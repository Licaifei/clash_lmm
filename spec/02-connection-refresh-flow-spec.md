# Connection And Refresh Flow Spec

## Goal

Make the app connection lifecycle reliable before deeper feature work depends on it.

The user must be able to connect to the configured Mihomo external controller, see clear loading/success/failure state, refresh data, and disconnect cleanly.

## Functional Requirements

- Add explicit connection state:
  - disconnected
  - connecting
  - connected
  - refreshing
  - failed
- Add a connect action that:
  - reads current controller URL and secret
  - creates or updates `MihomoApiService`
  - loads version, base config, and calculated proxies
  - starts traffic WebSocket subscription only after the initial HTTP load succeeds
  - persists current settings after a successful connection
- Add a refresh action that:
  - reuses current `MihomoApiService`
  - reloads version, base config, and calculated proxies
  - does not create duplicate WebSocket subscriptions
- Add a disconnect action that:
  - closes traffic WebSocket
  - marks the app disconnected
  - clears live traffic values
  - keeps saved controller settings intact
- Disable connect/refresh buttons while the corresponding operation is already running.
- Display a concise last error message when HTTP or WebSocket operations fail.
- Keep Home dashboard values visible after refresh unless the connection is explicitly disconnected.

## Development Constraints

- `startTraffic()` must close any old traffic subscription before opening a new one.
- Do not start multiple traffic WebSocket streams.
- Do not silently swallow errors. Convert errors to user-readable text.
- Do not automatically claim connected state until the initial HTTP requests succeed.
- Do not make settings save imply a successful connection.
- Keep `Promise.all` for initial parallel HTTP requests, but do not use array destructuring.
- Do not add retry loops yet. Reconnect behavior can be added later.

## Interface Test Expectations

- `MihomoApiService.getVersion()` is called during connect and refresh.
- `MihomoApiService.getBaseConfig()` is called during connect and refresh.
- `MihomoApiService.calcuProxies()` is called during connect and refresh.
- `MihomoWsSubscription.connect()` is called only after successful HTTP initialization.
- `MihomoWsSubscription.close()` is called on disconnect and before replacing an active stream.
- `AppConfigStore.save()` is called after successful connect and when settings are explicitly saved.

## Module Interaction Expectations

- `Index.ets` or a future controller-state owner keeps:
  - current controller config
  - connection state
  - dashboard data
  - traffic subscription instance
- `HomePage.ets` receives:
  - connection state
  - version text
  - mode text
  - traffic values
  - proxy counts
  - last error
  - connect/refresh/disconnect callbacks
- `SettingsPage.ets` edits controller config but does not independently test or mutate connection state unless explicitly wired through parent callbacks.
- Feature pages should be able to check whether the app is connected before triggering API actions.

## Tests

- Preview build must pass.
- Add focused unit-style tests where practical for state helpers if they are extracted into testable functions.
- Manual test checklist:
  - app opens as disconnected
  - connect button enters loading state
  - failed connection shows error and does not mark connected
  - successful connection shows connected state and traffic begins updating
  - refresh updates dashboard data without duplicating traffic streams
  - disconnect closes the stream and resets live traffic
  - settings remain saved after disconnect

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
