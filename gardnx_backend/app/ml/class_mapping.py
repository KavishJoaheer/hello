"""Segmentation class definitions for garden analysis."""

SEGMENTATION_CLASSES = {
    0: "background",
    1: "soil",
    2: "lawn",
    3: "path",
    4: "shade",
    5: "existing_plant",
}

CLASS_COLORS = {
    0: (0, 0, 0, 0),
    1: (139, 90, 43, 180),
    2: (34, 139, 34, 180),
    3: (128, 128, 128, 180),
    4: (70, 70, 150, 180),
    5: (0, 200, 0, 180),
}

CLASS_NAMES_DISPLAY = {
    0: "Background",
    1: "Soil",
    2: "Lawn/Grass",
    3: "Path/Paved",
    4: "Shaded Area",
    5: "Existing Plants",
}

PLANTABLE_CLASSES = {1, 4}  # soil and shade zones can be planted in
