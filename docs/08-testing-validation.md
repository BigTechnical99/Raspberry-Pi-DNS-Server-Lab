# Phase 9 — DNS Security Testing & Validation

#### Objective

In this phase, I performed a series of DNS security and functionality tests to validate my Raspberry Pi DNS server after configuring AdGuard Home, integrating Unbound, enabling DNSSEC validation, and hardening the system.

The objective was to confirm that the DNS server could successfully resolve legitimate domains, block advertising-related domains, reject invalid DNSSEC responses, recover after a service restart, and function as the configured DNS server for my Windows PC.

All tests were performed using my actual lab environment, with screenshots documenting the observed results.

##### Lab Environment

| Component | Configuration |
|---|---|
| DNS server | Raspberry Pi 4 |
| Hostname | DNS-SERVER |
| DNS server IP | 172.16.0.57 |
| Operating system | Raspberry Pi OS Lite (64-bit) |
| DNS filtering | AdGuard Home |
| Local upstream resolver | Unbound |
| Unbound endpoint | 127.0.0.1:5335 |
| Client operating system | Windows |
| Client connection | Ethernet |
| Local subnet | 172.16.0.0/24 |

---

#### Step 1 — Verify DNS Resolution from Windows

The first test was designed to confirm that my Windows PC could communicate with the Raspberry Pi DNS server and successfully resolve a legitimate domain.

I opened Windows PowerShell and executed:

```powershell
nslookup example.com 172.16.0.57
```

##### Observed Results

```text
Server:  DNS-SERVER
Address: 172.16.0.57

Non-authoritative answer:
Name:    example.com
Addresses: 2606:4700:10::6814:179a
           2606:4700:10::ac42:93f3
           104.20.23.154
           172.66.147.243
```

The DNS query completed successfully and returned both IPv4 and IPv6 addresses.

This confirmed that my Windows PC could reach the Raspberry Pi's DNS endpoint and receive a valid DNS response.

Because the server address was explicitly specified, this test did not establish whether Windows was using the Raspberry Pi as its default DNS server. That was tested separately later in the phase.

![Windows DNS resolution validation](screenshots/phase-9-01-windows-dns-resolution.png)

*Figure 1 — Windows PowerShell successfully resolves example.com using the Raspberry Pi DNS server at 172.16.0.57.*

---

#### Step 2 — Validate DNS Filtering

Next, I tested whether AdGuard Home could block a domain associated with advertising services.

From Windows PowerShell, I executed:

```powershell
nslookup doubleclick.net 172.16.0.57
```

##### Observed Results

```text
Server:  DNS-SERVER
Address: 172.16.0.57

Non-authoritative answer:
Name:    doubleclick.net
Addresses: ::
           0.0.0.0
```

Instead of returning the domain's normal public IP addresses, the DNS server returned:

- `0.0.0.0` — null IPv4 address
- `::` — unspecified IPv6 address

These responses are consistent with AdGuard Home's DNS blocking behavior.

##### Result

The test confirmed that the DNS filtering configuration successfully blocked the tested advertising-related domain.

![DNS filtering validation](screenshots/phase-9-02-dns-filtering-validation.png)

*Figure 2 — AdGuard Home returns null IPv4 and IPv6 addresses for doubleclick.net, demonstrating DNS filtering.*

---

#### Step 3 — Validate DNSSEC Enforcement

DNSSEC (Domain Name System Security Extensions) helps protect DNS integrity by allowing validating resolvers to detect improperly signed or tampered DNS data.

Because my DNS architecture uses Unbound as AdGuard Home's upstream resolver, I tested whether the client-facing DNS server would reject a domain intentionally configured with invalid DNSSEC signatures.

I executed:

```powershell
nslookup dnssec-failed.org 172.16.0.57
```

##### Observed Results

```text
Server:  DNS-SERVER
Address: 172.16.0.57

*** DNS-SERVER can't find dnssec-failed.org: Server failed
```

The query returned a server failure rather than a normal DNS answer.

The domain `dnssec-failed.org` is designed to fail DNSSEC validation.

##### Result

This result was consistent with successful DNSSEC enforcement. Combined with the direct Unbound DNSSEC tests performed in Phase 7, it provided supporting evidence that invalid DNSSEC responses were being rejected through the configured DNS setup.

The failure response alone does not identify the internal cause of every possible DNS failure.

![DNSSEC enforcement validation](screenshots/phase-9-03-dnssec-enforcement-validation.png)

*Figure 3 — The Raspberry Pi DNS server returns a server failure when querying an intentionally invalid DNSSEC test domain.*

---

#### Step 4 — Test AdGuard Home Service Recovery

To evaluate service recovery, I performed a controlled restart of AdGuard Home and verified that it returned to an operational state.

I connected to the Raspberry Pi through SSH and executed:

```bash
sudo systemctl restart AdGuardHome
```

After the restart, I checked the service state:

```bash
sudo systemctl is-active AdGuardHome
```

##### Observed Result

```text
active
```

I then inspected the service details:

```bash
sudo systemctl status AdGuardHome --no-pager
```

The service reported:

```text
Loaded: loaded
Active: active (running)
```

The startup logs also confirmed that AdGuard Home initialized its network listeners.

##### Verified Network Listeners

| Service | Address | Port |
|---|---|---|
| DNS over UDP | 172.16.0.57 | 53 |
| DNS over TCP | 172.16.0.57 | 53 |
| AdGuard Home web interface | 172.16.0.57 | 80 |

The service was also marked as enabled in systemd.

##### Result

AdGuard Home successfully restarted, returned to an active state, and initialized its DNS and web interface listeners.

No startup errors were visible in the captured status output.

![AdGuard Home service recovery](screenshots/phase-9-04-adguard-service-recovery.png)

*Figure 4 — AdGuard Home successfully restarts, reports an active running state, and initializes its DNS listeners.*

---

#### Step 5 — Verify DNS Resolution and Filtering After Restart

Although the service reported that it was running, I wanted to verify that it could still perform its primary functions from a separate network client.

I returned to Windows PowerShell and performed two additional tests.

##### Test A — Normal DNS Resolution

```powershell
nslookup example.com 172.16.0.57
```

Observed results:

```text
Server:  DNS-SERVER
Address: 172.16.0.57

Non-authoritative answer:
Name:    example.com
Addresses: 2606:4700:10::6814:179a
           2606:4700:10::ac42:93f3
           172.66.147.243
           104.20.23.154
```

The DNS server successfully resolved the legitimate domain after restarting.

##### Test B — DNS Filtering

```powershell
nslookup doubleclick.net 172.16.0.57
```

Observed results:

```text
Server:  DNS-SERVER
Address: 172.16.0.57

Non-authoritative answer:
Name:    doubleclick.net
Addresses: ::
           0.0.0.0
```

The DNS server continued returning blocking responses for the advertising-related domain.

##### Result

Both tests passed.

The results demonstrated that AdGuard Home recovered its DNS resolution and filtering functionality after the controlled service restart.

![Post-restart DNS validation](screenshots/phase-9-05-post-restart-dns-validation.png)

*Figure 5 — Windows successfully resolves example.com and receives a blocking response for doubleclick.net after AdGuard Home restarts.*

---

#### Step 6 — Verify Windows DNS Client Configuration

Earlier tests explicitly directed DNS queries to the Raspberry Pi. I next verified that my Windows Ethernet adapter was actually configured to use the Raspberry Pi as its DNS server.

From Windows PowerShell, I executed:

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

##### Observed Results

```text
InterfaceAlias             InterfaceIndex AddressFamily ServerAddresses
--------------             -------------- ------------- ---------------
Ethernet                   9              IPv4          {172.16.0.57}
Loopback Pseudo-Interface 1 1             IPv4          {}
```

##### Configuration Findings

| Setting | Observed value |
|---|---|
| Network adapter | Ethernet |
| Interface index | 9 |
| Address family | IPv4 |
| Configured DNS server | 172.16.0.57 |
| Additional IPv4 DNS servers | None listed |

This confirmed that the Windows Ethernet adapter was configured to use the Raspberry Pi as its IPv4 DNS server.

The test did not separately inspect IPv6 DNS settings or all possible application-specific DNS behavior.

![Windows default DNS configuration](screenshots/phase-9-06-windows-default-dns-configuration.png)

*Figure 6 — Windows PowerShell confirms that the Ethernet adapter uses 172.16.0.57 as its configured IPv4 DNS server.*

---

#### Step 7 — Validate Default DNS Resolution

For the final client-side test, I verified that Windows could automatically select the Raspberry Pi DNS server without manually specifying its address.

I executed:

```powershell
nslookup example.com
```

Unlike previous queries, this command did not include a DNS server IP address.

##### Observed Results

```text
Server:  DNS-SERVER
Address: 172.16.0.57

Non-authoritative answer:
Name:    example.com
Addresses: 2606:4700:10::6814:179a
           2606:4700:10::ac42:93f3
           172.66.147.243
           104.20.23.154
```

##### Result

Windows automatically selected `DNS-SERVER` at `172.16.0.57` and successfully resolved the domain.

This demonstrated that ordinary Windows `nslookup` queries could use the Raspberry Pi DNS server without explicitly specifying its IP address.

![Default DNS resolution](screenshots/phase-9-07-default-dns-resolution.png)

*Figure 7 — Windows automatically selects the Raspberry Pi DNS server and successfully resolves example.com without a manually specified server address.*

---

#### Challenges & Solutions

##### Challenge 1 — Distinguishing DNS Reachability from Default DNS Configuration

**Challenge:** A successful query directed to a specific DNS server does not prove that the client normally uses that server.

**Solution:** I inspected the Windows Ethernet adapter's DNS configuration and then performed a lookup without specifying a DNS server. Both tests confirmed that the Raspberry Pi was selected for normal Windows nslookup requests.

##### Challenge 2 — Confirming Filtering Rather Than Basic DNS Resolution

**Challenge:** Successful DNS resolution alone does not demonstrate that AdGuard Home is blocking unwanted domains.

**Solution:** I tested an advertising-related domain and verified that the server returned null IPv4 and IPv6 addresses instead of normal public addresses.

##### Challenge 3 — Verifying Service Functionality After Restart

**Challenge:** A service can report an active state even if its application-level functionality is not operating correctly.

**Solution:** After restarting AdGuard Home, I performed additional DNS resolution and filtering tests from Windows to confirm that both functions remained operational.

##### Challenge 4 — Interpreting DNSSEC Failure Responses

**Challenge:** A DNS server failure can have multiple causes, so a single failed lookup is not sufficient to prove the complete DNSSEC validation process.

**Solution:** I used a deliberately invalid DNSSEC test domain and interpreted the result alongside the direct Unbound DNSSEC validation evidence collected in Phase 7.

---

#### Phase 9 Results

| Validation | Observed result | Status |
|---|---|---|
| Windows DNS resolution | Valid IPv4 and IPv6 answers returned | PASS |
| DNS filtering | Null addresses returned for doubleclick.net | PASS |
| DNSSEC enforcement | Server failure for dnssec-failed.org | PASS |
| AdGuard Home restart | Service returned to active running state | PASS |
| Post-restart DNS functionality | Resolution and filtering both successful | PASS |
| Windows IPv4 DNS configuration | Ethernet configured with 172.16.0.57 | PASS |
| Default Windows DNS resolution | Raspberry Pi automatically selected | PASS |

##### Key Accomplishments

- Validated DNS communication between Windows and the Raspberry Pi.
- Demonstrated DNS filtering using a known advertising-related domain.
- Confirmed the expected failure response for invalid DNSSEC data.
- Performed a controlled AdGuard Home service restart.
- Verified DNS resolution and filtering after the restart.
- Confirmed Windows Ethernet was configured to use the Raspberry Pi as its IPv4 DNS server.
- Demonstrated default DNS resolution without manually specifying the server.
- Captured seven screenshots documenting the actual results.

---

#### Evidence Limitations

These tests validate specific observed behaviors within the home lab environment.

They do not independently prove:

- That every application on Windows uses the Raspberry Pi for all DNS requests.
- That IPv6 DNS configuration cannot provide an alternative resolver.
- That DNS-over-HTTPS or other encrypted DNS mechanisms cannot bypass local filtering.
- That all advertising, tracking, or malicious domains are blocked.
- That the DNS server remains available during a Raspberry Pi hardware failure.
- That service recovery occurs automatically after an unexpected crash or power loss.
- That every DNS query is recursively resolved through Unbound.

The controlled restart and subsequent queries demonstrate successful recovery from that particular restart, not a full high-availability or disaster-recovery test.

---

#### Phase 9 Conclusion

Phase 9 successfully validated the DNS server's primary functionality and several important security behaviors.

The results demonstrated that my Raspberry Pi could provide DNS resolution to a Windows client, block the tested advertising domain, return the expected failure for invalid DNSSEC data, recover after a controlled AdGuard Home restart, and serve as the configured IPv4 DNS server for Windows.

Together with the previous installation, networking, DNSSEC, and system-hardening phases, these results provide documented evidence of a functioning Raspberry Pi DNS security lab.

**Phase 9 Status: Validation Complete**

**Next Phase: Phase 10 — Monitoring, Logging & Performance Metrics**

---

---

---

[← Project overview](../README.md)
