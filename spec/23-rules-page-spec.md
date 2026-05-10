# Rules Page Spec

## Goal

Implement a readable Rules page for inspecting the active Mihomo rule set.

The page should help users understand why traffic is routed to a policy by showing rule type, payload, and target proxy/policy.

## Functional Requirements

- Add `entry/src/main/ets/pages/RulesPage.ets`.
- Load rules from `MihomoApiService.getRules()`.
- Display a rule summary:
  - total rule count
  - count by rule type if practical
  - current filter/search status
- Display a scrollable rule list with:
  - rule type
  - payload
  - target proxy/policy
  - row index
- Add manual refresh.
- Add search/filter input for payload and proxy text.
- Add a type filter if type extraction is simple and compile-safe.
- Show empty state when no rules exist.
- Show loading and error states.
- Preserve the current rule list while a refresh is in progress, unless the user explicitly clears filters.

## Development Constraints

- Start with HTTP-only data from `/rules`. Do not add live streaming for rules.
- Do not implement rule editing. This page is read-only in this phase.
- Do not add YAML/config parsing.
- Keep filtering simple:
  - payload includes search text
  - proxy includes search text
  - type equals selected type
- Avoid `Set`/`Map`; if type counts are needed, use `Record<string, number>`.
- Avoid heavy chained array expressions if ArkTS reports stdlib or inference errors. Prefer explicit loops.
- Long payload strings must not break the layout. Use max lines or horizontal clipping with readable text.

## Interface Test Expectations

- `MihomoApiService.getRules()` is called on page load or manual refresh when connected.
- `RulesResponse.rules` is converted into a renderable list.
- Each rendered row uses `RuleItem.type`, `RuleItem.payload`, and `RuleItem.proxy`.
- Search text filters against payload and proxy.
- Type filter, if implemented, filters against exact rule type.
- On API failure:
  - existing rules remain visible if previously loaded
  - an error banner is shown
  - loading state is cleared

## Module Interaction Expectations

- Parent router provides:
  - current connected state
  - current `MihomoApiService`
- `RulesPage.ets` owns:
  - `RuleItem[]`
  - search text
  - selected type filter
  - loading state
  - error text
- Rules page must not mutate proxy selection, provider state, or connection state.
- If disconnected, show a connect-required empty state instead of calling APIs.

## Tests

- Preview build must pass.
- Add helper tests if rule filtering is extracted.
- Manual test checklist:
  - disconnected state does not call API
  - refresh loads rules
  - empty rules display empty state
  - search by payload filters rows
  - search by proxy filters rows
  - type filter narrows rows if implemented
  - failed refresh shows error and preserves old rules
  - long rule payloads do not overlap surrounding UI

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
