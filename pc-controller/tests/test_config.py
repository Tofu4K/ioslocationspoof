"""Unit tests for configuration manager."""

import tempfile
from pathlib import Path
from locationctl.config.manager import ConfigManager, AppConfig


def test_config_lifecycle():
    with tempfile.TemporaryDirectory() as tmpdir:
        cfg_dir = Path(tmpdir)
        mgr = ConfigManager(config_dir=cfg_dir)

        assert mgr.config.default_speed_kmh == 50.0

        mgr.set("default_speed_kmh", 80.0)
        assert mgr.get("default_speed_kmh") == 80.0

        # Reload from disk
        mgr2 = ConfigManager(config_dir=cfg_dir)
        assert mgr2.get("default_speed_kmh") == 80.0

        mgr2.reset()
        assert mgr2.get("default_speed_kmh") == 50.0
