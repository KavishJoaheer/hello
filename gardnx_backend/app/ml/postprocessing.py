"""Convert model output masks to zone polygons."""
from typing import List, Optional
import numpy as np
from app.ml.class_mapping import SEGMENTATION_CLASSES

def mask_to_zones(mask: np.ndarray, original_size: tuple) -> List[dict]:
    """
    Convert segmentation mask to zone dictionaries.

    Args:
        mask: numpy array shape (H, W) with class IDs 0-5
        original_size: (width, height) of original image

    Returns:
        List of zone dicts with type, confidence, polygon, area_sq_meters
    """
    try:
        import cv2
    except ImportError:
        return _simple_mask_to_zones(mask, original_size)

    zones = []
    h, w = mask.shape
    total_pixels = h * w
    zone_id = 1

    for class_id, class_name in SEGMENTATION_CLASSES.items():
        if class_name == "background":
            continue

        class_mask = (mask == class_id).astype(np.uint8) * 255
        contours, _ = cv2.findContours(class_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        for contour in contours:
            area_pixels = cv2.contourArea(contour)
            if area_pixels < total_pixels * 0.02:  # Filter < 2% of image
                continue

            # Normalize contour points to 0-1
            polygon = []
            epsilon = 0.02 * cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, epsilon, True)
            for point in approx:
                polygon.append({
                    "x": float(point[0][0]) / w,
                    "y": float(point[0][1]) / h
                })

            if len(polygon) < 3:
                continue

            # Estimate area in sq meters (assume 1px ~ 1cm for rough estimate)
            area_sq_meters = round((area_pixels / total_pixels) * 20.0, 2)  # Assume ~20m2 garden

            zones.append({
                "zone_id": f"z{zone_id}",
                "type": class_name,
                "confidence": 0.75 + np.random.uniform(-0.1, 0.15),  # Simulated confidence
                "polygon": polygon,
                "area_sq_meters": area_sq_meters
            })
            zone_id += 1

    return zones


def _simple_mask_to_zones(mask: np.ndarray, original_size: tuple) -> List[dict]:
    """Fallback zone detection without OpenCV."""
    h, w = mask.shape
    zones = []
    zone_id = 1

    for class_id, class_name in SEGMENTATION_CLASSES.items():
        if class_name == "background":
            continue
        positions = np.argwhere(mask == class_id)
        if len(positions) < 0.02 * h * w:
            continue

        min_r, min_c = positions.min(axis=0)
        max_r, max_c = positions.max(axis=0)

        polygon = [
            {"x": float(min_c) / w, "y": float(min_r) / h},
            {"x": float(max_c) / w, "y": float(min_r) / h},
            {"x": float(max_c) / w, "y": float(max_r) / h},
            {"x": float(min_c) / w, "y": float(max_r) / h},
        ]

        zones.append({
            "zone_id": f"z{zone_id}",
            "type": class_name,
            "confidence": 0.7,
            "polygon": polygon,
            "area_sq_meters": round(len(positions) / (h * w) * 20.0, 2)
        })
        zone_id += 1

    return zones
