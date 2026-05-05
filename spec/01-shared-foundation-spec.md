# Shared Foundation Spec

## Goal

Prepare the codebase so the first batch of Mihomo controller features can be developed independently without every task editing `Index.ets`.

This is a prerequisite spec. Complete it before assigning the feature specs to separate Claude Code sessions.

## Functional Requirements

- Keep `entry/src/main/ets/pages/Index.ets` responsible only for:
  - navigation state
  - controller configuration state
  - `MihomoApiService` ownership
  - high-level page routing
- Extract current page bodies into separate page components:
  - `entry/src/main/ets/pages/HomePage.ets`
  - `entry/src/main/ets/pages/ProxiesPage.ets`
  - `entry/src/main/ets/pages/ConnectionsPage.ets`
  - `entry/src/main/ets/pages/ProvidersPage.ets`
  - `entry/src/main/ets/pages/SettingsPage.ets`
- Add reusable small UI components:
  - `entry/src/main/ets/components/EmptyState.ets`
  - `entry/src/main/ets/components/ErrorBanner.ets`
  - `entry/src/main/ets/components/LoadingRow.ets`
  - `entry/src/main/ets/components/SectionHeader.ets`
- Preserve the current navigation items:
  - Home
  - Proxies
  - Profiles
  - Connections
  - Rules
  - Logs
  - Settings
- Providers can be added as a separate navigation item or placed under Proxies, but the chosen location must be consistent with the Providers spec.
- Placeholder pages may remain for Profiles, Rules, and Logs.

## Development Constraints

- Do not add new runtime dependencies.
- Do not change external-controller architecture. The app must not start or bundle Mihomo core.
- Avoid large all-in-one components. `Index.ets` should shrink, not grow.
- Keep ArkTS strict-mode compatibility:
  - no array destructuring
  - no object destructuring
  - no untyped object literal API payloads
  - no `Object.assign`
  - avoid `Set` and `Map`; use `Record<string, T>` where practical
  - annotate callback return types where the compiler may infer poorly
- Keep existing colors and component style unless a feature spec requires a specific adjustment.
- Do not implement feature behavior in this foundation task beyond preserving current behavior.

## Interface Test Expectations

- Existing public service interfaces remain unchanged:
  - `MihomoApiService`
  - `MihomoWsSubscription`
  - `AppConfigStore`
- Page components should receive typed props rather than importing global state from `Index.ets`.
- Expected prop categories:
  - state values to display
  - callbacks for user actions
  - optional loading/error text
- No page component should create its own `MihomoApiService` unless a feature spec explicitly allows it.

## Module Interaction Expectations

- `Index.ets` owns shared controller state and passes data/callbacks down.
- `HomePage.ets` receives dashboard state and connect/refresh callbacks.
- `SettingsPage.ets` receives controller URL/secret values and save callbacks.
- `ProxiesPage.ets`, `ConnectionsPage.ets`, and `ProvidersPage.ets` can initially show empty/placeholder states until their feature specs are implemented.
- Shared components must be presentation-only. They should not call APIs or read preferences.

## Tests

- Run the preview compile command after extraction.
- Add or update import smoke tests if existing component import tests fail.
- Manual smoke expectations:
  - app still shows sidebar navigation
  - Home content still renders
  - Proxies content still renders the existing proxy summary/list when data exists
  - Settings can still edit and save URL/secret

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
