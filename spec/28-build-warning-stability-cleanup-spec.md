# Build Warning And Stability Cleanup Spec

## Goal

Clean up non-blocking ArkTS build warnings after the first connection features are stable.

This spec is intentionally separated from `02-connection-refresh-flow-spec.md`. The current warnings do not block PreviewBuild, but they should be removed before the project relies on settings persistence, controller API error handling, and layout runtime APIs more broadly.

## Functional Requirements

- Remove or explicitly handle ArkTS "Function may throw exceptions" warnings from settings persistence.
- Remove or explicitly handle ArkTS "Function may throw exceptions" warnings from controller API response parsing.
- Replace deprecated context and media query API usage where practical.
- Preserve the current user-visible behavior:
  - app still loads saved controller URL and secret on startup
  - saving settings still persists controller URL and secret
  - connect and refresh still surface readable errors through `lastError`
  - compact layout still updates from screen width changes
- Do not change connection-state semantics from spec02.
- Do not introduce retry loops, background reconnect, or profile migration in this spec.

## Warning Inventory

- `entry/src/main/ets/services/AppConfigStore.ets`
  - ArkTS warning: function may throw exceptions.
  - Expected source: preferences access, value reads, writes, or flush operations.
- `entry/src/main/ets/services/MihomoApiService.ets`
  - ArkTS warning: function may throw exceptions.
  - Expected source: JSON parsing of HTTP response text.
- `entry/src/main/ets/pages/Index.ets`
  - ArkTS warning: `getContext` has been deprecated.
  - ArkTS warning: `matchMediaSync` has been deprecated.

## Development Constraints

- Keep `AppConfigStore` as the only module that directly owns settings persistence.
- Keep `MihomoApiService` as the only module that parses Mihomo HTTP responses.
- Do not move UI state persistence into page components.
- Do not swallow persistence or JSON parsing failures silently:
  - return defaults only when that is already the intended fallback
  - otherwise surface a concise error to the caller
- Keep error messages suitable for UI display; avoid dumping large raw response bodies.
- If a deprecated API does not have a safe replacement in the current SDK version, document the reason in a short code comment near the call site and keep the warning cleanup scoped to the warnings that can be fixed safely.
- Do not change spec02 operation token behavior in `connect()`, `refresh()`, `disconnect()`, or `saveSettings()` except where required to propagate errors correctly.

## Interface Test Expectations

- `AppConfigStore.load()` returns default settings when no saved settings exist.
- `AppConfigStore.load()` handles malformed or partially missing saved values without crashing startup.
- `AppConfigStore.save()` either completes successfully or exposes a failure path that the caller can report.
- `MihomoApiService` converts invalid JSON responses into a readable API error instead of leaking a raw parse exception.
- `Index.ets` continues to show a readable `lastError` when connect or refresh fails because of invalid controller responses.
- Compact layout detection still updates when the viewport crosses the compact breakpoint.

## Module Interaction Expectations

- `Index.ets` startup flow:
  - asks `AppConfigStore` for saved settings
  - applies controller settings if loading succeeds
  - falls back to defaults if no settings exist
  - does not crash on recoverable persistence errors
- `Index.ets` settings save flow:
  - calls `AppConfigStore.save()`
  - keeps spec02 behavior that saving settings invalidates active or in-flight connection operations
  - reports persistence failure through the existing error-display path if saving fails
- `MihomoApiService`:
  - owns JSON parsing and parse-error conversion
  - does not require page components to parse raw JSON
- UI pages:
  - receive already-normalized state and error text
  - do not directly access preferences or raw HTTP response bodies

## Tests

- Preview build must pass with no new ArkTS errors.
- Prefer focused tests for extracted pure helpers if parsing or settings normalization is moved into helper functions.
- Manual test checklist:
  - fresh install or cleared settings starts with default controller URL
  - saving settings persists URL and secret
  - restart or preview reload restores saved settings
  - invalid controller JSON shows a concise error and does not mark connected
  - compact layout still switches correctly in portrait and landscape preview
  - disconnect and save settings still invalidate in-flight connect or refresh operations

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
