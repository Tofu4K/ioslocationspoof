# Windows Host Setup Guide

This guide details configuring a Windows 10/11 PC to communicate with a physical iPhone 13 for developer location simulation.

---

## 1. Apple Mobile Device Drivers

Windows requires Apple's official USB multiplexer service (`usbmuxd` / `AppleMobileDeviceService.exe`) to detect and route traffic to iOS devices:

1. **Verify Existing Installation:**
   - On this machine, Apple Mobile Device Support is installed under:
     `C:\Program Files\Common Files\Apple\Mobile Device Support\`
   - iTunes is installed in:
     `C:\Program Files\iTunes\`
2. **Ensure Service is Running:**
   - In an elevated PowerShell / Services window:
     ```powershell
     Start-Service "Apple Mobile Device Service"
     Start-Service "Bonjour Service"
     ```
   - Alternatively, simply opening iTunes once will automatically spin up the background services.

---

## 2. Python Environment & Dependencies

1. **Python 3.10+ Requirement:**
   - The project runs on Python 3.11+.
2. **Install Package Dependencies:**
   ```powershell
   cd pc-controller
   pip install -e .
   pip install pymobiledevice3
   ```

---

## 3. iOS 17+ RemoteXPC Tunneling on Windows

For devices running iOS 17 or later:
1. Apple requires an encrypted IPv6 tunnel for Remote Service Discovery (RSD).
2. `pymobiledevice3` manages this tunnel using a virtual TUN/TAP interface.
3. If running an iOS 17+ device, start the tunnel daemon in a separate terminal:
   ```powershell
   pymobiledevice3 remote tunneld
   ```
4. Verify the tunnel is established:
   ```powershell
   locationctl doctor
   ```
