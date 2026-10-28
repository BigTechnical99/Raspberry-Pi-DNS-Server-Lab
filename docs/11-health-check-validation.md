# Phase 11 — DNS Health-Check Validation

## Objective

Validate the repository's read-only Bash health-check script on the actual Raspberry Pi DNS server and record observed service, DNS resolution, and system-resource results.

## Test environment

| Item | Observed value |
|---|---|
| Test date and time | 2026-10-27 21:31:55 -04:00 |
| Hostname | DNS-SERVER |
| Raspberry Pi LAN address | 172.16.0.57 |
| AdGuard Home DNS endpoint | 172.16.0.57:53 |
| Unbound DNS endpoint | 127.0.0.1:5335 |
| SSH username | himothy_taylor99 |

## Deployment and execution

The script was downloaded from the repository to `~/dns-lab/scripts/dns-health-check.sh` and executed on the Raspberry Pi:

```bash
DNS_SERVER=172.16.0.57 bash ~/dns-lab/scripts/dns-health-check.sh
```

The explicit `DNS_SERVER` value directs the AdGuard Home lookup to its LAN listener.

## Observed results

```text
DNS infrastructure health check — 2026-10-27T21:31:55-04:00
Hostname: DNS-SERVER

[PASS] AdGuard Home service active (AdGuardHome.service)
[PASS] Unbound service active (unbound.service)
[PASS] SSH service active (ssh.service)
[PASS] AdGuard Home resolved example.com via 172.16.0.57:53
[PASS] Unbound resolved example.com via 127.0.0.1:5335

Uptime: up 2 hours, 43 minutes

Memory:
Mem: 1.8Gi total, 289Mi used, 1.4Gi free, 207Mi buff/cache, 1.5Gi available
Swap: 1.8Gi total, 0B used, 1.8Gi free

Root filesystem:
/dev/mmcblk0p2 59G 4.3G 52G 8% /

CPU temperature: 52.095 °C

Summary: 0 failure(s), 0 warning(s)
```

### Validation summary

| Check | Outcome |
|---|---|
| AdGuard Home systemd service | PASS |
| Unbound systemd service | PASS |
| SSH systemd service | PASS |
| AdGuard Home A-record resolution | PASS |
| Unbound A-record resolution | PASS |
| Script-reported failures | 0 |
| Script-reported warnings | 0 |

### Resource observations

- **Uptime:** 2 hours, 43 minutes at capture time.
- **Memory:** 289 MiB used out of 1.8 GiB total; 1.5 GiB available.
- **Swap:** 0 B used.
- **Root filesystem:** 4.3 GB used out of 59 GB (8%).
- **CPU temperature:** 52.095 °C.

## Evidence

A terminal screenshot was captured showing the command and full output. The image is not yet committed to the repository. Once uploaded to `screenshots/phase11-dns-health-check-success.png`, uncomment the following Markdown line to display it:

<!-- ![Phase 11 successful DNS health-check run](../screenshots/phase11-dns-health-check-success.png) -->

## Interpretation and limitations

The on-device run confirms that the three monitored systemd services were active and that both configured DNS endpoints resolved the test domain successfully at the time of execution. The resource figures are a point-in-time snapshot.

This check does **not** establish continuous availability, automated scheduling or alerting, DNSSEC correctness, filtering effectiveness, performance under load, or resolution of the previously documented router DNS Service Discovery timeouts.

**Phase 11 health-check validation status: COMPLETE (5/5 checks passed).**
