"""Real Apple Developer Location Simulation Backend.

Communicates with physical iPhone hardware via usbmuxd, Lockdown, and
Apple's developer simulation service (com.apple.dt.simulatelocation / DVT RemoteXPC).
"""

import asyncio
import logging
import socket
from typing import List, Optional, Tuple

from .base import SimulationBackend
from .state import (
    BackendState,
    DeviceInfo,
    CapabilityReport,
    SimulationResult,
    SimulationStatus,
)

logger = logging.getLogger("locationctl.backend.developer")
# Silence verbose socket teardown traces from userspace tunnel
logging.getLogger("pymobiledevice3.remote.userspace_tunnel").setLevel(logging.CRITICAL)
logging.getLogger("asyncio").setLevel(logging.CRITICAL)



class DeveloperServiceBackend(SimulationBackend):
    """
    Physical device location simulation backend using Apple Developer Services.
    Implements true hardware discovery and com.apple.dt.simulatelocation interaction.
    """

    def __init__(self):
        self._state: BackendState = BackendState.DISCONNECTED
        self._active_coordinate: Optional[Tuple[float, float]] = None
        self._connected_device: Optional[DeviceInfo] = None
        self._last_error: Optional[str] = None
        self._lockdown_client = None
        self._rsd = None
        self._dvt = None
        self._loc_sim = None
        self._sim_service = None
        self._keepalive_task: Optional[asyncio.Task] = None
        self._lock: Optional[asyncio.Lock] = None

    @property
    def lock(self) -> asyncio.Lock:
        if self._lock is None:
            self._lock = asyncio.Lock()
        return self._lock

    @staticmethod
    def _check_usbmuxd_port() -> bool:
        """Check whether usbmuxd (port 27015) is actively listening on localhost."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(0.5)
            result = sock.connect_ex(("127.0.0.1", 27015))
            sock.close()
            return result == 0
        except Exception:
            return False

    async def list_devices(self) -> List[DeviceInfo]:
        """
        Enumerate physical iOS devices connected via USB or local network
        using usbmuxd and Lockdown.
        """
        devices: List[DeviceInfo] = []
        if not self._check_usbmuxd_port():
            logger.debug("usbmuxd is not currently listening on port 27015.")
            self._last_error = (
                "Apple Mobile Device Service / usbmuxd is stopped. "
                "Please start 'Apple Mobile Device Service' or open iTunes on Windows."
            )
            return devices

        try:
            from pymobiledevice3.usbmux import list_devices as usbmux_list
            from pymobiledevice3.lockdown import create_using_usbmux

            raw_devices = await usbmux_list()

            for dev in raw_devices:
                udid = getattr(dev, "serial", None) or getattr(dev, "udid", "Unknown")
                dev_info = DeviceInfo(
                    udid=udid,
                    connection_type="USB" if getattr(dev, "is_usb", True) else "Network",
                )
                try:
                    lockdown = await create_using_usbmux(serial=udid)
                    dev_info.name = lockdown.short_info.get("DeviceName", "iPhone")
                    dev_info.product_type = lockdown.short_info.get("ProductType", "iPhone")
                    dev_info.ios_version = lockdown.short_info.get("ProductVersion", "Unknown")
                    dev_info.is_paired = True
                    try:
                        dev_info.developer_mode = await lockdown.get_developer_mode_status()
                    except Exception:
                        dev_info.developer_mode = True
                except Exception as e:
                    dev_info.name = f"iPhone ({udid[:8]}...)"
                    dev_info.is_paired = False
                    logger.debug(f"Lockdown pairing check for {udid}: {e}")

                devices.append(dev_info)

            self._last_error = None

        except Exception as e:
            logger.debug(f"Device enumeration exception: {e}")
            self._last_error = f"Device enumeration error: {e}"

        return devices

    async def connect(self, udid: Optional[str] = None) -> bool:
        """
        Connect to a physical device, verify pairing, check Developer Mode,
        and prepare the location simulation service.
        """
        self._state = BackendState.CONNECTING
        self._last_error = None

        try:
            from pymobiledevice3.lockdown import create_using_usbmux

            devices = await self.list_devices()
            if not devices:
                self._state = BackendState.DISCONNECTED
                if not self._check_usbmuxd_port():
                    self._last_error = (
                        "Apple Mobile Device Service is not running. "
                        "Start the service via Windows Services or launch iTunes."
                    )
                else:
                    self._last_error = "No iOS device detected. Connect via USB or ensure Wi-Fi sync is enabled in iTunes."
                return False

            target = None
            if udid:
                target = next((d for d in devices if d.udid == udid), None)
            if not target:
                target = devices[0]

            self._connected_device = target

            if not target.is_paired:
                self._state = BackendState.ERROR
                self._last_error = "Device is not paired. Unlock your iPhone screen and tap 'Trust'."
                return False

            self._lockdown_client = await create_using_usbmux(serial=target.udid)
            self._state = BackendState.READY
            logger.info(f"Connected to {target.name} ({target.udid})")
            return True

        except Exception as e:
            self._state = BackendState.ERROR
            self._last_error = f"Connection failed: {e}"
            logger.error(f"Failed to connect to device: {e}")
            return False

    async def disconnect(self) -> None:
        """Clean up active session and reset state."""
        async with self.lock:
            await self._cleanup_simulation_session()
            if self._lockdown_client and hasattr(self._lockdown_client, "close"):
                try:
                    await self._lockdown_client.close()
                except Exception:
                    pass
            self._lockdown_client = None
            self._connected_device = None
            self._state = BackendState.DISCONNECTED


    async def get_status(self) -> SimulationStatus:
        """Query current state machine status and capabilities."""
        devices = await self.list_devices()
        caps = await self.get_capabilities(cached_devices=devices)
        
        if devices:
            self._connected_device = devices[0]
            if self._state == BackendState.DISCONNECTED:
                self._state = BackendState.READY
        else:
            self._connected_device = None
            if self._state not in (BackendState.CONNECTING, BackendState.ERROR):
                self._state = BackendState.DISCONNECTED

        return SimulationStatus(
            state=self._state,
            active_coordinate=self._active_coordinate,
            device=self._connected_device,
            capabilities=caps,
            last_error=self._last_error,
        )

    async def get_capabilities(self, cached_devices: Optional[List[DeviceInfo]] = None) -> CapabilityReport:
        """Inspect device capabilities and developer service availability."""
        caps = CapabilityReport()
        usbmux_active = self._check_usbmuxd_port()
        devices = cached_devices if cached_devices is not None else await self.list_devices()
        if devices:
            caps.device_connected = True
            primary = devices[0]
            caps.device_paired = primary.is_paired
            caps.developer_mode_enabled = primary.developer_mode
            caps.developer_service_available = primary.is_paired
            caps.simulation_backend_available = True
            caps.details = f"{primary.name} ({primary.product_type}) running iOS {primary.ios_version}"
        else:
            if not usbmux_active:
                caps.details = "Apple Mobile Device Service / usbmuxd is not active on host."
            else:
                caps.details = "usbmuxd is active. Awaiting physical iPhone connection."
        return caps

    async def _cleanup_simulation_session(self) -> None:
        """Gracefully terminate active simulation channels, keepalive tasks, and DVT sockets."""
        if self._keepalive_task:
            self._keepalive_task.cancel()
            try:
                await self._keepalive_task
            except (asyncio.CancelledError, Exception):
                pass
            self._keepalive_task = None

        if self._loc_sim:
            try:
                await self._loc_sim.clear()
            except Exception as e:
                logger.debug(f"loc_sim clear during cleanup: {e}")
            try:
                await self._loc_sim.close()
            except Exception as e:
                logger.debug(f"loc_sim close during cleanup: {e}")
            self._loc_sim = None

        if self._dvt:
            try:
                await self._dvt.close()
            except Exception as e:
                logger.debug(f"dvt close during cleanup: {e}")
            self._dvt = None

        if self._sim_service:
            try:
                await self._sim_service.clear()
            except Exception as e:
                logger.debug(f"sim_service clear during cleanup: {e}")
            self._sim_service = None

        self._rsd = None

    def _start_keepalive(self) -> None:
        """Start or refresh the keepalive loop to maintain developer location override."""
        if self._keepalive_task and not self._keepalive_task.done():
            self._keepalive_task.cancel()
        self._keepalive_task = asyncio.create_task(self._keepalive_worker())

    async def _keepalive_worker(self) -> None:
        """Periodically ping the location simulation to prevent timeouts and keep GPS overridden."""
        try:
            while self._state == BackendState.SIMULATING and self._active_coordinate:
                await asyncio.sleep(5)
                if self._state != BackendState.SIMULATING or not self._active_coordinate:
                    break
                lat, lon = self._active_coordinate
                try:
                    if self._loc_sim:
                        await self._loc_sim.set(lat, lon)
                        logger.debug(f"Keepalive ping: {lat}, {lon}")
                    elif self._sim_service:
                        await self._sim_service.set(latitude=lat, longitude=lon)
                except asyncio.CancelledError:
                    break
                except Exception as e:
                    logger.warning(f"Keepalive ping error: {e}")
                    break
        except asyncio.CancelledError:
            pass

    async def set_location(self, latitude: float, longitude: float) -> SimulationResult:
        """
        Send simulated coordinate to Apple's developer location service.
        Performs strict coordinate validation, sends to hardware, and verifies state.
        Maintains an active persistent session to prevent iOS from reverting to real GPS.
        """
        # 1. Coordinate Validation
        if not (-90.0 <= latitude <= 90.0):
            return SimulationResult(
                success=False,
                message=f"Invalid latitude {latitude}. Must be between -90.0 and 90.0.",
                error="LATITUDE_OUT_OF_BOUNDS",
                state=self._state,
            )
        if not (-180.0 <= longitude <= 180.0):
            return SimulationResult(
                success=False,
                message=f"Invalid longitude {longitude}. Must be between -180.0 and 180.0.",
                error="LONGITUDE_OUT_OF_BOUNDS",
                state=self._state,
            )

        async with self.lock:
            # 2. Fast-path: If an active simulation channel is already open, reuse it!
            if self._state == BackendState.SIMULATING and self._loc_sim:
                try:
                    await self._loc_sim.set(latitude, longitude)
                    self._active_coordinate = (latitude, longitude)
                    logger.info(f"Updated active simulation to ({latitude}, {longitude})")
                    return SimulationResult(
                        success=True,
                        message=f"Location simulation active at {latitude:.4f}, {longitude:.4f}",
                        latitude=latitude,
                        longitude=longitude,
                        state=self._state,
                    )
                except Exception as e:
                    logger.warning(f"Failed to update existing DVT session ({e}), reconnecting...")
                    await self._cleanup_simulation_session()

            elif self._state == BackendState.SIMULATING and self._sim_service:
                try:
                    await self._sim_service.set(latitude=latitude, longitude=longitude)
                    self._active_coordinate = (latitude, longitude)
                    return SimulationResult(
                        success=True,
                        message=f"Location simulation active at {latitude:.4f}, {longitude:.4f}",
                        latitude=latitude,
                        longitude=longitude,
                        state=self._state,
                    )
                except Exception as e:
                    logger.warning(f"Failed to update existing legacy session ({e}), reconnecting...")
                    await self._cleanup_simulation_session()

            # 3. Verify connection
            if not self._connected_device or not self._lockdown_client:
                connected = await self.connect()
                if not connected:
                    return SimulationResult(
                        success=False,
                        message=self._last_error or "Device not connected.",
                        error="NO_DEVICE_CONNECTED",
                        state=self._state,
                    )

            # 4. Determine OS version
            ios_version = self._connected_device.ios_version if self._connected_device else "17.0"
            try:
                major_ver = int(ios_version.split(".")[0]) if "." in ios_version else 17
            except Exception:
                major_ver = 17

            # iOS 17+ uses DVT LocationSimulation over RSD / Userspace tunnel
            if major_ver >= 17:
                try:
                    from pymobiledevice3.remote import userspace_tunnel
                    from pymobiledevice3.services.dvt.instruments.dvt_provider import DvtProvider
                    from pymobiledevice3.services.dvt.instruments.location_simulation import LocationSimulation

                    # Clean up any stale session
                    await self._cleanup_simulation_session()

                    self._rsd = await userspace_tunnel.establish_userspace_rsd(serial=self._connected_device.udid)
                    self._dvt = DvtProvider(self._rsd)
                    await self._dvt.connect()
                    self._loc_sim = LocationSimulation(self._dvt)
                    await self._loc_sim.connect()
                    await self._loc_sim.set(latitude, longitude)

                    self._active_coordinate = (latitude, longitude)
                    self._state = BackendState.SIMULATING
                    self._last_error = None
                    self._start_keepalive()

                    logger.info(f"Location simulation active at ({latitude}, {longitude}) with persistent DVT session.")
                    return SimulationResult(
                        success=True,
                        message=f"Location simulation active at {latitude:.4f}, {longitude:.4f}",
                        latitude=latitude,
                        longitude=longitude,
                        state=self._state,
                    )
                except Exception as e:
                    logger.warning(f"DVT LocationSimulation failed, attempting fallback: {e}")
                    await self._cleanup_simulation_session()

            # Fallback to standard DtSimulateLocation (iOS <= 16 or mounted DDI)
            try:
                from pymobiledevice3.services.simulate_location import DtSimulateLocation

                await self._cleanup_simulation_session()
                self._sim_service = DtSimulateLocation(self._lockdown_client)
                await self._sim_service.set(latitude=latitude, longitude=longitude)

                self._active_coordinate = (latitude, longitude)
                self._state = BackendState.SIMULATING
                self._last_error = None
                self._start_keepalive()

                return SimulationResult(
                    success=True,
                    message=f"Location simulation active at {latitude:.4f}, {longitude:.4f}",
                    latitude=latitude,
                    longitude=longitude,
                    state=self._state,
                )
            except Exception as e:
                err_msg = f"Failed to activate location simulation: {e}"
                logger.error(err_msg)
                await self._cleanup_simulation_session()
                self._state = BackendState.ERROR
                self._last_error = err_msg
                return SimulationResult(
                    success=False,
                    message=err_msg,
                    error="SIMULATION_SERVICE_FAILED",
                    state=self._state,
                )

    async def clear_location(self) -> SimulationResult:
        """
        Send clear/stop command to com.apple.dt.simulatelocation to restore hardware GPS.
        """
        async with self.lock:
            self._state = BackendState.STOPPING
            await self._cleanup_simulation_session()
            self._active_coordinate = None
            self._state = BackendState.READY
            self._last_error = None
            return SimulationResult(
                success=True,
                message="Simulation cleared. Device restored to natural GPS.",
                state=self._state,
            )


    @staticmethod
    def _run_coro(coro):
        """Helper to run an async coroutine synchronously in any context."""
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = None

        if loop and loop.is_running():
            import nest_asyncio
            nest_asyncio.apply()
            return loop.run_until_complete(coro)
        else:
            return asyncio.run(coro)

    def list_devices_sync(self) -> List[DeviceInfo]:
        return self._run_coro(self.list_devices())

    def connect_sync(self, udid: Optional[str] = None) -> bool:
        return self._run_coro(self.connect(udid))

    def get_status_sync(self) -> SimulationStatus:
        return self._run_coro(self.get_status())

    def get_capabilities_sync(self) -> CapabilityReport:
        return self._run_coro(self.get_capabilities())

    def set_location_sync(self, latitude: float, longitude: float) -> SimulationResult:
        return self._run_coro(self.set_location(latitude, longitude))

    def clear_location_sync(self) -> SimulationResult:
        return self._run_coro(self.clear_location())

