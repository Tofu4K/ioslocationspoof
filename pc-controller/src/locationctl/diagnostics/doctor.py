"""Diagnostic checks for host OS, Python runtime, tooling, networking, and devices."""

import sys
import platform
import shutil
import socket
from typing import Dict, List, Any
from pydantic import BaseModel
from ..protocol.models import PROTOCOL_VERSION


class DiagnosticItem(BaseModel):
    name: str
    status: str  # OK, WARN, FAIL, INFO
    detail: str
    recommendation: str = ""


class DiagnosticReport(BaseModel):
    platform: str
    python_version: str
    protocol_version: int
    items: List[DiagnosticItem]


class Doctor:
    """Performs system diagnostic scans for locationctl."""

    @staticmethod
    def run_checks() -> DiagnosticReport:
        items: List[DiagnosticItem] = []

        # 1. OS & Runtime Check
        os_name = f"{platform.system()} {platform.release()}"
        py_ver = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        if sys.version_info >= (3, 10):
            items.append(
                DiagnosticItem(
                    name="Python Runtime",
                    status="OK",
                    detail=f"Python {py_ver} (meets >=3.10 requirement)",
                )
            )
        else:
            items.append(
                DiagnosticItem(
                    name="Python Runtime",
                    status="WARN",
                    detail=f"Python {py_ver} (Python 3.10+ recommended)",
                    recommendation="Upgrade to Python 3.10 or later.",
                )
            )

        # 2. Network / Port Availability
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1.0)
            result = sock.connect_ex(("127.0.0.1", 8765))
            sock.close()
            if result == 0:
                items.append(
                    DiagnosticItem(
                        name="Bridge Port (8765)",
                        status="INFO",
                        detail="Port 8765 is actively listening (daemon running)",
                    )
                )
            else:
                items.append(
                    DiagnosticItem(
                        name="Bridge Port (8765)",
                        status="OK",
                        detail="Port 8765 is available for local companion server",
                    )
                )
        except Exception as e:
            items.append(
                DiagnosticItem(
                    name="Network Socket",
                    status="WARN",
                    detail=f"Socket check error: {e}",
                )
            )

        # 3. Xcode / simctl Tooling (if on macOS)
        if platform.system() == "Darwin":
            xcrun_path = shutil.which("xcrun")
            if xcrun_path:
                items.append(
                    DiagnosticItem(
                        name="Xcode CLI (xcrun)",
                        status="OK",
                        detail=f"Found at {xcrun_path}",
                    )
                )
            else:
                items.append(
                    DiagnosticItem(
                        name="Xcode CLI (xcrun)",
                        status="WARN",
                        detail="xcrun not found in PATH",
                        recommendation="Install Xcode Command Line Tools via 'xcode-select --install'.",
                    )
                )
        else:
            items.append(
                DiagnosticItem(
                    name="Apple Tooling Boundary",
                    status="INFO",
                    detail=f"Running on {platform.system()}; companion server & protocol bridge active. Native xcodebuild requires macOS.",
                )
            )

        # 4. Developer Mode & Pairing capability
        items.append(
            DiagnosticItem(
                name="Developer Mode Support",
                status="OK",
                detail="Developer Mode required on iOS 16+ targets for hardware debug override.",
                recommendation="Enable under iOS Settings > Privacy & Security > Developer Mode.",
            )
        )

        return DiagnosticReport(
            platform=os_name,
            python_version=py_ver,
            protocol_version=PROTOCOL_VERSION,
            items=items,
        )
