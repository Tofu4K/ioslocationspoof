# Apple Code Signing & Provisioning Constraints

**Verification Date:** September 2026  
**Primary Source:** [Apple Developer Account Basics](https://developer.apple.com/help/account/basics/about-your-developer-account)  
**Primary Source:** [Apple Developer — Developer Mode Overview](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

---

## 1. Developer Account Types & Constraints

### Personal Team (Free Apple ID)
* **Cost:** $0 / year.
* **Capabilities:** Deploy apps to personal iOS devices via Xcode.
* **Limitations:**
  * Provisioning profiles expire after **7 days**.
  * Maximum of 3 active installed development apps per device.
  * No access to special entitlements (Apple Pay, Network Extensions, CloudKit production, etc.).
  * Requires re-signing and re-deploying every week.

### Paid Apple Developer Program ($99/yr)
* **Capabilities:** Distribution via TestFlight, App Store, Ad-Hoc.
* **Profile Lifetime:** 1 year.
* **Device Limit:** 100 devices per category.

---

## 2. Developer Mode on iOS 16, 17 & 18

Starting in iOS 16, Apple introduced an explicit device-level opt-in requirement for installing and running development binaries:

1. Device must be plugged into a Mac with Xcode, or have a development profile installed.
2. User must navigate to `Settings > Privacy & Security > Developer Mode`.
3. Toggle `Developer Mode` to `ON`.
4. The device reboots.
5. On reboot, a system prompt asks to "Turn On Developer Mode" and requires entering the device passcode.

---

## 3. Windows vs macOS Build Boundaries

* **Codebase Development:** Can be completely engineered, linted, and tested (logic/math/protocol) on Windows.
* **Compilation & Signing (`xcodebuild`):** Requires macOS with Xcode and Apple Clang/Swift toolchain.
* **PC Controller (`locationctl`):** Runs standalone on Windows 10/11, macOS, and Linux using Python 3.12+.
