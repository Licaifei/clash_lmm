# VPN Platform Capability Spec

## Goal

Verify the HarmonyOS VPN and native-runtime foundation before implementing subscription import or core startup.

This is a gate spec. If this fails on the target device, later VPN specs must stop and document the blocker instead of building UI that cannot work.

## Functional Requirements

- Add a minimal `VpnExtensionAbility` declaration to `entry/src/main/module.json5`.
- Add a minimal extension entry file that imports `VpnExtensionAbility` and logs lifecycle callbacks.
- Add start and stop integration points from the main app using `vpnExtension.startVpnExtensionAbility()` and `vpnExtension.stopVpnExtensionAbility()`.
- Confirm whether the current target SDK and device support:
  - `type: "vpn"` extension ability
  - `vpnExtension.createVpnConnection(context)`
  - `VpnConnection.create(config)`
  - `VpnConnection.destroy()`
  - `VpnConnection.protect(fd)` if the eventual bridge needs socket protection
- Confirm how the app can package or execute Mihomo Core:
  - native executable
  - shared library through NAPI
  - unsupported without platform-specific signing or system capability
- Produce a short capability result in code comments or a small markdown note if any platform path is blocked.

## Development Constraints

- Do not implement subscription import in this spec.
- Do not implement Mihomo config generation in this spec.
- Do not ship a fake "VPN connected" state.
- Do not request broad permissions without proving they are required.
- Keep the extension minimal and reversible.
- Do not store secrets or subscription URLs in logs.
- Use the app bundle name and the exact VPN ability name consistently in all `Want` objects.
- If the API is unavailable in the configured SDK, fail the spec with a clear compile-time note instead of adding untyped dynamic calls.

## Interface Test Expectations

- `module.json5` contains a VPN extension ability with `type: "vpn"`.
- The VPN extension class can compile under the current SDK.
- Main UI code can call start and stop functions without ArkTS compile errors.
- Start failure is converted to a concise user-visible error.
- Stop failure is converted to a concise user-visible error.
- If another VPN is active, system rejection is surfaced as "another VPN is active" or equivalent readable text.

## Module Interaction Expectations

- `Index.ets` or a future runtime owner triggers start and stop.
- `VpnExtensionAbility` owns VPN lifecycle callbacks and `VpnConnection` cleanup.
- No page component should directly create `VpnConnection`.
- Runtime capability results should be exposed to the UI through typed state, not raw exception objects.
- Later specs may replace the minimal extension internals, but should keep the ability name stable.

## Tests

- Preview build must pass.
- Manual test checklist:
  - app launches after adding VPN extension declaration
  - tapping Start VPN Extension triggers system authorization dialog if required
  - user denial is shown as a readable failure
  - user approval starts the extension
  - tapping Stop VPN Extension stops the extension
  - extension `onDestroy()` releases any created `VpnConnection`

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
