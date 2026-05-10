# Proxies Page Spec

## Goal

Turn the Proxies page from a group-name list into a usable proxy selector.

The user must be able to view proxy groups, inspect nodes in a selected group, see the current selected node, switch nodes, and run delay checks.

## Functional Requirements

- Display proxy group list using `CalculatedProxies.groups`.
- Select the first available group by default after proxy data loads.
- Selecting a group displays its child nodes from `ProxyGroupItem.all`.
- For each group, show:
  - group name
  - group type
  - current node from `now`
  - child count
- For each node, show:
  - name
  - type
  - provider if present
  - last delay if known
  - selected/current marker if node name matches group `now`
- Clicking a node calls `MihomoApiService.selectNodeForGroup(groupName, proxyName)`.
- After a successful node selection:
  - refresh calculated proxies
  - update group `now`
  - clear action loading state
- Add a delay test action for each node using `MihomoApiService.delayProxyByName(name, url, timeout)`.
- Use a default delay URL and timeout:
  - URL: `https://www.gstatic.com/generate_204`
  - timeout: `5000`
- Add a refresh button to reload proxies manually.
- Show empty state if no groups exist.
- Show error banner when loading, selection, or delay test fails.

## Development Constraints

- Do not keep only `string[]` group names in state. Store `ProxyGroupItem[]`.
- Do not mutate nested group/node objects in place if ArkUI state refresh becomes unreliable. Prefer assigning a new array.
- Do not fake local selection without server confirmation. Call API first, then refresh.
- Avoid `Map`/`Set`; use `Record<string, number>` for delay values and `Record<string, boolean>` for per-node action state.
- Do not add provider update controls here unless the Providers spec is also implemented.
- Keep the page responsive for tablet preview:
  - group list on the left or top
  - node list in the main area
  - avoid oversized cards

## Interface Test Expectations

- `MihomoApiService.calcuProxies()` is the source of group/node data.
- `MihomoApiService.selectNodeForGroup(groupName, proxyName)` is called with exact selected group and node names.
- `MihomoApiService.delayProxyByName(proxyName, url, timeout)` is called for the target node.
- Delay result uses `DelayResponse.delay`.
- If `selectNodeForGroup()` rejects, UI must keep the previous selected state and display an error.
- If delay check rejects, UI must leave any existing delay value intact and display an error.

## Module Interaction Expectations

- Parent state owner provides:
  - current `MihomoApiService`
  - latest `CalculatedProxies`
  - callback to refresh proxies globally after changes
- `ProxiesPage.ets` owns only page-local UI state:
  - selected group name
  - per-node delay values
  - loading/action/error state
- If shared proxy data is stored in parent, node selection must notify parent after refresh.
- If `ProxiesPage.ets` loads its own data, it must still expose refreshed counts to Home or parent state if Home displays proxy counts.

## Tests

- Preview build must pass.
- Add model-level or helper-level tests if proxy-selection helpers are extracted.
- Manual test checklist:
  - no groups shows empty state
  - groups render after connect/refresh
  - selecting a group changes node list
  - current node is visually marked
  - selecting a node calls API and refreshes current node
  - delay test shows delay in ms
  - failed selection shows error and does not corrupt state
  - manual refresh reloads group and node data

## Verification Command

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
$env:JAVA_HOME='D:\software\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'D:\software\DevEco Studio\tools\node\node.exe' 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p pageType=page -p compileResInc=true -p requiredDeviceType=tablet -p previewMode=true -p buildRoot=.preview PreviewBuild --watch --analyze=normal --parallel --incremental --daemon
```
