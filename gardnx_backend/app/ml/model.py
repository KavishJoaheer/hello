"""DeepLabV3+ model definition for garden segmentation."""

def load_deeplabv3_mobilenetv2(num_classes: int = 6, weights_path: str = None):
    """
    Load DeepLabV3+ with MobileNetV3-Large backbone.

    Args:
        num_classes: Number of segmentation classes (6 for garden).
        weights_path: Path to pretrained weights file (.pth). If None, uses random init.

    Returns:
        PyTorch model in eval mode.
    """
    try:
        import torch
        from torchvision.models.segmentation import deeplabv3_mobilenet_v3_large

        model = deeplabv3_mobilenet_v3_large(num_classes=num_classes)

        if weights_path:
            state_dict = torch.load(weights_path, map_location='cpu')
            model.load_state_dict(state_dict)
            print(f"Loaded model weights from {weights_path}")

        model.eval()
        return model
    except ImportError:
        print("PyTorch not available. Mock mode will be used.")
        return None
