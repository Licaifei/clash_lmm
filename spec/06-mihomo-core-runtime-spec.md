# Mihomo Core Runtime Spec

## Goal

Start and stop a local Mihomo Core process or embedded runtime from the HarmonyOS app.

This spec turns generated config files into a live local external-controller endpoint.

## Functional Requirements

- Decide and implement one runtime strategy after `03-vpn-platform-capability-spec.md`:
  - packaged native executable
  - NAPI wrapper around embedded core
  - documented unsupported path if the target device cannot run either
- Bundle or reference the Mihomo runtime artifact in a deterministic location.
- Record the supported CPU ABI and artifact name. MVP should target the actual phone ABI first, usually `arm64`.
- Verify the runtime artifact is executable or loadable before trying to start it.
- Start the core using the generated config path.
- Stop the core on user request and app shutdown where required.
- Detect running state:
  - stopped
  - starting
  - running
  - stopping
  - failed
- Wait until local external-controller responds before marking core running.
- Detect controller port conflicts and report them as startup failures.
- Connect existing `MihomoApiService` to the generated local controller URL after startup.
- Capture concise startup errors.
- Keep a small rolling runtime log for debugging.

## Development Constraints

- Do not start system VPN in this spec.
- Do not claim phone traffic is protected in this spec.
- Do not leave orphan core processes after Stop.
- Do not hardcode paths outside the app sandbox.
- Use an app-owned working directory for generated config, cache, and runtime data.
- Do not log subscription secrets or generated config secrets.
- Keep startup idempotent: repeated Start while starting/running must not spawn duplicate cores.
- Keep stop idempotent: repeated Stop while stopped/stopping must not crash.
- If process execution is impossible in this SDK/app privilege level, stop this spec and document the blocker instead of building a fake runtime.
- If NAPI is required, keep the ArkTS runtime service as a thin typed wrapper around native start/stop/status calls.

## Interface Test Expectations

- `MihomoCoreRuntime.start(configPath)` returns a typed startup result.
- `MihomoCoreRuntime.stop()` closes the runtime and returns a typed result.
- Startup fails if generated config is missing.
- Startup fails if runtime artifact is missing.
- Startup fails if runtime artifact ABI does not match the device.
- Startup fails if the configured local controller port is already occupied.
- Startup success requires local controller health check success.
- Duplicate Start does not create duplicate core instances.
- Stop clears local runtime state and closes related subscriptions.

## Module Interaction Expectations

- `MihomoConfigService` provides generated config path and controller settings.
- `MihomoCoreRuntime` owns process or embedded runtime lifecycle.
- `Index.ets` or a runtime coordinator owns combined app state and tells `MihomoApiService` which local controller to use.
- `HomePage.ets` receives runtime state and Start Core / Stop Core callbacks only through typed props.
- VPN tunnel code from the next spec depends on core running before VPN activation.

## Tests

- Preview build must pass.
- Manual device test checklist:
  - missing config blocks startup
  - valid generated config starts local core
  - local controller responds after startup
  - traffic WebSocket can connect to local controller
  - Stop terminates core
  - repeated Start/Stop does not create duplicate runtime instances
  - app relaunch does not assume an old orphan runtime is healthy without probing it

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
