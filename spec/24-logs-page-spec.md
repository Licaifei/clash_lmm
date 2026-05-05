# Logs Page Spec

## Goal

Implement a live Logs page using the existing Mihomo WebSocket wrapper.

The user must be able to subscribe to logs, choose a log level, pause/resume display, clear visible logs, and inspect recent messages without breaking the rest of the app.

## Functional Requirements

- Add `entry/src/main/ets/pages/LogsPage.ets`.
- Use `MihomoWsSubscription` with topic `logs`.
- Support log level selection:
  - `debug`
  - `info`
  - `warning`
  - `error`
  - `silent` only if Mihomo accepts it in current controller behavior
- Display incoming log messages in a scrollable list.
- Parse messages into `LogItem` when JSON parsing succeeds.
- If parsing fails, display the raw message safely.
- Provide controls:
  - start logs
  - stop logs
  - pause/resume display
  - clear visible logs
  - change level and reconnect
- Limit visible log entries to a fixed maximum, preferred default: 300.
- Show stream status:
  - stopped
  - connecting/active
  - paused
  - error
- Show empty state when no logs have arrived.

## Development Constraints

- Do not reuse the Home traffic `MihomoWsSubscription` instance. Logs must have a separate subscription.
- Always close the log subscription on page disappearance or when switching level.
- Do not store unbounded logs in state.
- Do not let frequent log messages freeze the UI. Trim old entries when adding new messages.
- Do not assume every message is JSON.
- Avoid object destructuring and array destructuring.
- Avoid `Date` formatting complexity unless it is already straightforward. Raw `LogItem.time` is acceptable.
- Do not write logs to files.

## Interface Test Expectations

- `MihomoWsSubscription.connect(config, 'logs', onMessage, onError, level)` is called when starting logs.
- `MihomoWsSubscription.close()` is called when stopping logs, changing level, leaving page, or component disappearance.
- JSON messages that match `LogItem` display:
  - type
  - payload
  - time if present
- Non-JSON messages display as raw payload.
- When paused:
  - incoming messages should not append to visible list
  - stream may remain connected
- When visible log count exceeds the max, oldest entries are removed.

## Module Interaction Expectations

- Parent router provides:
  - current connected state
  - current controller config
- Logs page owns:
  - its own `MihomoWsSubscription`
  - log level
  - stream status
  - visible log entries
  - paused state
  - error text
- Logs page must not affect Home traffic stream.
- If disconnected, show connect-required state and close any existing log subscription.

## Tests

- Preview build must pass.
- Add helper tests if log parsing or trimming is extracted.
- Manual test checklist:
  - disconnected state does not open WebSocket
  - start opens logs stream
  - stop closes logs stream
  - level change reconnects with the selected level
  - clear removes visible logs
  - pause prevents visible appends
  - resume allows new logs to append
  - non-JSON log message renders safely
  - max log count is enforced
  - switching away from page closes subscription if page lifecycle supports it

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
