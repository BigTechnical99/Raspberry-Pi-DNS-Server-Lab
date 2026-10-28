# Phase 4 — AdGuard Home Installation and Configuration

#### Objective

Deploy AdGuard Home on the Raspberry Pi, bind its services to Ethernet, and verify DNS resolution and controlled filtering.

#### Lab settings

| Setting | Value |
| --- | --- |
| Host | DNS-SERVER, Raspberry Pi 4 |
| Ethernet interface | eth0 |
| Reserved address | 172.16.0.57 |
| Installation directory | /opt/AdGuardHome |
| Version recorded during setup | v0.107.79 |
| Initial setup URL | http://172.16.0.57:3000 |
| Configured admin URL | http://172.16.0.57/ |
| DNS service | UDP and TCP port 53 |

This document records the existing lab. Commands below describe validation steps; they are not newly executed test results.

#### 1. Install AdGuard Home

I used the AdGuard Home installation script for the Raspberry Pi's ARM64 environment. The project conversation records installation in /opt/AdGuardHome, automatic service startup and the initial setup address http://172.16.0.57:3000.

The recovered installer output confirms successful installation, that the service was running, and that it was configured to start automatically on boot. It also displays the initial setup URL. The exact installation command is not visible in this screenshot and is not reconstructed here.

![AdGuard Home installation](screenshots/phase-4-01-adguard-installation.png)

#### 2. Configure web and DNS interfaces

In the setup wizard, I selected the Ethernet interface for both services:

- Admin Web Interface: eth0 / 172.16.0.57, port 80.
- DNS server: eth0 / 172.16.0.57, port 53.

The web interface moved from the initial setup port 3000 to the configured HTTP port 80. The DHCP reservation documented in Phase 3 provides the consistent address needed by clients.

![Web and DNS interface settings](screenshots/phase-4-06-web-dns-interface-settings.png)

This screenshot shows the wizard settings before completion. The later socket output confirms the running services were bound to 172.16.0.57.

An administrator account was configured during setup. Credentials are intentionally excluded; the account-creation screen was not recovered.

#### 3. Validate the running service and listening ports

From the installation directory, the service status can be checked with:

```bash
cd /opt/AdGuardHome
sudo ./AdGuardHome -s status
```

I checked listening sockets and queried the DNS server directly:

```bash
sudo ss -tulpn | grep -E ':53 |:80 '
nslookup example.com 172.16.0.57
```

The recovered terminal screenshot shows:

- AdGuard Home service status: running.
- UDP 172.16.0.57:53 and TCP 172.16.0.57:53 owned by AdGuardHome.
- An example.com response containing IPv4 and IPv6 answers from DNS server 172.16.0.57.

![DNS service and resolution validation](screenshots/phase-4-02-dns-service-validation.png)

During the original work, nslookup was initially unavailable; dnsutils was installed before the lookup tests. The screenshot above shows the later successful lookup, not the package-install step. Resolved website addresses are historical and can change.

#### 4. Confirm requests in the Query Log

I opened the AdGuard Home Query Log to verify that the server recorded the test requests. The recovered image shows example.com A and AAAA requests marked Processed, with the client identified as DNS-SERVER at 172.16.0.57.

![Processed test queries](screenshots/phase-4-03-adguard-query-log.png)

These requests came from the Pi itself. This proves local direct-query processing; it does not establish that every household device was using AdGuard Home.

#### 5. Validate filtering with a controlled test

I used example.org for a controlled blocking test. The recovered Query Log shows its A and AAAA requests marked Blocked by Custom filtering rules, alongside processed example.com requests.

![Controlled DNS filtering test](screenshots/phase-4-04-dns-filtering-validation.png)

This demonstrates the custom rule was applied to the test domain. It is not evidence that example.org is malicious, or a benchmark of general ad blocking. The exact custom-rule text and the corresponding terminal blocked response were not recovered in this image set.

#### 6. Additional service-health validation

A later validation screenshot shows AdGuard Home running, DNS listening on UDP/TCP 172.16.0.57:53, and the web interface listening on TCP 172.16.0.57:80. A direct example.com lookup succeeds, eth0 is connected, and wlan0 is unavailable.

![Additional service-health validation](screenshots/phase-4-05-reboot-persistence-validation.png)

The original filename is retained for consistency. This image does not show a reboot sequence or uptime, so it confirms service health but does not independently prove persistence across reboot. The installer message confirms automatic startup was configured; it does not by itself verify a successful restart after reboot.

#### Outcome

The six recovered screenshots document successful installation, Ethernet-bound web and DNS settings, a running AdGuard Home service, UDP/TCP DNS listeners, successful direct DNS resolution, query logging, controlled filtering and a later service-health check.

The test queries shown came from the Pi itself. They do not establish that every household device was using AdGuard Home; client configuration and testing are documented separately.

#### Evidence limitations

All six screenshot files are available. The reboot and reconnect sequence itself is not shown, so reboot persistence remains unverified by these images alone. Administrator-account creation, the dnsutils package installation and the exact custom-filter rule text are not pictured. No images or command output were fabricated to fill these gaps.

Usernames are redacted in the published terminal images. The installer image retains its existing redaction. Private LAN addresses, generic hostnames and public test domains remain visible to explain the lab.
---

---

[← Project overview](../README.md)
