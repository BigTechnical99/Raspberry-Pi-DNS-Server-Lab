# Phase 10 — Monitoring, Logging & Performance Metrics

#### Objective

In this phase, I monitored and evaluated the performance, reliability, and operational health of my Raspberry Pi DNS security server.

After configuring AdGuard Home, integrating Unbound, validating DNSSEC, and implementing system security controls in previous phases, I focused on collecting measurable operational data and investigating real system logs.

The primary objectives were to:

- Monitor DNS traffic and filtering activity through AdGuard Home.
- Analyze individual DNS queries and their outcomes.
- Verify the active upstream DNS configuration.
- Measure DNS lookup performance from a Windows client.
- Monitor Raspberry Pi system resources and uptime.
- Verify the health of essential services.
- Investigate DNS errors and identify their likely source.

All results documented in this phase were collected from my actual lab environment.

##### Lab Environment

| Component | Configuration |
|---|---|
| Server hardware | Raspberry Pi 4 |
| Operating system | Raspberry Pi OS Lite (64-bit) |
| Hostname | DNS-SERVER |
| Server IP address | 172.16.0.57 |
| Local subnet | 172.16.0.0/24 |
| Router | 172.16.0.1 |
| DNS filtering | AdGuard Home |
| Upstream DNS resolver | Unbound |
| Unbound endpoint | 127.0.0.1:5335 |
| Client operating system | Windows |
| Remote administration | SSH |

---

#### Step 1 — Monitor AdGuard Home Dashboard Statistics

I accessed the AdGuard Home dashboard from my Windows PC using:

```text
http://172.16.0.57
```

The dashboard provided visibility into DNS requests, filtering activity, client statistics, and upstream resolver performance.

##### Observed DNS Statistics

The dashboard displayed the following metrics for the last 24 hours:

| Metric | Observed value |
|---|---:|
| Total DNS queries | 71,873 |
| Queries blocked by filters | 18,328 |
| Filtering percentage | Approximately 25.5% |
| Blocked malware/phishing | 0 |
| Blocked adult websites | 41 |
| Enforced Safe Search | 76 |
| Average DNS processing time | 77 ms |

AdGuard Home protection was enabled.

The dashboard showed that approximately one-quarter of recorded DNS requests were blocked by configured filters.

The zero malware/phishing count represents the dashboard's recorded value and does not establish that no malicious DNS activity occurred.

##### Top DNS Clients

| Client | DNS requests | Percentage |
|---|---:|---:|
| Router — 172.16.0.1 | 65,564 | 91.22% |
| Windows PC — 172.16.0.74 | 6,308 | 8.78% |
| DNS-SERVER — 172.16.0.57 | 1 | Approximately 0% |

The router accounted for most recorded DNS requests.

This was consistent with the possibility that the router was forwarding DNS requests on behalf of other devices, although the dashboard alone did not establish which devices originally generated those requests.

##### Upstream DNS Statistics

| Upstream DNS server | Requests | Percentage | Average response time |
|---|---:|---:|---:|
| 127.0.0.1:5335 — Unbound | 45,451 | 96.67% | 100 ms |
| 172.16.0.1:53 — Router | 1,564 | 3.33% | 646 ms |

The dashboard showed Unbound handling most recorded upstream requests.

The router also appeared in the upstream statistics, which prompted further investigation into AdGuard Home's resolver configuration.

These dashboard measurements were historical observations, not controlled performance benchmarks.

![AdGuard Home dashboard metrics](screenshots/phase-10-01-adguard-dashboard-metrics.png)

*Figure 1 — AdGuard Home dashboard displaying DNS traffic, filtering statistics, client activity, and upstream resolver metrics.*

---

#### Step 2 — Analyze DNS Query Logs

I opened the AdGuard Home Query Log to investigate individual DNS requests and identify how the server processed them.

The Query Log displayed:

- Requested domain names.
- DNS record types.
- Query timestamps.
- Allowed or blocked status.
- Client information.
- Processing times for completed requests.

##### Observed Query Log Entries

| Domain | Result | Processing time |
|---|---|---|
| iadsdk.apple.com | Blocked by AdGuard DNS filter | Not displayed |
| regstat.api.mega.co.nz | Blocked by AdGuard DNS filter | Not displayed |
| ocsp2.apple.com | Processed | 0.34 ms |
| steamconnecttest.com | Processed | 73 ms |
| pd.itunes.apple.com | Processed | 97–131 ms |
| bag.itunes.apple.com | Processed | 1 ms |

The logs demonstrated that AdGuard Home was recording both blocked and permitted DNS queries.

Blocked requests were identified as matching AdGuard DNS filtering rules, while processed requests included response-time information.

The visible requests were associated with the router at `172.16.0.1`, identified as `RBE971`.

##### Result

Query logging was operational and provided useful information for DNS troubleshooting, filtering verification, and performance analysis.

![AdGuard Home DNS query log analysis](screenshots/phase-10-02-dns-query-log-analysis.png)

*Figure 2 — Query Log showing blocked and processed DNS requests, client identification, and response times.*

---

#### Step 3 — Verify Primary Upstream DNS Configuration

The dashboard showed both Unbound and the router in its upstream statistics.

To investigate this, I opened:

**AdGuard Home → Settings → DNS settings**

I inspected the configured primary upstream DNS servers.

##### Observed Configuration

```text
127.0.0.1:5335
```

This was the only server listed in the primary upstream DNS field.

The DNS server selection mode was set to:

```text
Load-balancing
```

##### Result

The configuration confirmed that AdGuard Home was using the locally hosted Unbound resolver as its configured primary upstream.

The router was not listed as an additional primary upstream.

This matched the DNS architecture established in Phase 7:

```text
Network Clients
       |
       v
AdGuard Home
172.16.0.57:53
       |
       v
Unbound
127.0.0.1:5335
       |
       v
DNS Infrastructure
```

Because only one primary upstream was listed, the load-balancing setting did not indicate that multiple primary resolvers were configured.

![Primary upstream DNS configuration](screenshots/phase-10-03-upstream-dns-configuration.png)

*Figure 3 — AdGuard Home configured with Unbound at 127.0.0.1:5335 as its only primary upstream DNS server.*

---

#### Step 4 — Inspect Fallback, Bootstrap & Private Reverse DNS Settings

I continued reviewing the DNS settings to determine why the router appeared in the upstream statistics.

##### Fallback DNS Configuration

The fallback DNS server field was empty.

This confirmed that no explicit fallback DNS server was configured in the displayed field.

##### Bootstrap DNS Configuration

The bootstrap DNS field included Quad9 addresses, including:

```text
9.9.9.10
149.112.112.10
```

Additional IPv6 bootstrap entries were visible in the configuration.

Bootstrap DNS servers are used when hostname resolution is required for certain upstream resolver configurations.

Because the primary Unbound upstream was configured using a local IP address, hostname-based bootstrap resolution was not ordinarily required for that connection.

##### Private Reverse DNS Configuration

The interface identified the default private reverse DNS resolver as:

```text
172.16.0.1:53
```

The following options were enabled:

- Use private reverse DNS resolvers.
- Enable reverse resolving of clients' IP addresses.

Private reverse DNS allows AdGuard Home to request local hostname information from a resolver such as the home router.

For example, this can help identify a client by hostname instead of displaying only its IP address.

##### Result

The router's role as the default private reverse DNS resolver provided a plausible explanation for its appearance in the dashboard's upstream statistics.

However, the historical statistics alone did not prove that every request attributed to the router was a reverse DNS lookup.

No configuration changes were made during this inspection.

![Fallback and private reverse DNS settings](screenshots/phase-10-04-fallback-reverse-dns-settings.png)

*Figure 4 — AdGuard Home fallback, bootstrap, and private reverse DNS settings showing the router as the default local reverse DNS resolver.*

---

#### Step 5 — Benchmark DNS Response Times

I performed a DNS performance test from Windows PowerShell to measure how quickly the Raspberry Pi responded to repeated DNS queries.

The test consisted of ten sequential requests for the IPv4 address of `example.com`.

##### PowerShell Benchmark Command

```powershell
1..10 | ForEach-Object {
    $domain = "example.com"
    $time = Measure-Command {
        Resolve-DnsName $domain -Server 172.16.0.57 -Type A -DnsOnly -ErrorAction Stop | Out-Null
    }
    [PSCustomObject]@{
        Test = $_
        ResponseTimeMs = [math]::Round($time.TotalMilliseconds, 2)
    }
}
```

##### Observed Benchmark Results

| Test | Response time |
|---|---:|
| 1 | 120.73 ms |
| 2 | 1.77 ms |
| 3 | 1.42 ms |
| 4 | 1.33 ms |
| 5 | 1.23 ms |
| 6 | 1.38 ms |
| 7 | 1.25 ms |
| 8 | 1.44 ms |
| 9 | 1.34 ms |
| 10 | 1.32 ms |

##### Performance Summary

| Metric | Result |
|---|---:|
| Successful queries | 10 of 10 |
| Average response time | 13.32 ms |
| Fastest response | 1.23 ms |
| Slowest response | 120.73 ms |
| Average of tests 2–10 | Approximately 1.39 ms |

The first query took significantly longer than the subsequent requests.

This pattern was consistent with DNS caching, where later requests may be answered using previously cached DNS records.

However, the benchmark did not directly measure cache hits or isolate Unbound's internal processing time.

The PowerShell timings also included command execution overhead, so they represent client-observed lookup times rather than pure DNS server processing latency.

The AdGuard Home dashboard's 77 ms average processing time was a separate metric and was not directly equivalent to these benchmark results.

##### Result

All ten DNS lookups completed successfully, with substantially faster observed completion times after the initial request.

![DNS response-time benchmark](screenshots/phase-10-05-dns-response-time-benchmark.png)

*Figure 5 — Windows PowerShell benchmark showing ten successful DNS queries and their measured completion times.*

---

#### Step 6 — Monitor Raspberry Pi System Resources

I connected to the Raspberry Pi using SSH to evaluate system uptime, workload, memory consumption, storage capacity, and CPU temperature.

##### Check System Uptime

```bash
uptime
```

Observed output:

```text
17:51:26 up 17 days, 11:34, 2 users, load average: 0.00, 0.00, 0.00
```

The Raspberry Pi had been running for over 17 days without a system reboot.

The load averages indicated very low recent system workload.

##### Check Memory Usage

```bash
free -h
```

Observed results:

| Metric | Value |
|---|---:|
| Total RAM | 1.8 GiB |
| Used RAM | 299 MiB |
| Free RAM | 658 MiB |
| Buff/cache | 974 MiB |
| Available RAM | 1.5 GiB |
| Swap used | 0 B |

The server had substantial available memory.

Linux uses otherwise available memory for filesystem caching, so the available-memory figure is generally more informative than the free-memory figure alone.

##### Check Disk Usage

```bash
df -h /
```

Observed results:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p2   59G  4.3G   52G   8% /
```

The root filesystem was using approximately 8% of its capacity, leaving approximately 52 GB available.

##### Check CPU Temperature

```bash
vcgencmd measure_temp
```

Observed result:

```text
temp=51.1'C
```

The CPU temperature was 51.1°C at the time of testing.

This was below the Raspberry Pi 4's typical thermal-throttling threshold of approximately 80°C.

##### Resource Monitoring Summary

| Metric | Observed value |
|---|---|
| Uptime | 17 days, 11 hours, 34 minutes |
| Load average | 0.00 / 0.00 / 0.00 |
| RAM used | 299 MiB |
| RAM available | 1.5 GiB |
| Swap used | 0 B |
| Root filesystem utilization | 8% |
| Available disk space | 52 GB |
| CPU temperature | 51.1°C |

##### Result

The Raspberry Pi demonstrated low resource utilization, substantial memory and storage headroom, and no apparent thermal concern during the captured measurement.

These values represent a point-in-time snapshot and do not establish peak usage under heavier workloads.

![Raspberry Pi resource monitoring](screenshots/phase-10-06-raspberry-pi-resource-monitoring.png)

*Figure 6 — Raspberry Pi terminal displaying uptime, load average, memory usage, disk utilization, and CPU temperature.*

---

#### Step 7 — Verify Service Health & Inspect System Logs

I checked the operational status of AdGuard Home, Unbound, and SSH.

##### Service Health Check

```bash
sudo systemctl is-active AdGuardHome unbound ssh
```

Observed output:

```text
active
active
active
```

All three services were active.

##### Inspect Warning-Level System Logs

I executed:

```bash
sudo journalctl -u AdGuardHome -u unbound -u ssh -p warning --since "24 hours ago" --no-pager
```

Observed result:

```text
-- No entries --
```

This indicated that the command found no matching warning-level or higher-priority entries in the available system journal records for the selected services and time window.

However, this did not guarantee that the applications were completely free of operational errors.

##### Inspect Recent Service Events

I then executed:

```bash
sudo journalctl -u AdGuardHome -u unbound --since "1 hour ago" -n 25 --no-pager
```

The output contained repeated AdGuard Home application-level DNS errors.

An example included:

```text
upstream=172.16.0.1:53
proto=udp
i/o timeout
```

Other entries identified private DNS Service Discovery-related queries such as:

```text
r._dns-sd._udp.0.0.16.172.in-addr.arpa
```

The logs showed that some requests to the router's DNS service were not receiving responses before the timeout.

##### Initial Assessment

The errors appeared related to local DNS discovery and reverse DNS operations rather than ordinary public-domain resolution through Unbound.

This prompted a series of targeted DNS diagnostics.

![Service health and log monitoring](screenshots/phase-10-07-service-health-log-monitoring.png)

*Figure 7 — All essential services report active states, while recent AdGuard Home logs reveal router DNS timeout errors.*

---

#### Step 8 — Test Standard Router Reverse DNS Resolution

To determine whether the router's DNS service was generally unavailable, I tested standard PTR lookups directly from the Raspberry Pi.

##### Test A — Resolve the Windows PC Hostname

```bash
dig @172.16.0.1 -x 172.16.0.74 +time=2 +tries=1
```

Observed results:

```text
status: NOERROR

ANSWER SECTION:
74.0.16.172.in-addr.arpa. 0 IN PTR DESKTOP-TS3RBGF.

Query time: 3 msec
SERVER: 172.16.0.1#53
```

The router successfully returned a hostname for the Windows PC.

##### Test B — Resolve the Router Hostname

```bash
dig @172.16.0.1 -x 172.16.0.1 +time=2 +tries=1
```

Observed results:

```text
status: NOERROR

ANSWER SECTION:
1.0.16.172.in-addr.arpa. 0 IN PTR RBE971.

Query time: 3 msec
SERVER: 172.16.0.1#53
```

The router successfully resolved its own address.

##### Results

| Test | DNS status | Response time |
|---|---|---:|
| Windows PC PTR lookup | NOERROR | 3 ms |
| Router PTR lookup | NOERROR | 3 ms |

Both standard reverse DNS queries succeeded.

##### Interpretation

These results demonstrated that the router's DNS service was reachable and capable of answering ordinary PTR queries.

Therefore, the earlier timeout messages did not establish a complete failure of the router's DNS service.

![Router reverse DNS diagnostics](screenshots/phase-10-08-router-reverse-dns-diagnostics.png)

*Figure 8 — The router successfully resolves standard PTR queries for the Windows PC and its own IP address.*

---

#### Step 9 — Reproduce the DNS Service Discovery Timeout over UDP

After confirming that standard reverse DNS queries worked, I tested the specific DNS Service Discovery query identified in the AdGuard Home logs.

##### UDP Diagnostic Command

```bash
dig @172.16.0.1 r._dns-sd._udp.0.0.16.172.in-addr.arpa PTR +time=2 +tries=1
```

##### Observed Result

```text
communications error to 172.16.0.1#53: timed out

no servers could be reached
```

The router did not respond within the two-second timeout.

##### Interpretation

The result reproduced the timeout behavior seen in the AdGuard Home logs.

Unlike the successful standard PTR queries, this DNS Service Discovery-related request failed to receive a response within the configured timeout.

This narrowed the investigation to a particular DNS query pattern rather than general router DNS availability.

The test did not establish why the router failed to respond.

![DNS Service Discovery UDP diagnostics](screenshots/phase-10-09-dns-service-discovery-diagnostics.png)

*Figure 9 — A DNS Service Discovery-related PTR query times out when sent to the router over UDP.*

---

#### Step 10 — Repeat the DNS Service Discovery Test over TCP

To determine whether the behavior was specific to UDP, I repeated the same query using TCP.

##### TCP Diagnostic Command

```bash
dig @172.16.0.1 r._dns-sd._udp.0.0.16.172.in-addr.arpa PTR +tcp +time=2 +tries=1
```

##### Observed Result

```text
communications error to 172.16.0.1#53: timed out

no servers could be reached
```

The router again failed to respond within two seconds.

##### Diagnostic Comparison

| DNS test | Protocol | Result |
|---|---|---|
| Windows PC standard PTR | UDP | NOERROR — 3 ms |
| Router standard PTR | UDP | NOERROR — 3 ms |
| DNS Service Discovery PTR | UDP | Timeout |
| DNS Service Discovery PTR | TCP | Timeout |

##### Interpretation

The router successfully answered the two standard reverse DNS queries but did not answer the tested DNS Service Discovery query over either UDP or TCP within the configured timeout.

This provided strong evidence that the AdGuard Home errors were associated with the router's handling of this specific type of DNS query.

The tests did not determine whether the cause was router firmware behavior, unsupported DNS Service Discovery handling, filtering, or another network or DNS implementation issue.

Because ordinary DNS resolution and filtering continued working, I documented the behavior as an unresolved local DNS discovery limitation rather than changing the functioning DNS configuration.

![DNS Service Discovery TCP diagnostics](screenshots/phase-10-10-dns-service-discovery-tcp-test.png)

*Figure 10 — The same DNS Service Discovery query also times out over TCP, confirming that the observed failure is not limited to UDP.*

---

#### Challenges & Solutions

##### Challenge 1 — Understanding Unexpected Upstream DNS Statistics

**Challenge:** The AdGuard Home dashboard showed the router as an upstream resolver even though Unbound was intended to handle upstream DNS resolution.

**Approach:** I inspected the primary upstream, fallback, bootstrap, and private reverse DNS settings.

**Finding:** Unbound was the only configured primary upstream, while the router was listed as the default private reverse DNS resolver. This provided a plausible explanation for the router appearing in the dashboard statistics.

##### Challenge 2 — Interpreting DNS Performance Measurements

**Challenge:** The first DNS lookup took significantly longer than the following nine requests.

**Approach:** I compared the ten measurements and calculated their average, fastest, and slowest completion times.

**Finding:** The results were consistent with DNS caching, but the benchmark also included PowerShell execution overhead. I documented the measurements as client-observed lookup times rather than pure DNS server latency.

##### Challenge 3 — Distinguishing Healthy Services from Application Errors

**Challenge:** AdGuard Home, Unbound, and SSH all reported active states, but AdGuard Home logs contained repeated DNS timeout errors.

**Approach:** I reviewed recent application logs and identified the affected upstream address and query names.

**Finding:** The errors involved requests to the router's DNS service, particularly local DNS Service Discovery-related queries.

##### Challenge 4 — Isolating Router DNS Timeout Behavior

**Challenge:** It was unclear whether the router's DNS service was generally unavailable or failing only for certain requests.

**Approach:** I tested standard PTR lookups, followed by the specific DNS Service Discovery query over both UDP and TCP.

**Finding:** Standard PTR queries completed successfully in 3 ms, while the tested DNS Service Discovery query timed out over both protocols.

The underlying reason for the router's behavior remains unresolved.

---

#### Phase 10 Results

| Validation | Observed result | Status |
|---|---|---|
| AdGuard Home statistics | Dashboard collecting DNS and filtering metrics | PASS |
| DNS query logging | Allowed and blocked queries recorded | PASS |
| Primary upstream configuration | Unbound configured at 127.0.0.1:5335 | PASS |
| Fallback and reverse DNS inspection | Configuration inspected and documented | PASS |
| DNS performance benchmark | 10 of 10 lookups successful | PASS |
| System resource monitoring | Uptime, memory, disk, load, and temperature measured | PASS |
| Essential service health | AdGuard Home, Unbound, and SSH active | PASS |
| Standard router reverse DNS | Both PTR queries successful | PASS |
| DNS-SD query over UDP | Timed out | INVESTIGATED |
| DNS-SD query over TCP | Timed out | INVESTIGATED |

##### Key Performance Metrics

| Metric | Recorded value |
|---|---:|
| DNS queries in dashboard period | 71,873 |
| Requests blocked by filters | 18,328 |
| Filtering rate | Approximately 25.5% |
| Dashboard average processing time | 77 ms |
| Benchmark average | 13.32 ms |
| Benchmark average, tests 2–10 | Approximately 1.39 ms |
| System uptime | 17 days, 11 hours, 34 minutes |
| Available RAM | 1.5 GiB |
| Root filesystem utilization | 8% |
| CPU temperature | 51.1°C |

---

#### Evidence Limitations

The Phase 10 evidence represents measurements and observations collected during specific test periods.

The results do not independently establish:

- Continuous uptime or availability beyond the captured system uptime.
- Maximum DNS throughput or performance under heavy concurrent load.
- That all DNS requests are served exclusively by Unbound.
- That repeated fast DNS lookups were definitively caused by cache hits.
- That the router's DNS Service Discovery timeouts affect every device or every DNS-SD query.
- The exact firmware, filtering, or implementation cause of the router's timeout behavior.
- That active systemd services guarantee error-free application behavior.
- That the dashboard's client statistics identify every originating household device.
- That the monitoring configuration provides automated alerts or centralized log retention.

The DNS-SD timeout issue remains an identified but unresolved operational limitation.

---

#### Phase 10 Conclusion

Phase 10 expanded my Raspberry Pi DNS Security Lab from installation and functional validation into operational monitoring and troubleshooting.

I collected real DNS traffic statistics, analyzed filtering activity, inspected upstream resolver configuration, measured DNS lookup performance, and monitored Raspberry Pi system resources.

I also verified essential service health and investigated repeated AdGuard Home DNS errors.

Through targeted diagnostics, I demonstrated that the router could successfully answer standard reverse DNS queries while failing to respond to a specific DNS Service Discovery-related query over both UDP and TCP within the test timeout.

Rather than making unnecessary configuration changes, I documented the observed behavior and its limitations while preserving the working DNS infrastructure.

This phase demonstrates practical experience with:

- DNS monitoring and query analysis.
- DNS filtering metrics.
- Performance measurement.
- Linux system resource monitoring.
- Systemd service administration.
- Journal log analysis.
- DNS troubleshooting using `dig`.
- UDP and TCP DNS diagnostics.
- Technical documentation and evidence-based troubleshooting.

**Phase 10 Status: Monitoring and Diagnostics Complete**

**Next Phase: Phase 11 — Final GitHub Documentation & Portfolio Review**

---

---

[← Project overview](../README.md)
