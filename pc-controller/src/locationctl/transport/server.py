"""Unified HTTP REST and WebSocket companion server for iOS Location Simulation."""

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Optional, Set

from aiohttp import web
import websockets

from ..backend.base import SimulationBackend
from ..backend.developer_service import DeveloperServiceBackend

logger = logging.getLogger("locationctl.transport.server")


def create_app(backend: Optional[SimulationBackend] = None) -> web.Application:
    """Create the aiohttp web application serving UI and REST API."""
    if backend is None:
        backend = DeveloperServiceBackend()

    app = web.Application()
    ui_dir = Path(__file__).parent.parent / "ui"
    index_file = ui_dir / "index.html"

    async def handle_index(request: web.Request) -> web.Response:
        if index_file.exists():
            return web.FileResponse(index_file)
        return web.Response(text="LocationControl UI not found.", status=404)

    async def handle_get_status(request: web.Request) -> web.Response:
        status = await backend.get_status()
        return web.json_response(status.model_dump())

    async def handle_get_devices(request: web.Request) -> web.Response:
        devices = await backend.list_devices()
        return web.json_response([d.model_dump() for d in devices])

    async def handle_post_spoof(request: web.Request) -> web.Response:
        try:
            data = await request.json()
            lat = float(data.get("lat"))
            lon = float(data.get("lon"))
        except Exception as e:
            return web.json_response({"success": False, "message": f"Invalid coordinate payload: {e}"}, status=400)

        result = await backend.set_location(latitude=lat, longitude=lon)
        return web.json_response(result.model_dump())

    async def handle_post_clear(request: web.Request) -> web.Response:
        result = await backend.clear_location()
        return web.json_response(result.model_dump())


    async def on_cleanup(app_instance):
        try:
            await backend.clear_location()
        except Exception:
            pass

    app.on_cleanup.append(on_cleanup)

    # Routes
    app.router.add_get("/", handle_index)
    app.router.add_get("/api/status", handle_get_status)
    app.router.add_get("/api/devices", handle_get_devices)
    app.router.add_post("/api/spoof", handle_post_spoof)
    app.router.add_post("/api/clear", handle_post_clear)

    return app



def run_server(host: str = "0.0.0.0", port: int = 8765, backend: Optional[SimulationBackend] = None):
    """Run the web and REST server synchronously."""
    print(f"\n[+] iOS Location Simulation Server running on http://localhost:{port}")
    print(f"[+] If accessing from iPhone Safari on local Wi-Fi: http://<PC_LOCAL_IP>:{port}\n")
    app = create_app(backend=backend)
    web.run_app(app, host=host, port=port)
