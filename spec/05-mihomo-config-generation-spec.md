# Mihomo Config Generation Spec

## Goal

Generate a local Mihomo config from the active subscription so the phone can run a local core with stable ports and controller settings.

## Functional Requirements

- Read the active subscription content from the subscription store.
- Generate a Mihomo-compatible runtime config file in the app sandbox.
- Preserve subscription proxy and proxy-group definitions when the source content is already Mihomo or Clash YAML.
- Preserve source rule, proxy-provider, rule-provider, DNS, and proxy-group sections unless the app must override a local runtime field.
- Ensure required local runtime fields exist:
  - `mixed-port`
  - `allow-lan: false`
  - `mode`
  - `external-controller`
  - `secret` if configured
  - DNS settings suitable for local VPN mode
  - TUN settings only if the selected runtime design requires Mihomo TUN directly
- Add app-owned defaults for missing required fields.
- Validate generated config before core startup where practical.
- Detect and report missing required source sections such as no `proxies` and no `proxy-providers`.
- Store generated config path and generation timestamp.
- Show config generation errors separately from subscription fetch errors.

## Development Constraints

- Do not implement Core startup in this spec.
- Do not implement VPN tunnel creation in this spec.
- Do not silently overwrite user subscription content; write generated runtime config to a separate file.
- Avoid ad hoc line editing if a YAML parser is available and compile-safe.
- If no YAML parser is available, keep transformation minimal and explicit:
  - append or override a small known set of top-level fields
  - document unsupported source shapes
- Prefer a deterministic merge order:
  - app-owned runtime fields override source fields
  - source proxy/rule sections are preserved
  - generated comments are optional and must not contain secrets
- Do not include subscription tokens in generated logs or error text.
- Keep generated controller port stable so existing `MihomoApiService` can connect to local core.

## Interface Test Expectations

- `MihomoConfigService.generate(activeSubscriptionId)` returns:
  - generated config path
  - local controller URL
  - local controller secret
  - selected mixed port
  - timestamp
- Missing active subscription returns a readable error.
- Invalid or unsupported subscription content returns a readable error.
- Generated config always contains local `external-controller`.
- Generated config always contains a reachable local mixed or SOCKS port for the VPN bridge.
- Generated config does not mutate the raw subscription file.
- Re-generating the same subscription replaces only the generated runtime config.

## Module Interaction Expectations

- `SubscriptionStore` provides active subscription content or file path.
- `MihomoConfigService` owns config generation and validation.
- `MihomoCoreRuntime` from the next spec consumes generated config path only.
- `Index.ets` updates controller config to the generated local controller after generation succeeds.
- Existing external-controller mode remains available for development, but local VPN mode becomes the default path for phone usage.

## Tests

- Preview build must pass.
- Add helper tests for config defaults if generation logic is extracted.
- Manual test checklist:
  - no active subscription shows clear error
  - valid Clash/Mihomo YAML generates runtime config
  - generated config contains expected local controller URL
  - generated config contains expected mixed port
  - generated config path persists for Core startup
  - raw subscription file remains unchanged

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
