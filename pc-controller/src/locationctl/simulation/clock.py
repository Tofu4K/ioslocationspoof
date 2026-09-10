"""Clock abstractions for real-time and deterministic test simulation."""

from abc import ABC, abstractmethod
import time


class ClockProtocol(ABC):
    """Abstract clock for frame-rate and wall-clock independent time advancement."""

    @abstractmethod
    def now(self) -> float:
        """Return current monotonic time in seconds."""
        pass


class SystemMonotonicClock(ClockProtocol):
    """System monotonic clock for live simulation."""

    def now(self) -> float:
        return time.monotonic()


class FakeClock(ClockProtocol):
    """Deterministic simulated clock for testing and time seeking."""

    def __init__(self, initial_time: float = 0.0):
        self._current_time = initial_time

    def now(self) -> float:
        return self._current_time

    def advance(self, seconds: float):
        if seconds < 0:
            raise ValueError("Time cannot advance backward in fake clock.")
        self._current_time += seconds

    def set_time(self, seconds: float):
        self._current_time = seconds
