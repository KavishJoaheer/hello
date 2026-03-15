"""Companion planting rule checker for garden layouts."""

import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from app.models.layout_models import LayoutWarning, PlantPlacement

logger = logging.getLogger("gardnx")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"


class CompanionChecker:
    """Loads companion-planting rules from JSON and checks plant pairs or full layouts.

    The rules file contains entries with plant1_id, plant2_id, type (companion
    or incompatible), and a reason. Lookups are stored in both directions for
    fast O(1) pair checks.
    """

    def __init__(self, rules_path: str | None = None):
        path = Path(rules_path) if rules_path else DATA_DIR / "companion_rules.json"
        self.rules: List[dict] = []
        # Keyed by (sorted pair) -> {"type": ..., "reason": ...}
        self._pair_map: Dict[Tuple[str, str], dict] = {}
        self._load_rules(path)

    def _load_rules(self, path: Path) -> None:
        """Load companion rules from a JSON file."""
        try:
            with open(path, "r", encoding="utf-8") as f:
                self.rules = json.load(f)
            for rule in self.rules:
                pair = tuple(sorted([rule["plant1_id"], rule["plant2_id"]]))
                self._pair_map[pair] = {
                    "type": rule.get("type", "neutral"),
                    "reason": rule.get("reason", ""),
                }
            logger.info("CompanionChecker: loaded %d rules from %s", len(self.rules), path)
        except FileNotFoundError:
            logger.warning("CompanionChecker: rules file not found at %s", path)
        except Exception as e:
            logger.error("CompanionChecker: error loading rules: %s", e)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def check_pair(self, plant1_id: str, plant2_id: str) -> str:
        """Check the relationship between two plants.

        Returns
        -------
        str
            "companion", "incompatible", or "neutral"
        """
        pair = tuple(sorted([plant1_id, plant2_id]))
        info = self._pair_map.get(pair)
        if info is None:
            return "neutral"
        return info["type"]

    def get_reason(self, plant1_id: str, plant2_id: str) -> str:
        """Return the reason string for a pair relationship."""
        pair = tuple(sorted([plant1_id, plant2_id]))
        info = self._pair_map.get(pair)
        if info is None:
            return ""
        return info.get("reason", "")

    def check_layout(
        self,
        placements: List[PlantPlacement],
        bed_width_cm: float = 0,
        bed_height_cm: float = 0,
    ) -> List[LayoutWarning]:
        """Check all placed plants for companion-planting issues.

        Iterates all pairs of placements that are adjacent on the grid
        (including diagonals) and returns warnings for incompatible
        neighbours and info-level notes for beneficial companions.

        Parameters
        ----------
        placements : list[PlantPlacement]
            The placements to check.
        bed_width_cm, bed_height_cm : float
            Bed dimensions (used for context in warnings; not strictly needed).

        Returns
        -------
        list[LayoutWarning]
        """
        warnings: List[LayoutWarning] = []
        checked_pairs: set = set()

        # Build a quick spatial index: cell -> plant_id
        cell_map: Dict[Tuple[int, int], str] = {}
        for p in placements:
            for dr in range(p.span_rows):
                for dc in range(p.span_cols):
                    cell_map[(p.row + dr, p.col + dc)] = p.plant_id

        # For each occupied cell, check 8 neighbours
        for (r, c), pid in cell_map.items():
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue
                    nr, nc = r + dr, c + dc
                    nid = cell_map.get((nr, nc))
                    if nid is None or nid == pid:
                        continue

                    pair = tuple(sorted([pid, nid]))
                    if pair in checked_pairs:
                        continue
                    checked_pairs.add(pair)

                    rel = self.check_pair(pid, nid)
                    reason = self.get_reason(pid, nid)

                    if rel == "incompatible":
                        warnings.append(
                            LayoutWarning(
                                type="companion_conflict",
                                message=f"{pid} and {nid} are incompatible. {reason}",
                                plant1_id=pid,
                                plant2_id=nid,
                                severity="error",
                            )
                        )
                    elif rel == "companion":
                        warnings.append(
                            LayoutWarning(
                                type="companion_benefit",
                                message=f"{pid} and {nid} are good companions. {reason}",
                                plant1_id=pid,
                                plant2_id=nid,
                                severity="info",
                            )
                        )

        return warnings
