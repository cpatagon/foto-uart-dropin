from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class ImageMetadata:
    """Metadatos de imagen capturada."""
    timestamp: datetime
    width: int
    height: int
    quality: int
    size_bytes: int
    processing_time_ms: float
    enhancements_applied: list
    camera_settings: dict
    location: Optional[tuple] = None
