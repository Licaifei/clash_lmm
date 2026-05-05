# Subscription Import Spec

## Goal

Let the user import and store an airport subscription as the first real input for local VPN mode.

The app should accept a subscription URL, fetch the remote profile, keep a local copy, and expose enough metadata for config generation.

## Functional Requirements

- Add a subscription management page or section reachable from the main navigation.
- Support adding a subscription by URL.
- Validate subscription URL:
  - non-empty
  - trimmed
  - starts with `http://` or `https://`
- Fetch subscription content over HTTP.
- Send request headers compatible with common airport subscription endpoints where possible:
  - `User-Agent` that asks for Clash/Mihomo-compatible output
  - `Accept` for YAML/text responses
- Follow normal HTTP redirects if the platform HTTP client supports them.
- Store the raw subscription content locally.
- Store subscription metadata:
  - id
  - name
  - source URL
  - last updated timestamp
  - byte size
  - content hash if cheap
  - detected format
  - optional subscription user info header values if returned
  - optional user note
- Support manual update for a saved subscription.
- Support deleting a saved subscription.
- Select one active subscription for config generation.
- Show readable update errors without deleting the last good local copy.

## Development Constraints

- Do not start Mihomo Core in this spec.
- Do not start VPN in this spec.
- Do not parse every possible proxy format deeply unless required for validation.
- MVP supported source format is Clash/Mihomo YAML. Base64 proxy URI lists, SIP008, and vendor-specific JSON may be detected and rejected with a clear "unsupported subscription format" error unless a compile-safe converter is deliberately added.
- Treat fetched content as untrusted input.
- Do not log full subscription URLs if they may contain tokens.
- Do not log raw subscription contents.
- Keep local storage behind a service boundary; page components should not write raw files directly.
- Prefer app sandbox files for raw profile content, not Preferences, because subscription YAML can be large.
- Preferences may store metadata and active subscription id.

## Interface Test Expectations

- A subscription service exposes typed operations such as:
  - `addSubscription(url: string, name: string): Promise<SubscriptionProfile>`
  - `updateSubscription(id: string): Promise<SubscriptionProfile>`
  - `deleteSubscription(id: string): Promise<void>`
  - `selectSubscription(id: string): Promise<void>`
  - `loadSubscriptions(): Promise<SubscriptionState>`
- Invalid URL blocks add and update.
- Network failure preserves the previous local profile content.
- Unsupported content format preserves the previous local profile content.
- Delete active subscription either selects another subscription or leaves no active subscription with a clear UI state.
- Metadata load failure does not crash startup.

## Module Interaction Expectations

- `SubscriptionPage.ets` owns form state and visible validation messages.
- `SubscriptionStore` or equivalent owns file paths and metadata persistence.
- `MihomoConfigService` from the next spec reads only the active local subscription path or raw content through a typed API.
- `Index.ets` owns the selected subscription state or receives it from a shared runtime store.
- Existing external-controller settings remain separate from subscription source URLs.

## Tests

- Preview build must pass.
- Add focused tests for URL validation and metadata normalization if test harness supports it.
- Manual test checklist:
  - add invalid URL shows inline error
  - add valid subscription fetches content
  - common Clash/Mihomo subscription response is detected as supported
  - unsupported base64 or JSON response is rejected with clear error
  - update failure keeps previous content
  - delete subscription removes it from list
  - active subscription survives app restart or preview reload
  - raw content and tokenized URL are not printed in logs

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
