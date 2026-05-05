# Settings Validation And Connection Test Spec

## Goal

Make Settings safer and more useful by validating controller configuration and adding an explicit test-connection action.

Settings should edit configuration, validate it, and optionally test it. Saving settings should not imply the app is connected.

## Functional Requirements

- Improve `SettingsPage.ets` or current Settings section.
- Add validation for:
  - non-empty controller URL
  - URL starts with `http://` or `https://`
  - no trailing whitespace
  - secret can be empty
- Normalize URL before save:
  - trim whitespace
  - remove trailing slash if compatible with existing request builder
- Add secret visibility toggle.
- Add "Test Connection" action:
  - creates a temporary `MihomoApiService` from current input values
  - calls `getVersion()`
  - displays success with version text or failure with error
  - does not mutate global connected state unless user explicitly connects elsewhere
- Add save action:
  - validates fields
  - persists settings/profile current config
  - updates service config in parent
  - marks active connection stale if connected config changed
- Show inline field errors instead of only global status text.
- Keep layout responsive and avoid overlap in compact layout.

## Development Constraints

- Do not log secret values.
- Do not show secret in status text or error messages.
- Do not auto-connect after saving.
- Do not run Test Connection on every text change.
- Do not use complex URL parsing if ArkTS standard library causes compile issues. Simple string checks are acceptable.
- Keep validation helpers explicit and compile-safe.
- Avoid object destructuring.
- If adding payload/settings interfaces, declare them explicitly.

## Interface Test Expectations

- Invalid URL blocks save and test connection.
- Valid URL with empty secret is allowed.
- Test Connection calls `MihomoApiService.getVersion()`.
- Successful test displays version if available.
- Failed test displays concise error.
- Save updates `AppConfigStore`.
- Save updates parent controller config or service config.
- Save does not call `connectAndRefresh()` implicitly.

## Module Interaction Expectations

- `SettingsPage.ets` owns:
  - editable base URL
  - editable secret
  - field errors
  - testing state
  - save state
  - secret visibility state
- Parent state owner receives:
  - saved controller config
  - optional stale-connection notification
- `AppConfigStore` persists normalized values.
- Connection flow remains responsible for actual app connection state.

## Tests

- Preview build must pass.
- Add helper tests if validation is extracted.
- Manual test checklist:
  - empty URL shows validation error
  - unsupported URL scheme shows validation error
  - whitespace is trimmed before save
  - empty secret saves successfully
  - secret visibility toggle works
  - Test Connection success shows version
  - Test Connection failure shows readable error
  - Save does not mark app connected
  - compact layout has no overlapping labels, inputs, or buttons

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
