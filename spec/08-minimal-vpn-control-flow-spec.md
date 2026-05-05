# Minimal VPN Control Flow Spec

## Goal

Replace the first-screen experience with a minimal real VPN flow once subscription, config generation, core runtime, and VPN tunnel pieces exist.

The user should be able to run the VPN from the phone without understanding the external-controller architecture.

## Functional Requirements

- Home page primary action becomes Start VPN when stopped.
- Start VPN orchestrates:
  - validate active subscription
  - generate runtime config if missing or stale
  - start Mihomo Core
  - verify local controller
  - start system VPN tunnel
  - verify packet bridge active state
  - connect dashboard API to local controller
- Stop VPN orchestrates:
  - stop VPN tunnel
  - stop Mihomo Core
  - close WebSocket subscriptions
  - reset live traffic values
- Show a single user-facing state:
  - no subscription
  - ready
  - preparing
  - core starting
  - requesting VPN permission
  - VPN active
  - stopping
  - failed
- Provide a compact error panel with the failed phase and readable message.
- Keep advanced external-controller connection available for development, but not as the primary phone path.

## Development Constraints

- Do not duplicate orchestration across pages.
- Do not let Home directly write subscription files, generated configs, or native runtime state.
- Do not start VPN without a selected subscription.
- Do not leave Core running if VPN startup fails after Core startup.
- If bridge startup fails after system VPN authorization, tear down the VPN extension and stop Core before reporting failure.
- Do not show "connected" unless both local Core and system VPN are active.
- Keep operation token or equivalent cancellation semantics from spec02 for long-running Start/Stop.
- Avoid adding dashboard detail cards that belong to later specs.

## Interface Test Expectations

- `VpnStartupCoordinator.start()` or equivalent returns the final state and failed phase.
- Missing subscription blocks before config generation.
- Config generation failure does not start Core.
- Core startup failure does not start VPN.
- VPN startup failure stops Core or marks it explicitly as stopped.
- Packet bridge startup failure stops VPN and Core.
- Stop VPN is idempotent.
- User can retry after failure without restarting the app.

## Module Interaction Expectations

- `Index.ets` owns top-level orchestration state or delegates to a coordinator service.
- `SubscriptionStore` provides active subscription.
- `MihomoConfigService` generates config.
- `MihomoCoreRuntime` starts local core.
- `VpnRuntime` starts system VPN.
- `MihomoApiService` connects only after local controller is verified.
- `HomePage.ets` is presentational and receives state, error, and callbacks.

## Tests

- Preview build must pass.
- Manual phone test checklist:
  - no subscription shows import action or clear blocked state
  - valid subscription can start VPN from Home
  - Start VPN reaches active state
  - phone traffic is routed through subscription
  - Stop VPN fully stops tunnel and core
  - failure during each phase reports the failed phase
  - retry after failure works
  - compact portrait layout has no clipped button text or overlapping controls

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
