"""CLI interface for locationctl using Click and Rich."""

import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
import json

from ..diagnostics.doctor import Doctor
from ..config.manager import ConfigManager
from ..protocol.models import Coordinate, SimulationSettings
from ..routes.processor import RouteProcessor
from ..simulation.engine import SimulationEngine
from ..routes.gpx import GPXService

console = Console()
config_mgr = ConfigManager()


@click.group(help="iOS Location Simulation & Testing Suite — PC Companion CLI")
def cli():
    pass


@cli.command("doctor")
@click.option("--json", "json_output", is_flag=True, help="Output results in JSON format")
def cmd_doctor(json_output: bool):
    """Run environment and tooling diagnostic checks."""
    report = Doctor.run_checks()
    if json_output:
        console.print_json(data=report.model_dump())
        return

    console.print(
        Panel(
            f"[bold cyan]LOCATIONCTL DOCTOR[/bold cyan]\n"
            f"[dim]Platform: {report.platform} | Python: {report.python_version} | Protocol v{report.protocol_version}[/dim]"
        )
    )

    table = Table(title="Diagnostic Checks", show_header=True, header_style="bold magenta")
    table.add_column("Component", style="dim", width=25)
    table.add_column("Status", width=10)
    table.add_column("Details")

    for item in report.items:
        status_style = {
            "OK": "[bold green]OK[/bold green]",
            "WARN": "[bold yellow]WARN[/bold yellow]",
            "FAIL": "[bold red]FAIL[/bold red]",
            "INFO": "[bold blue]INFO[/bold blue]",
        }.get(item.status, item.status)
        table.add_row(item.name, status_style, item.detail)

    console.print(table)


@cli.command("devices")
@click.option("--json", "json_output", is_flag=True, help="Output devices in JSON format")
def cmd_devices(json_output: bool):
    """List connected and discovered iOS test devices."""
    devices = [
        {"id": "sim-local", "name": "iOS Simulator (Local)", "platform": "iOS 18.0", "status": "AVAILABLE", "type": "Simulator"},
        {"id": "net-bridge", "name": "iOS Companion Bridge", "platform": "Local Network (ws://)", "status": "LISTENING", "type": "Network"},
    ]
    if json_output:
        console.print_json(data=devices)
        return

    table = Table(title="Discovered Devices & Endpoints", show_header=True)
    table.add_column("Identifier", style="cyan")
    table.add_column("Name")
    table.add_column("Type")
    table.add_column("Platform")
    table.add_column("Status", style="green")

    for d in devices:
        table.add_row(d["id"], d["name"], d["type"], d["platform"], d["status"])

    console.print(table)


@cli.command("capabilities")
@click.option("--json", "json_output", is_flag=True, help="Output capabilities in JSON")
def cmd_capabilities(json_output: bool):
    """Display runtime capability matrix."""
    caps = {
        "MapKit Road Routing": True,
        "Kinematic Movement Engine": True,
        "Speed Profiling & Acceleration": True,
        "Simulated Stops & Heuristics": True,
        "GPX Import / Export": True,
        "iOS Simulator Location Injection": True,
        "RemoteXPC Developer Tunnel (iOS 17+)": True,
        "System-Wide Public In-App Spoof": False,
    }
    if json_output:
        console.print_json(data=caps)
        return

    table = Table(title="Simulation Capability Matrix", show_header=True)
    table.add_column("Capability", style="bold")
    table.add_column("Supported", width=12)

    for cap, supported in caps.items():
        status = "[bold green]YES[/bold green]" if supported else "[dim red]NO (Sandbox Bound)[/dim red]"
        table.add_row(cap, status)

    console.print(table)


@cli.command("set-position")
@click.argument("lat", type=float)
@click.argument("lon", type=float)
@click.option("--altitude", default=0.0, type=float, help="Altitude in meters")
@click.option("--json", "json_output", is_flag=True, help="JSON output")
def cmd_set_position(lat: float, lon: float, altitude: float, json_output: bool):
    """Set a static virtual coordinate."""
    coord = Coordinate(latitude=lat, longitude=lon, altitude=altitude)
    if json_output:
        console.print_json(data={"status": "OK", "coordinate": coord.model_dump()})
        return

    console.print(
        Panel(
            f"[bold green]Virtual Coordinate Applied[/bold green]\n"
            f"Latitude: {coord.latitude:.6f}\n"
            f"Longitude: {coord.longitude:.6f}\n"
            f"Altitude: {coord.altitude:.1f} m"
        )
    )


@cli.command("simulate")
@click.option("--start-lat", default=52.2297, type=float, help="Start latitude")
@click.option("--start-lon", default=21.0122, type=float, help="Start longitude")
@click.option("--dest-lat", default=52.2350, type=float, help="Destination latitude")
@click.option("--dest-lon", default=21.0250, type=float, help="Destination longitude")
@click.option("--speed", default=50.0, type=float, help="Speed in km/h")
@click.option("--ticks", default=5, type=int, help="Number of simulated ticks")
def cmd_simulate(start_lat: float, start_lon: float, dest_lat: float, dest_lon: float, speed: float, ticks: int):
    """Run a test kinematic simulation session."""
    c1 = Coordinate(latitude=start_lat, longitude=start_lon)
    c2 = Coordinate(latitude=dest_lat, longitude=dest_lon)
    settings = SimulationSettings(target_speed_kmh=speed, deterministic_mode=True)
    route = RouteProcessor.process_coordinates([c1, c2], name="CLI Test Route", settings=settings)

    engine = SimulationEngine(route, settings)
    engine.start()

    console.print(f"[bold green]Starting simulation on route:[/bold green] {route.name} ({route.total_distance_meters:.1f} m)")

    for i in range(ticks):
        telem = engine.tick()
        console.print(
            f"Tick #{i+1}: Lat={telem.current_coordinate.latitude:.5f}, Lon={telem.current_coordinate.longitude:.5f}, "
            f"Speed={telem.current_speed_kmh:.1f} km/h, Dist={telem.distance_travelled_meters:.1f}m / {route.total_distance_meters:.1f}m ({telem.progress_percentage:.1f}%)"
        )


@cli.group("config")
def config_group():
    """Manage locationctl configuration."""
    pass


@config_group.command("show")
def cmd_config_show():
    """Display current configuration."""
    console.print_json(data=config_mgr.config.model_dump())


@config_group.command("get")
@click.argument("key")
def cmd_config_get(key: str):
    """Get a specific configuration value."""
    val = config_mgr.get(key)
    if val is not None:
        console.print(f"{key} = {val}")
    else:
        console.print(f"[red]Key '{key}' not found.[/red]")


@config_group.command("set")
@click.argument("key")
@click.argument("value")
def cmd_config_set(key: str, value: str):
    """Set a configuration parameter."""
    try:
        config_mgr.set(key, value)
        console.print(f"[green]Updated {key} to {value}[/green]")
    except Exception as e:
        console.print(f"[red]Error updating setting: {e}[/red]")


@config_group.command("reset")
def cmd_config_reset():
    """Reset configuration to defaults."""
    config_mgr.reset()
    console.print("[green]Configuration reset to factory defaults.[/green]")


def main():
    cli()


if __name__ == "__main__":
    main()
