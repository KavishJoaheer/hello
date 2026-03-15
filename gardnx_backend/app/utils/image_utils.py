"""Image processing utilities."""
import io
import base64
from typing import Tuple


def compress_image(image_bytes: bytes, max_size: int = 1920, quality: int = 85) -> bytes:
    """Compress and resize image, keeping aspect ratio."""
    from PIL import Image
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    w, h = img.size
    if max(w, h) > max_size:
        ratio = max_size / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=quality, optimize=True)
    return buf.getvalue()


def get_image_dimensions(image_bytes: bytes) -> Tuple[int, int]:
    """Return (width, height) of image."""
    from PIL import Image
    img = Image.open(io.BytesIO(image_bytes))
    return img.size  # (width, height)


def image_to_base64(image_bytes: bytes) -> str:
    return base64.b64encode(image_bytes).decode("utf-8")


def base64_to_image(b64_string: str) -> bytes:
    return base64.b64decode(b64_string)
