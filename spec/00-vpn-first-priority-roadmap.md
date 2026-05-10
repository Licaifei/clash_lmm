# VPN First Priority Roadmap

## Goal

Reorder the project plan so the app becomes a real phone VPN client before continuing controller-dashboard feature work.

The first usable milestone is: import an airport subscription, generate a Mihomo-compatible config, start Mihomo Core locally, request system VPN authorization, and route phone traffic through the local core.

## Current Baseline

- `01-shared-foundation-spec.md` is complete enough to keep page boundaries stable.
- `02-connection-refresh-flow-spec.md` is complete enough for external-controller connectivity.
- The current app is still an external-controller UI. It does not bundle Mihomo Core, start a local core, declare `VpnExtensionAbility`, or own phone traffic.

## New Priority Order

1. `01-shared-foundation-spec.md`
2. `02-connection-refresh-flow-spec.md`
3. `03-vpn-platform-capability-spec.md`
4. `04-subscription-import-spec.md`
5. `05-mihomo-config-generation-spec.md`
6. `06-mihomo-core-runtime-spec.md`
7. `07-system-vpn-tunnel-spec.md`
8. `08-minimal-vpn-control-flow-spec.md`

## Deferred Controller Dashboard Specs

These remain useful after the phone VPN baseline works:

- `20-proxies-page-spec.md`
- `21-connections-page-spec.md`
- `22-providers-page-spec.md`
- `23-rules-page-spec.md`
- `24-logs-page-spec.md`
- `25-controller-profiles-spec.md`
- `26-settings-validation-spec.md`
- `27-dashboard-monitoring-spec.md`
- `28-build-warning-stability-cleanup-spec.md`

## Core Definition Of Done

- User can paste or import an airport subscription URL.
- App can fetch and store the subscription result.
- App can identify whether the subscription content is directly usable as Clash/Mihomo YAML, or clearly reject unsupported formats.
- App can generate a valid Mihomo config with local mixed port, external-controller values, DNS, and rule/proxy sections.
- App can start and stop Mihomo Core on the phone, or clearly report that the runtime path is unsupported on the target device before later specs continue.
- App can start and stop a `VpnExtensionAbility`.
- App can obtain system VPN authorization.
- App can create a VPN tunnel and route device traffic through a real packet bridge into the local Mihomo path.
- App can show a single reliable running state: stopped, preparing, core running, VPN active, failed.

## Gate Rule

`03-vpn-platform-capability-spec.md` is a hard gate. If the target SDK/device cannot support either local Mihomo runtime execution or a packet bridge from `VpnExtensionAbility`, Claude Code should stop the VPN branch, write the exact blocker into the spec result, and not implement UI-only placeholders that imply phone traffic is protected.

## External References

- OpenHarmony VPN Extension development guide: https://gitee.com/openharmony/docs/blob/08986484ea997e1da01ac9221d20dbb0a54b4922/en/application-dev/network/net-vpnExtension.md
- VPN APIs begin at API version 11 according to the OpenHarmony documentation.
- The documentation states only one active VPN connection is supported, so the app must handle system rejection when another VPN is already active.
