# macOS Virtual Machine Setup Guide (Secondary / Fallback Workflow)

If Windows driver friction or TUN adapter limitations prevent establishing an IPv6 RemoteXPC tunnel for modern iOS, a macOS Virtual Machine running on Windows provides an official, zero-compromise developer pipeline.

---

## 1. Hypervisor & Virtual Machine Specs

- **Hypervisor:** VMware Workstation Pro (17.x+) or VirtualBox (7.x+).
- **Guest OS:** macOS Sonoma (14.x) or macOS Sequoia (15.x).
- **Hardware Allocation:**
  - **RAM:** Minimum 8 GB (12 GB recommended).
  - **CPU:** 4 to 6 Cores.
  - **Storage:** 80 GB SSD space.

---

## 2. USB Passthrough Configuration

1. In the VMware/VirtualBox VM settings, ensure USB Controller is set to **USB 3.1 (xHCI)**.
2. Plug the iPhone 13 into the Windows PC via Lightning/USB.
3. In the hypervisor menu:
   - Go to `VM > Removable Devices > Apple iPhone > Connect (Disconnect from host)`.
4. The iPhone will detach from Windows and attach directly to the macOS VM.
5. In macOS, verify the iPhone appears in Finder or System Information.

---

## 3. macOS Tooling & Location Simulation

Inside the macOS VM:
1. Open Terminal and install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```
2. Verify device visibility via Apple's native CoreDevice CLI:
   ```bash
   xcrun devicectl list devices
   ```
3. Because macOS natively handles RSD tunnels and pairing via `com.apple.CoreDevice.CoreDeviceService`, location simulation commands work natively without third-party network drivers:
   ```bash
   pip install pymobiledevice3
   python -m locationctl.cli devices
   python -m locationctl.cli spoof --lat 48.8584 --lon 2.2945
   ```
