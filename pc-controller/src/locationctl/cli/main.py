"""CLI interface for locationctl using Click and Rich."""

import warnings
warnings.filterwarnings("ignore", message=".*doesn't match a supported version!.*")
warnings.filterwarnings("ignore", category=UserWarning)

import sys
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
from ..backend.developer_service import DeveloperServiceBackend
from ..backend.state import BackendState

console = Console()
config_mgr = ConfigManager()
backend = DeveloperServiceBackend()


@click.group(help="iOS Location Simulation & Testing Suite — PC Companion CLI")
def cli():
    pass


# Export app alias for console_scripts entrypoint
app = cli


@cli.command("doctor")
@click.option("--json", "json_output", is_flag=True, help="Output results in JSON format")
def cmd_doctor(json_output: bool):
    """Run environment, usbmuxd, and hardware diagnostic checks."""
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
    table.add_column("Component", style="dim", width=28)
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
    """List connected and discovered physical iOS devices."""
    dev_objects = backend.list_devices_sync()
    devices = [d.model_dump() for d in dev_objects]

    if json_output:
        console.print_json(data=devices)
        return

    if not devices:
        console.print(
            Panel(
                "[bold yellow]No Connected iOS Devices Detected[/bold yellow]\n\n"
                "1. Connect your iPhone 13 via a USB data cable.\n"
                "2. Unlock the device screen.\n"
                "3. Ensure 'Apple Mobile Device Service' is running (or launch iTunes on Windows).\n"
                "4. Ensure Developer Mode is enabled under Settings > Privacy & Security > Developer Mode.",
                title="Device Discovery",
            )
        )
        return

    table = Table(title="Connected Physical iOS Devices", show_header=True)
    table.add_column("UDID", style="cyan", width=25)
    table.add_column("Device Name")
    table.add_column("Model")
    table.add_column("iOS Version")
    table.add_column("Paired", width=10)
    table.add_column("Developer Mode", width=16)

    for d in devices:
        paired_str = "[green]YES[/green]" if d["is_paired"] else "[red]NO[/red]"
        devmode_str = "[green]ENABLED[/green]" if d["developer_mode"] else "[yellow]UNKNOWN[/yellow]"
        table.add_row(
            d["udid"][:20] + "...",
            d["name"],
            d["product_type"],
            d["ios_version"],
            paired_str,
            devmode_str,
        )

    console.print(table)


@cli.command("capabilities")
@click.option("--json", "json_output", is_flag=True, help="Output capabilities in JSON")
def cmd_capabilities(json_output: bool):
    """Display runtime capability and hardware readiness matrix."""
    caps = backend.get_capabilities_sync()
    if json_output:
        console.print_json(data=caps.model_dump())
        return

    table = Table(title="Hardware & Simulation Capability Matrix", show_header=True)
    table.add_column("Capability", style="bold")
    table.add_column("Status", width=18)

    table.add_row("Device Connected", "[green]YES[/green]" if caps.device_connected else "[dim red]NO[/dim red]")
    table.add_row("Device Paired (Trust)", "[green]YES[/green]" if caps.device_paired else "[dim red]NO[/dim red]")
    table.add_row("Developer Mode", "[green]ENABLED[/green]" if caps.developer_mode_enabled else "[yellow]UNVERIFIED[/yellow]")
    table.add_row("Developer Service Backend", "[green]AVAILABLE[/green]" if caps.simulation_backend_available else "[dim red]UNAVAILABLE[/dim red]")
    table.add_row("com.apple.dt.simulatelocation", "[green]READY[/green]" if caps.developer_service_available else "[dim red]NOT READY[/dim red]")

    console.print(table)
    if caps.details:
        console.print(f"[dim]Details: {caps.details}[/dim]\n")


@cli.command("spoof")
@click.option("--lat", required=True, type=float, help="Latitude (-90.0 to 90.0)")
@click.option("--lon", required=True, type=float, help="Longitude (-180.0 to 180.0)")
@click.option("--udid", default=None, type=str, help="Target device UDID")
def cmd_spoof(lat: float, lon: float, udid: str):
    """Simulate a fixed coordinate on the connected iPhone 13."""
    console.print(f"[dim]Initiating location simulation to ({lat:.4f}, {lon:.4f})...[/dim]")
    res = backend.set_location_sync(lat, lon)
    if res.success:
        console.print(
            Panel(
                f"[bold green]SPOOFING ACTIVE[/bold green]\n\n"
                f"Latitude: {lat:.6f}\n"
                f"Longitude: {lon:.6f}\n"
                f"Status: {res.message}\n\n"
                f"[bold yellow]Location simulation is active and locked on iPhone.[/bold yellow]\n"
                f"Press [bold cyan]Enter[/bold cyan] or [bold cyan]Ctrl+C[/bold cyan] to stop simulation and restore genuine GPS.",
                border_style="green",
            )
        )
        try:
            input()
        except (KeyboardInterrupt, EOFError):
            pass
        finally:
            console.print("\n[dim]Stopping location simulation...[/dim]")
            clear_res = backend.clear_location_sync()
            if clear_res.success:
                console.print("[bold green]Device successfully restored to genuine GPS.[/bold green]\n")
            else:
                console.print(f"[yellow]Simulation stopped: {clear_res.message}[/yellow]\n")
    else:
        console.print(
            Panel(
                f"[bold red]SPOOFING FAILED[/bold red]\n\n"
                f"Reason: {res.message}\n"
                f"Error Code: {res.error}",
                border_style="red",
            )
        )



@cli.command("clear")
def cmd_clear():
    """Stop location simulation and restore device to natural GPS."""
    console.print("[dim]Stopping location simulation...[/dim]")
    res = backend.clear_location_sync()
    if res.success:
        console.print(
            Panel(
                "[bold green]SIMULATION STOPPED[/bold green]\n\n"
                "Device locationd has restored natural GNSS hardware updates.",
                border_style="green",
            )
        )
    else:
        console.print(
            Panel(
                f"[bold red]FAILED TO CLEAR SIMULATION[/bold red]\n\n{res.message}",
                border_style="red",
            )
        )


@cli.command("status")
def cmd_status():
    """Query current backend simulation state and active coordinates."""
    status = backend.get_status_sync()
    console.print(
        Panel(
            f"[bold cyan]SIMULATION STATUS[/bold cyan]\n\n"
            f"State: [bold]{status.state.value}[/bold]\n"
            f"Active Coordinate: {status.active_coordinate or 'None'}\n"
            f"Device: {status.device.name if status.device else 'None'}\n"
            f"Last Error: {status.last_error or 'None'}",
            border_style="cyan",
        )
    )



@cli.command("serve")
@click.option("--host", default="0.0.0.0", help="Bind host (default: 0.0.0.0)")
@click.option("--port", default=8765, help="Port (default: 8765)")
def cmd_serve(host: str, port: int):
    """Start the interactive World Map UI and companion REST/WebSocket server."""
    from ..transport.server import run_server
    run_server(host=host, port=port, backend=backend)


@cli.command("server", hidden=True)
@click.option("--host", default="0.0.0.0", help="Bind host (default: 0.0.0.0)")
@click.option("--port", default=8765, help="Port (default: 8765)")
def cmd_server(host: str, port: int):
    """Alias for serve."""
    cmd_serve(host=host, port=port)



if __name__ == "__main__":
    cli()
