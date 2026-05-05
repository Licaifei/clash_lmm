# System VPN Tunnel Spec

## Goal

Create the system VPN tunnel and route device traffic into the local Mihomo runtime.

This is the critical phone-traffic spec. It must prove real traffic routing, not only UI state.

## Functional Requirements

- Implement `VpnExtensionAbility` internals for the real VPN lifecycle.
- Create a `VpnConnection` from the extension context.
- Build a VPN config with:
  - virtual interface address
  - default IPv4 route
  - DNS server list
  - MTU
  - app include/exclude handling if supported
- Request system VPN authorization through `vpnExtension.startVpnExtensionAbility()`.
- Handle user denial as a normal failure state.
- Handle system rejection when another VPN is already active.
- Bridge vNIC traffic to the local Mihomo runtime using the selected design:
  - Mihomo TUN mode if supported by runtime and platform
  - tun2socks or equivalent packet bridge if Mihomo only exposes a SOCKS/mixed port
  - documented blocker if no safe bridge is available
- Treat `VpnConnection.create(config)` as tunnel creation only. It is not sufficient by itself; the spec is not complete until vNIC packets are read and forwarded into Mihomo or a verified Mihomo TUN path.
- Protect any outbound tunnel sockets with `VpnConnection.protect(fd)` when required to avoid routing loops.
- Destroy `VpnConnection` and bridge resources on stop.

## Development Constraints

- Do not mark VPN active until `VpnConnection.create(config)` succeeds and the bridge path is running.
- Do not route the app's own controller traffic into a loop.
- Do not route Mihomo outbound sockets back into the same VPN tunnel.
- Do not use system-only VPN APIs unless the app is signed and privileged for them.
- Do not assume IPv6 support in the first pass; default can be IPv4-only.
- Do not silently ignore packet bridge errors.
- Do not keep VPN active if local Mihomo Core stops.
- Keep all native bridge code behind a service boundary.
- If the bridge needs a file descriptor or native packet loop, expose only typed start/stop/status methods to ArkTS.
- Avoid hardcoding third-party package names in trusted or blocked app lists.

## Interface Test Expectations

- `VpnRuntime.start()` checks that Mihomo Core is running before requesting VPN.
- `VpnRuntime.start()` starts `VpnExtensionAbility` with the correct bundle and ability name.
- `VpnExtensionAbility.onCreate()` creates or prepares `VpnConnection`.
- `VpnConnection.create(config)` receives a config with a default route.
- Packet bridge starts after VPN creation and reports active status.
- `VpnRuntime.stop()` stops extension ability and destroys active connection.
- User denial and another-active-VPN errors are surfaced as readable messages.
- Packet bridge failure transitions state to failed and tears down the VPN.

## Module Interaction Expectations

- `MihomoCoreRuntime` must be running before `VpnRuntime` starts.
- `VpnRuntime` owns UI-facing VPN state:
  - stopped
  - requestingPermission
  - startingTunnel
  - active
  - stopping
  - failed
- `VpnExtensionAbility` owns system VPN lifecycle and low-level connection cleanup.
- `Index.ets` coordinates Core and VPN state, but does not parse packets.
- `HomePage.ets` exposes Start VPN and Stop VPN actions through callbacks.

## Tests

- Preview build must pass.
- Manual device test checklist:
  - first Start VPN shows system authorization prompt
  - denial returns to stopped or failed with readable message
  - approval creates VPN and shows system VPN icon
  - active VPN can load an IP-check website through the configured subscription
  - packet bridge counters or logs show packets moving through the bridge
  - DNS resolution works through VPN
  - Stop VPN removes system VPN icon
  - stopping Mihomo Core tears down VPN or blocks with a clear error
  - starting while another VPN is active shows clear error

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
