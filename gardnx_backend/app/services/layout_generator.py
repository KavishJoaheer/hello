"""Grid-based garden layout generator with companion planting awareness."""

import logging
import math
from typing import Dict, List, Optional

from app.models.layout_models import (
    LayoutRequest,
    LayoutResponse,
    LayoutStatistics,
    PlantPlacement,
    SelectedPlant,
    BedInfo,
)
from app.models.plant_models import Plant
from app.services.spacing_calculator import calculate_grid_dimensions
from app.services.companion_checker import CompanionChecker
from app.services.plant_recommender import PlantRecommender

logger = logging.getLogger("gardnx")


class LayoutGenerator:
    """Generates optimal garden bed layouts using a greedy grid-placement algorithm.

    Algorithm:
    1. Convert bed dimensions to a grid using the minimum plant spacing as cell size.
    2. Sort plants by priority (ascending = most important first), then by
       space needed (largest first, so big plants get placed before small ones).
    3. Greedily iterate grid positions. For each candidate cell, check:
       - Not already occupied
       - No incompatible neighbour (within adjacency radius)
    4. Place the plant and mark occupied cells.
    5. Collect statistics and companion-planting warnings.
    """

    def __init__(self):
        self._recommender: Optional[PlantRecommender] = None
        self._companion: Optional[CompanionChecker] = None

    @property
    def recommender(self) -> PlantRecommender:
        if self._recommender is None:
            self._recommender = PlantRecommender()
        return self._recommender

    @property
    def companion(self) -> CompanionChecker:
        if self._companion is None:
            self._companion = CompanionChecker()
        return self._companion

    def generate(self, request: LayoutRequest) -> LayoutResponse:
        """Generate a layout for the given bed and plant selections."""
        bed = request.bed
        selected = request.plants
        use_companions = request.use_companion_rules

        # Resolve plant data
        plant_lookup = self._resolve_plants(selected)

        # Determine cell size (smallest spacing among all selected plants)
        cell_size = self._pick_cell_size(plant_lookup)
        grid_info = calculate_grid_dimensions(bed.width_cm, bed.height_cm, cell_size)
        rows = grid_info["rows"]
        cols = grid_info["cols"]

        # Initialise grid (None = empty)
        grid: List[List[Optional[str]]] = [[None] * cols for _ in range(rows)]

        # Sort selected plants: priority ascending, then space descending
        ordered = self._sort_plants(selected, plant_lookup, cell_size)
        # Clamp spans so plants that are larger than the grid still get placed
        ordered = [(sel, min(span_r, rows), min(span_c, cols)) for sel, span_r, span_c in ordered]

        placements: List[PlantPlacement] = []
        warnings: List[str] = []
        total_requested = sum(s.quantity for s in selected)

        for sel, span_r, span_c in ordered:
            plant = plant_lookup.get(sel.plant_id)
            placed_count = 0

            for _ in range(sel.quantity):
                pos = self._find_position(
                    grid, rows, cols, span_r, span_c,
                    sel.plant_id, plant_lookup, use_companions,
                )
                if pos is None:
                    warnings.append(
                        f"Could not place all '{sel.plant_id}' "
                        f"({placed_count}/{sel.quantity} placed) -- bed is full"
                    )
                    break

                r, c = pos
                # Mark grid
                for dr in range(span_r):
                    for dc in range(span_c):
                        grid[r + dr][c + dc] = sel.plant_id

                placements.append(
                    PlantPlacement(
                        plant_id=sel.plant_id,
                        plant_name=plant.name if plant else sel.plant_id,
                        row=r,
                        col=c,
                        span_rows=span_r,
                        span_cols=span_c,
                        count=1,
                    )
                )
                placed_count += 1

        # Companion warnings
        if use_companions:
            comp_warnings = self._check_companion_warnings(grid, rows, cols, plant_lookup)
            warnings.extend(comp_warnings)

        # Statistics
        occupied = sum(1 for r in grid for c in r if c is not None)
        total_cells = rows * cols
        utilisation = (occupied / total_cells * 100) if total_cells > 0 else 0

        stats = LayoutStatistics(
            total_cells=total_cells,
            occupied_cells=occupied,
            utilization_percent=round(utilisation, 1),
            plants_placed=len(placements),
            plants_requested=total_requested,
            grid_rows=rows,
            grid_cols=cols,
            cell_size_cm=cell_size,
        )

        return LayoutResponse(
            placements=placements,
            grid=grid,
            statistics=stats,
            warnings=warnings,
            bed=bed,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _resolve_plants(self, selected: List[SelectedPlant]) -> Dict[str, Plant]:
        """Look up full Plant objects from the catalog."""
        lookup: Dict[str, Plant] = {}
        for sel in selected:
            plant = self.recommender.plants.get(sel.plant_id)
            if plant:
                lookup[sel.plant_id] = plant
            else:
                logger.warning("Plant '%s' not found in catalog", sel.plant_id)
        return lookup

    def _pick_cell_size(self, plant_lookup: Dict[str, Plant]) -> float:
        """Choose the grid cell size based on the smallest plant spacing."""
        spacings = []
        for plant in plant_lookup.values():
            spacings.append(plant.spacing.between_plants_cm)
            spacings.append(plant.spacing.between_rows_cm)
        if not spacings:
            return 30.0  # Default 30 cm cells
        return max(15.0, min(spacings))  # At least 15 cm

    def _sort_plants(
        self,
        selected: List[SelectedPlant],
        plant_lookup: Dict[str, Plant],
        cell_size: float,
    ) -> List[tuple]:
        """Sort plants by priority then size; return (SelectedPlant, span_rows, span_cols)."""
        result = []
        for sel in selected:
            plant = plant_lookup.get(sel.plant_id)
            if plant:
                span_r = max(1, math.ceil(plant.spacing.between_rows_cm / cell_size))
                span_c = max(1, math.ceil(plant.spacing.between_plants_cm / cell_size))
            else:
                span_r, span_c = 1, 1
            result.append((sel, span_r, span_c))

        # Sort: priority ascending, then area descending (big plants first)
        result.sort(key=lambda x: (x[0].priority, -(x[1] * x[2])))
        return result

    def _find_position(
        self,
        grid: List[List[Optional[str]]],
        rows: int,
        cols: int,
        span_r: int,
        span_c: int,
        plant_id: str,
        plant_lookup: Dict[str, Plant],
        use_companions: bool,
    ) -> Optional[tuple]:
        """Find the first valid grid position for a plant."""
        for r in range(rows - span_r + 1):
            for c in range(cols - span_c + 1):
                if self._can_place(
                    grid, r, c, span_r, span_c, plant_id, rows, cols,
                    plant_lookup, use_companions,
                ):
                    return (r, c)
        return None

    def _can_place(
        self,
        grid: List[List[Optional[str]]],
        r: int,
        c: int,
        span_r: int,
        span_c: int,
        plant_id: str,
        rows: int,
        cols: int,
        plant_lookup: Dict[str, Plant],
        use_companions: bool,
    ) -> bool:
        """Check if we can place a plant at (r, c) with given span."""
        # Check that all cells in the span are empty
        for dr in range(span_r):
            for dc in range(span_c):
                if grid[r + dr][c + dc] is not None:
                    return False

        if not use_companions:
            return True

        # Check neighbours for incompatibility
        plant = plant_lookup.get(plant_id)
        if not plant:
            return True

        incompatible = set(plant.incompatible_plants)
        if not incompatible:
            return True

        # Scan all adjacent cells (including diagonals) around the footprint
        for dr in range(-1, span_r + 1):
            for dc in range(-1, span_c + 1):
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    neighbour = grid[nr][nc]
                    if neighbour and neighbour in incompatible:
                        return False

        return True

    def _check_companion_warnings(
        self,
        grid: List[List[Optional[str]]],
        rows: int,
        cols: int,
        plant_lookup: Dict[str, Plant],
    ) -> List[str]:
        """Check all placed plants for companion conflicts and return warnings."""
        warnings: List[str] = []
        checked_pairs = set()

        for r in range(rows):
            for c in range(cols):
                pid = grid[r][c]
                if pid is None:
                    continue

                # Check 8 neighbours
                for dr in [-1, 0, 1]:
                    for dc in [-1, 0, 1]:
                        if dr == 0 and dc == 0:
                            continue
                        nr, nc = r + dr, c + dc
                        if 0 <= nr < rows and 0 <= nc < cols:
                            nid = grid[nr][nc]
                            if nid and nid != pid:
                                pair = tuple(sorted([pid, nid]))
                                if pair not in checked_pairs:
                                    checked_pairs.add(pair)
                                    rel = self.companion.check_pair(pid, nid)
                                    if rel == "incompatible":
                                        p1 = plant_lookup.get(pid)
                                        p2 = plant_lookup.get(nid)
                                        n1 = p1.name if p1 else pid
                                        n2 = p2.name if p2 else nid
                                        warnings.append(
                                            f"Companion conflict: {n1} and {n2} "
                                            f"are incompatible neighbours"
                                        )

        return warnings
