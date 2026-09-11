# Verification and Testing Procedures

Comprehensive test procedures for unit testing, protocol validation, and physical device acceptance.

---

## 1. Automated Unit Tests

Run the Python controller test suite:
```bash
cd pc-controller
pytest tests -v
```

### Key Test Coverage:
1. **Coordinate Validation:** Ensures latitude `[-90, 90]` and longitude `[-180, 180]` are enforced and invalid inputs raise errors.
2. **Finite State Machine:** Tests legal state transitions (`DISCONNECTED -> CONNECTING -> CONNECTED -> READY -> SIMULATING -> STOPPING -> READY`) and invalid transition rejections.
3. **Protocol Serialization:** Verifies JSON payload formatting for REST/WebSocket endpoints.

---

## 2. Physical Device Acceptance Test (Acceptance Criteria)

This test confirms that a real physical iPhone 13 receives coordinates observable by system apps:

### Procedure:
1. Connect physical iPhone 13 via USB to host PC.
2. Unlock the device and ensure Developer Mode is enabled.
3. Launch the location control server / CLI:
   ```bash
   locationctl devices
   ```
   Confirm the iPhone 13 is listed with `Developer Mode: Enabled`.
4. Open the Map UI (`http://localhost:8765`).
5. Select a known landmark, e.g. **Eiffel Tower (48.8584, 2.2945)**.
6. Click **`[SPOOF]`**.
7. Wait for status banner to show **`SPOOFING ACTIVE`**.

### Validation across Apps on iPhone:
- **Apple Maps:** Open Apple Maps. Confirm the blue user location puck centers on the Eiffel Tower in Paris.
- **Google Maps:** Open Google Maps. Confirm blue dot is at the Eiffel Tower.
- **Snapchat (Snap Map):** Open Snap Map. Confirm your Bitmoji is located at the Eiffel Tower.
- **Test App:** Query `CLLocation.sourceInformation.isSimulatedBySoftware` and verify it equals `true`.

### Restoration Test:
1. In the Map UI, click **`[STOP SPOOFING]`**.
2. Status transitions to `STOPPING` -> `READY`.
3. Open Apple Maps on the iPhone. Confirm the location puck returns to your real physical location.
