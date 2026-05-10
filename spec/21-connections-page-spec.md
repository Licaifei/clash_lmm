# Connections Page Spec

## Goal

Implement a usable Connections page for inspecting active Mihomo connections and closing one or all connections.

## Functional Requirements

- Add `ConnectionsPage.ets`.
- Load data from `MihomoApiService.getConnections()`.
- Display summary values:
  - total download
  - total upload
  - active connection count
- Display active connection rows with:
  - destination host or `remoteDestination`
  - process name if available
  - network/type
  - rule and rule payload
  - chains
  - upload/download bytes
  - start time
- Add manual refresh.
- Add close button for each connection using `closeConnection(id)`.
- Add close-all button using `closeAllConnections()`.
- After closing one or all connections, refresh the list.
- Show empty state when there are no active connections.
- Show loading and error state for list load and close actions.

## Development Constraints

- Start with HTTP refresh only. Do not wire WebSocket `connections` stream in this feature unless the HTTP version is already complete and stable.
- Treat optional metadata fields defensively:
  - `destinationIP`
  - `remoteDestination`
  - `process`
  - `processPath`
- Do not assume connection IDs are human-readable.
- Do not block the whole page when closing one connection; use per-row action state where practical.
- Avoid table layouts that rely on tight desktop widths. Tablet preview must remain readable.
- Keep byte formatting local or reuse a shared utility if one already exists.

## Interface Test Expectations

- `MihomoApiService.getConnections()` returns `ConnectionsResponse`.
- `ConnectionsResponse.downloadTotal` and `uploadTotal` are displayed through byte formatting.
- Each row action calls `MihomoApiService.closeConnection(id)` with the exact `ConnectionItem.id`.
- Close-all calls `MihomoApiService.closeAllConnections()`.
- After close success, `getConnections()` is called again.
- On close failure, the row remains visible and an error is shown.

## Module Interaction Expectations

- Parent page router provides `MihomoApiService` or a typed callback wrapper.
- `ConnectionsPage.ets` owns:
  - current `ConnectionItem[]`
  - total upload/download
  - loading state
  - error text
  - per-connection closing state
- Home dashboard traffic remains owned by connection flow / traffic WS. Connections page should not mutate Home traffic counters.
- If disconnected, page should show a connect-required state rather than trying to call APIs.

## Tests

- Preview build must pass.
- Add helper tests if destination formatting or byte formatting is extracted.
- Manual test checklist:
  - disconnected state does not call API
  - refresh loads active connections
  - empty list renders clearly
  - close one removes or refreshes the row after success
  - close all clears the list after success
  - failed close displays error without clearing the list
  - long hosts/chains do not break layout

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
