# Controller Profiles Spec

## Goal

Implement Profiles management for saved Mihomo external-controller endpoints.

In the current architecture, Profiles means app-side controller profiles, not Mihomo core configuration files or subscription YAML management.

## Functional Requirements

- Add `entry/src/main/ets/pages/ProfilesPage.ets`.
- Allow users to manage multiple controller profiles.
- Each profile includes:
  - id
  - name
  - base URL
  - secret
  - optional note
  - last selected timestamp or display text if simple
- Add profile actions:
  - create profile
  - edit profile
  - delete profile
  - select profile
  - duplicate profile if cheap and low-risk
- Selecting a profile updates the current controller config used by the app.
- Persist profiles in `AppConfigStore`.
- Persist selected profile id.
- Preserve the existing single controller settings by migrating them into a default profile when no profiles exist.
- Prevent deletion of the only remaining profile unless a default replacement is created.
- Show validation errors for empty name or empty URL.

## Development Constraints

- Do not implement Mihomo config file import/export.
- Do not implement subscription update.
- Do not write files outside Preferences.
- Do not store secrets in logs or visible status text.
- Keep profile payloads explicitly typed in `MihomoModels.ets` or `AppConfigStore.ets`.
- Be careful with Preferences schema evolution:
  - existing `controller.baseUrl`
  - existing `controller.secret`
  - existing `selectedPage`
  must continue to load.
- Avoid serializing complex classes. Store plain typed records.
- If storing profile arrays as JSON strings, handle parse failure by falling back to a default profile.

## Interface Test Expectations

- `AppConfigStore.load()` returns settings compatible with old saved data.
- `AppConfigStore.save()` preserves selected page and theme while saving profile changes.
- New store methods may be added, but must be typed:
  - `loadProfiles()`
  - `saveProfiles()`
  - `selectProfile()`
  or equivalent.
- Selecting a profile updates:
  - current controller base URL
  - current controller secret
  - selected profile id
- Invalid stored JSON does not crash the app.
- Deleting selected profile selects another available profile.

## Module Interaction Expectations

- Parent state owner keeps:
  - selected controller config
  - selected profile id if implemented globally
- `ProfilesPage.ets` owns:
  - profile list editing UI state
  - local form state
  - validation errors
- `SettingsPage.ets` should display/edit the active profile's URL and secret, or clearly indicate it edits the current controller settings.
- Selecting a profile should disconnect or mark current connection stale unless the app has an explicit reconnect flow.
- Profile changes should not silently start a new connection.

## Tests

- Preview build must pass.
- Add or update `AppConfigStore` tests for:
  - old single-controller settings migration
  - create profile
  - edit profile
  - delete profile
  - select profile
  - invalid profile JSON fallback
- Manual test checklist:
  - first launch creates or shows a default profile from existing settings
  - creating profile validates fields
  - editing active profile updates Settings values
  - selecting profile changes current controller config
  - deleting selected profile chooses a fallback
  - app does not reconnect automatically after profile switch unless explicitly requested

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
