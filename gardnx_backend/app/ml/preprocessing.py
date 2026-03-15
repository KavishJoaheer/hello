"""Image preprocessing for DeepLabV3+ inference."""
from typing import Tuple

INPUT_SIZE = (513, 513)
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]

def preprocess_image(image, target_size: Tuple[int, int] = INPUT_SIZE):
    """
    Preprocess a PIL Image for DeepLabV3+ inference.
    Returns a normalized float tensor of shape (3, H, W).
    """
    try:
        import torch
        from torchvision import transforms

        transform = transforms.Compose([
            transforms.Resize(target_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
        ])
        return transform(image.convert('RGB'))
    except ImportError:
        return None
