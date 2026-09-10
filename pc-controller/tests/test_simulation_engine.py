"""Unit tests for simulation engine, kinematics, and state machine."""

import pytest
from locationctl.protocol.models import (
    Coordinate,
    SimulationSettings,
    SimulationState,
    AccelerationProfile,
)
from locationctl.routes.processor import RouteProcessor
from locationctl.simulation.engine import SimulationEngine
from locationctl.simulation.clock import FakeClock


@pytest.fixture
def test_route():
    c1 = Coordinate(latitude=52.2297, longitude=21.0122)
    c2 = Coordinate(latitude=52.2350, longitude=21.0180)
    c3 = Coordinate(latitude=52.2400, longitude=21.0250)
    return RouteProcessor.process_coordinates([c1, c2, c3], name="Test Route")


def test_simulation_lifecycle(test_route):
    clock = FakeClock(100.0)
    settings = SimulationSettings(target_speed_kmh=60.0)
    engine = SimulationEngine(test_route, settings, clock=clock)

    assert engine.state == SimulationState.READY

    engine.start()
    assert engine.state == SimulationState.RUNNING

    # Tick with time advancing
    clock.advance(5.0)
    telem = engine.tick()
    assert telem.distance_travelled_meters > 0.0
    assert telem.state == SimulationState.RUNNING

    engine.pause()
    assert engine.state == SimulationState.PAUSED

    engine.resume()
    assert engine.state == SimulationState.RUNNING

    engine.stop()
    assert engine.state == SimulationState.COMPLETED


def test_simulation_seeking(test_route):
    clock = FakeClock(0.0)
    settings = SimulationSettings(target_speed_kmh=50.0)
    engine = SimulationEngine(test_route, settings, clock=clock)
    engine.start()

    engine.seek_to_percentage(50.0)
    telem = engine.tick()
    assert telem.progress_percentage == pytest.approx(50.0, abs=1.0)
    assert telem.distance_travelled_meters == pytest.approx(test_route.total_distance_meters * 0.5, rel=1e-2)
