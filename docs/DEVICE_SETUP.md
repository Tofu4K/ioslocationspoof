# Physical Device Setup Guide (iPhone 13 / iOS 16+)

Follow these one-time steps on your physical iPhone 13 before executing developer location simulation.

---

## 1. Enable Developer Mode

On iOS 16 and later, Apple requires Developer Mode to be explicitly toggled on by the device owner:

1. Open the **Settings** app on your iPhone.
2. Scroll down and tap **Privacy & Security**.
3. Scroll to the very bottom and tap **Developer Mode**.
4. Toggle the switch to **ON**.
5. Tap **Restart** when prompted.
6. After the device restarts:
   - Unlock your iPhone with your Passcode.
   - An alert titled *"Turn On Developer Mode?"* will appear.
   - Tap **Turn On**, then enter your Passcode again to confirm.

---

## 2. Pair and Trust the Computer

1. Connect your iPhone 13 to your computer using a genuine Lightning-to-USB cable.
2. Unlock the iPhone screen.
3. When the prompt *"Trust This Computer?"* appears on the iPhone:
   - Tap **Trust**.
   - Enter your device Passcode.
4. On Windows: Open iTunes or ensure Apple Mobile Device Service recognizes the device.
5. The pairing record is securely stored on your computer (in `%ProgramData%\Apple\Lockdown` on Windows).

---

## 3. Keep Device Screen Unlocked During First Run

During the initial handshake, iOS will confirm that the session is initiated from a trusted host. Ensure the screen is unlocked so any developer authorization prompts can be acknowledged immediately.
