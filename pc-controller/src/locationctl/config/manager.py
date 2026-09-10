"""Configuration manager for locationctl."""

from pathlib import Path
import json
from typing import Any, Dict
from pydantic import BaseModel, Field
from ..protocol.models import SimulationSettings, SpeedUnit, AccelerationProfile


class AppConfig(BaseModel):
    default_speed_kmh: float = 50.0
    speed_unit: SpeedUnit = SpeedUnit.KMH
    default_acceleration: AccelerationProfile = AccelerationProfile.NORMAL
    simulate_stops: bool = True
    server_port: int = 8765
    server_host: str = "0.0.0.0"
    companion_device_ip: str = "127.0.0.1"
    companion_device_port: int = 8765


class ConfigManager:
    """Manages persistent JSON configuration in user home directory."""

    def __init__(self, config_dir: Path = None):
        if config_dir is None:
            self.config_dir = Path.home() / ".locationctl"
        else:
            self.config_dir = config_dir
        self.config_file = self.config_dir / "config.json"
        self._ensure_config_dir()
        self.config = self.load()

    def _ensure_config_dir(self):
        self.config_dir.mkdir(parents=True, exist_ok=True)

    def load(self) -> AppConfig:
        if self.config_file.exists():
            try:
                with open(self.config_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return AppConfig(**data)
            except Exception:
                return AppConfig()
        return AppConfig()

    def save(self):
        self._ensure_config_dir()
        with open(self.config_file, "w", encoding="utf-8") as f:
            json.dump(self.config.model_dump(), f, indent=2)

    def get(self, key: str) -> Any:
        return getattr(self.config, key, None)

    def set(self, key: str, value: Any):
        if hasattr(self.config, key):
            # Type cast where needed
            current_val = getattr(self.config, key)
            if isinstance(current_val, float):
                value = float(value)
            elif isinstance(current_val, int):
                value = int(value)
            elif isinstance(current_val, bool):
                value = str(value).lower() in ("true", "1", "yes")

            setattr(self.config, key, value)
            self.save()
        else:
            raise KeyError(f"Unknown configuration key: {key}")

    def reset(self):
        self.config = AppConfig()
        self.save()
