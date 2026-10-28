# Phase 5 — Network-Wide DNS Integration

#### Objective

Extend AdGuard Home beyond DNS requests made on the Raspberry Pi itself. In this phase, I configured a Windows PC to use the Raspberry Pi directly and configured the NETGEAR Orbi router to forward DNS requests to AdGuard Home. I then used the AdGuard Home Query Log to examine which clients reached the server and which requests were filtered.

The DNS server was `172.16.0.57` (TCP/UDP port 53), the Orbi gateway was `172.16.0.1`, and the Windows PC was `172.16.0.74` on the `172.16.0.0/24` private LAN.

#### 1. Verify DNS connectivity from Windows

Before changing the client DNS settings, I checked whether Windows could reach the DNS server over TCP port 53:

```powershell
Test-NetConnection 172.16.0.57 -Port 53
```

The original lab recorded `TcpTestSucceeded : True`. This verifies a TCP connection to port 53, not DNS resolution over UDP. **The four recovered Phase 5 screenshots do not show this PowerShell output**, so I have not assigned a Query Log image to this step.

#### 2. Configure Windows to use AdGuard Home

On the Windows PC, I opened **Settings → Network & Internet → Ethernet → DNS Server Assignment → Edit**, selected manual IPv4 configuration, set the preferred DNS server to `172.16.0.57`, left the alternate DNS server blank, and disabled DNS over HTTPS for this connection.

I checked the assigned DNS server and performed a default-server lookup:

```powershell
Get-DnsClientServerAddress
nslookup github.com
```

The original lab recorded that the Windows client used `172.16.0.57` for the lookup. The recovered Query Log independently shows queries originating from the Windows client at `172.16.0.74`.

![Windows client DNS requests processed by AdGuard Home](screenshots/phase-5-01-windows-dns-query-log.png)

*Figure 1 — AdGuard Home processed `example.com` A/AAAA requests attributed to Windows client `172.16.0.74`. This demonstrates client DNS activity, not the PowerShell connectivity test.*

#### 3. Confirm DNS filtering on the Windows client

I inspected the AdGuard Home Query Log after the Windows DNS change. It recorded both permitted requests and requests blocked by AdGuard's DNS filter for `172.16.0.74`.

![Windows DNS filtering in AdGuard Home](screenshots/phase-5-02-windows-dns-filtering.png)

*Figure 2 — Windows client `172.16.0.74` has processed requests and blocked NVIDIA telemetry requests. This demonstrates that filtering was active for this client.*

These log entries demonstrate filtering decisions for the recorded requests. They do not prove that every application on Windows always uses the system DNS settings.

#### 4. Configure NETGEAR Orbi DNS forwarding

The router's LAN DHCP settings did not expose the custom DNS distribution option needed for this setup. I instead configured the router's **Internet Setup** DNS setting to use `172.16.0.57`.

At this stage, AdGuard Home forwarded permitted requests to the configured Quad9 DNS-over-HTTPS upstream. Unbound was added later in Phase 7.

```text
Household devices
       |
       v
NETGEAR Orbi DNS proxy (172.16.0.1)
       |
       v
AdGuard Home (172.16.0.57:53)
       |
       v
Quad9 upstream resolver (at this stage)
```

#### 5. Verify router-forwarded household DNS traffic

The AdGuard Home Query Log recorded processed and blocked requests attributed to `172.16.0.1`, the Orbi router. The domains included requests associated with multiple services, such as Apple and TikTok.

![DNS queries forwarded through the Orbi router](screenshots/phase-5-03-orbi-forwarded-dns-queries.png)

*Figure 3 — The Query Log shows permitted and blocked requests attributed to router address `172.16.0.1`, consistent with Orbi DNS forwarding.*

![Additional filtering of router-forwarded queries](screenshots/phase-5-04-orbi-dns-filtering.png)

*Figure 4 — Additional queries attributed to `172.16.0.1` include blocked advertising and analytics domains and permitted application requests. This is supplementary filtering evidence, **not a reboot-persistence test**.*

**Client attribution limitation:** When the Orbi forwards DNS on behalf of household devices, AdGuard Home often records the router IP rather than the original device IP. The Windows PC, which was configured directly, appeared as `172.16.0.74`. Therefore, the router-proxied logs demonstrate DNS activity through the router, but they do not reliably identify each individual household device.

#### Challenges and solutions

- **Client adoption:** A working DNS server does not mean clients use it automatically. I set the Windows preferred DNS address to the Raspberry Pi and verified client activity in the Query Log.
- **Router configuration:** Because the desired custom DNS setting was unavailable in Orbi's LAN DHCP options, I used the router's Internet Setup DNS configuration.
- **Client identification:** Orbi DNS proxying grouped many requests under `172.16.0.1`. Directly configuring a client, as with Windows, allowed AdGuard Home to identify that client separately.

#### Outcome

The recorded lab tests and recovered Query Logs support these Phase 5 results:

- Windows client `172.16.0.74` sent DNS requests to AdGuard Home.
- AdGuard Home processed and blocked selected Windows client requests.
- The Orbi router `172.16.0.1` forwarded DNS requests to AdGuard Home.
- AdGuard Home processed and blocked selected router-forwarded requests.
- Router DNS proxying limited per-device attribution, which informed the client-specific filtering work in Phase 6.

#### Evidence limitations

The four recovered images are all AdGuard Home Query Logs. They do **not** display `Test-NetConnection`, `Get-DnsClientServerAddress`, `nslookup`, router DNS settings, or a reboot/reconnect sequence. The commands and configuration steps above are retained from the original project record, but the screenshots must not be captioned as proof of those separate actions. Reboot persistence is not established by this Phase 5 image set.

The images contain private LAN IP addresses, a Windows hostname, router-associated hostname labels, and requested domain names. They do not visibly expose administrator passwords, private SSH keys, or public WAN addresses. Review the domain history and device names before publishing if you want to keep household activity private.

**Phase 5 Status: Complete — with screenshot evidence limited as described above.**

---

---

---

[← Project overview](../README.md)
