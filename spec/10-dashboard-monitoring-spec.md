# Dashboard Monitoring Spec

## Goal

Expand Home dashboard monitoring beyond version, mode, and live traffic.

The Home page should become a compact health overview for the connected Mihomo controller while keeping detailed operations in their dedicated pages.

## Functional Requirements

- Extend Home dashboard to show:
  - connection state
  - version
  - mode
  - live upload/download speed
  - active connection count
  - total upload/download from connections endpoint if available
  - proxy group count
  - node count
  - memory usage from WebSocket `memory` topic
- Add manual refresh.
- Add optional auto-refresh interval for HTTP summary data:
  - default off or conservative
  - do not implement if it complicates state ownership
- Start memory WebSocket only when connected and Home monitoring is active.
- Close memory WebSocket on disconnect.
- Keep traffic WebSocket behavior from the connection flow.
- Show stale/last updated text.
- Show concise error status without replacing all dashboard values.

## Development Constraints

- Do not overload Home with detailed lists. Keep lists in Proxies, Connections, Providers, Rules, and Logs pages.
- Do not open duplicate WebSocket streams.
- Use separate `MihomoWsSubscription` instances for traffic and memory.
- Do not make Home own connection closing if connection flow already owns it.
- Avoid fast polling. If auto-refresh is added, interval should be explicit and easy to disable.
- Use explicit typed parsing for `TrafficItem` and `MemoryItem`.
- Do not assume memory `oslimit` is present.
- Compact layout must keep cards vertical and readable.

## Interface Test Expectations

- Connection flow provides or triggers:
  - version
  - base config mode
  - calculated proxy counts
- Connections summary calls `MihomoApiService.getConnections()` if active connection count or totals are displayed.
- Memory stream uses `MihomoWsSubscription.connect(config, 'memory', ...)`.
- Memory JSON parses into `MemoryItem`.
- Invalid memory message shows a non-fatal warning or is ignored without crashing.
- Disconnect closes memory subscription.
- Refresh updates dashboard summary without resetting live traffic unnecessarily.

## Module Interaction Expectations

- Parent state owner keeps dashboard summary fields if Home is presentational.
- `HomePage.ets` receives:
  - dashboard values
  - loading states
  - connection state
  - refresh/connect/disconnect callbacks
- If Home owns memory subscription, it must expose lifecycle hooks or callbacks that close it when app disconnects.
- Connections page remains the source for detailed connection rows; Home only displays counts/totals.
- Logs page remains the source for detailed logs; Home should not display logs.

## Tests

- Preview build must pass.
- Add helper tests if byte/memory formatting is extracted.
- Manual test checklist:
  - disconnected dashboard shows connect-required state
  - connected dashboard shows version/mode/traffic
  - proxy counts update after proxy refresh
  - connection count/totals update after refresh
  - memory usage updates while connected
  - disconnect stops memory updates
  - invalid memory message does not crash
  - compact layout displays cards vertically with no clipped text

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
