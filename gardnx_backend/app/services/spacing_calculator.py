"""Spacing and grid dimension calculations for garden beds."""

import math


def calculate_max_plants(
    bed_width_cm: float,
    bed_height_cm: float,
    spacing_between_cm: float,
    spacing_rows_cm: float,
) -> dict:
    """Calculate the maximum number of plants that fit in a rectangular bed.

    Parameters
    ----------
    bed_width_cm : float
        Bed width in centimeters.
    bed_height_cm : float
        Bed height (length) in centimeters.
    spacing_between_cm : float
        Spacing between plants within a row, in centimeters.
    spacing_rows_cm : float
        Spacing between rows, in centimeters.

    Returns
    -------
    dict
        max_count, rows, cols, cell_width_cm, cell_height_cm
    """
    cols = max(1, math.floor(bed_width_cm / spacing_between_cm))
    rows = max(1, math.floor(bed_height_cm / spacing_rows_cm))

    return {
        "max_count": rows * cols,
        "rows": rows,
        "cols": cols,
        "cell_width_cm": spacing_between_cm,
        "cell_height_cm": spacing_rows_cm,
    }


def calculate_grid_dimensions(
    bed_width_cm: float,
    bed_height_cm: float,
    cell_size_cm: float,
) -> dict:
    """Calculate uniform grid dimensions for a bed.

    Parameters
    ----------
    bed_width_cm : float
        Bed width in centimeters.
    bed_height_cm : float
        Bed height (length) in centimeters.
    cell_size_cm : float
        Size of each square grid cell in centimeters.

    Returns
    -------
    dict
        rows, cols, cell_size_cm, total_cells
    """
    cols = max(1, math.floor(bed_width_cm / cell_size_cm))
    rows = max(1, math.floor(bed_height_cm / cell_size_cm))

    return {
        "rows": rows,
        "cols": cols,
        "cell_size_cm": cell_size_cm,
        "total_cells": rows * cols,
    }
