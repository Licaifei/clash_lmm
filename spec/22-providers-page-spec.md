# Providers Page Spec

## Goal

Implement provider management for Mihomo proxy providers.

The user must be able to view configured proxy providers, update a provider, and run provider health checks.

## Functional Requirements

- Add `ProvidersPage.ets`.
- Load provider data from `MihomoApiService.getProxyProviders()`.
- Display provider list with:
  - name
  - type
  - vehicle type
  - updated time
  - proxy count
- Add refresh button for provider list.
- Add update action for each provider using `updateProxyProvider(providerName)`.
- Add health check action for each provider using `healthcheckProxyProvider(providerName)`.
- After update or health check:
  - refresh providers
  - refresh calculated proxies if parent/shared state uses provider data
- Show empty state if no providers exist.
- Show loading and error state for list and actions.
- Use Providers navigation placement consistently:
  - either add a top-level `Providers` nav item
  - or add provider controls inside the Proxies page
  - preferred for first batch: top-level `Providers` nav item for isolated development

## Development Constraints

- Do not implement subscription/profile management here.
- Do not assume provider update returns JSON. Current service returns `Promise<void>`.
- Provider update may take time. Show per-provider action state.
- Avoid `Date` parsing unless needed. Display `updatedAt` as returned first.
- Do not mix provider node selection into this page. Node selection belongs to Proxies.
- Keep the API wrapper unchanged unless a compile error or real endpoint mismatch is found.

## Interface Test Expectations

- `MihomoApiService.getProxyProviders()` is called on page load/refresh.
- `ProxyProvidersResponse.providers` is converted into a renderable array.
- `MihomoApiService.updateProxyProvider(providerName)` is called with exact provider name.
- `MihomoApiService.healthcheckProxyProvider(providerName)` is called with exact provider name.
- After either action succeeds, provider data is refreshed.
- If a parent proxy refresh callback exists, it is called after provider update/healthcheck.
- On action failure, provider list remains visible and error is shown.

## Module Interaction Expectations

- Parent router provides:
  - current `MihomoApiService`
  - connected/disconnected state
  - optional callback to refresh proxy data
- `ProvidersPage.ets` owns:
  - provider list
  - provider loading state
  - provider error text
  - active action provider name
- Provider page should not directly mutate Proxies page UI state. It may notify parent to refresh shared proxy data.
- If disconnected, show connect-required state instead of calling provider APIs.

## Tests

- Preview build must pass.
- Add helper tests if provider response conversion is extracted.
- Manual test checklist:
  - disconnected state does not call API
  - provider list loads and displays counts
  - refresh reloads provider data
  - update action shows per-provider loading
  - health check action shows per-provider loading
  - action success refreshes provider data
  - action failure shows error without clearing current list

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
