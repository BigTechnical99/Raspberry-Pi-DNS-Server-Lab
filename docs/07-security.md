# Phase 8 — SSH Hardening & System Security

#### Objective

In this phase, I validated the Raspberry Pi DNS server's remote-access controls, host firewall, automatic update configuration, and essential service health. The goal was to reduce unnecessary access while keeping SSH administration, AdGuard Home DNS filtering, and Unbound DNS resolution operational.

This section documents **observed lab results**, not assumed settings. All screenshots are from the actual Raspberry Pi environment.

---

#### Step 1 — Validate SSH Server Hardening

After successfully connecting to the Raspberry Pi with an existing Ed25519 SSH key, I inspected the effective SSH daemon settings:

```bash
sudo sshd -T | grep -Ei '^(pubkeyauthentication|passwordauthentication|permitrootlogin|kbdinteractiveauthentication|authenticationmethods) '
```

The server returned:

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
authenticationmethods any
```

| Setting | Observed value | Security significance |
|---|---|---|
| `permitrootlogin` | `no` | Direct SSH login as root is disabled |
| `pubkeyauthentication` | `yes` | Public-key authentication is enabled |
| `passwordauthentication` | `no` | SSH password authentication is disabled |
| `kbdinteractiveauthentication` | `no` | Keyboard-interactive SSH authentication is disabled |
| `authenticationmethods` | `any` | Any permitted, enabled authentication method may satisfy login; this does **not** allow anonymous access |

An earlier SSH attempt without explicitly selecting the custom key returned `Permission denied (publickey)`. Using the existing private key with `ssh -i` successfully authenticated. This supports that the server accepted the authorized key, while the effective settings independently establish the password-login restrictions.

![SSH hardening validation](screenshots/phase-8-01-ssh-hardening-validation.png)

*Figure 1 — Effective SSH settings show public-key authentication enabled and password, keyboard-interactive, and root SSH logins disabled.*

---

#### Step 2 — Inspect UFW Firewall Rules

I checked the active firewall configuration:

```bash
sudo ufw status verbose
```

Observed policies:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
```

The firewall displayed these inbound allow rules:

| Destination | Protocol | Allowed source | Purpose |
|---|---|---|---|
| `172.16.0.57:53` | UDP | `172.16.0.0/24` | AdGuard Home DNS |
| `172.16.0.57:53` | TCP | `172.16.0.0/24` | AdGuard Home DNS |
| `172.16.0.57:80` | TCP | `172.16.0.0/24` | AdGuard Home web interface |
| Port `22` | TCP | `172.16.0.0/24` | SSH administration |

The default-deny incoming policy reduces exposure by allowing only explicitly permitted traffic. Both TCP and UDP DNS are allowed for LAN clients. SSH and the web administration interface are also limited by source subnet, although devices on that subnet may still attempt to connect.

![UFW firewall status](screenshots/phase-8-02-ufw-firewall-status.png)

*Figure 2 — UFW active with default-deny incoming policy and LAN-scoped DNS, web, and SSH rules.*

**Scope:** These rules demonstrate host-firewall configuration. They do not prove the absence of router port forwarding, and the screenshot is not a packet-level firewall enforcement test.

---

#### Step 3 — Verify the Unattended-Upgrades Service

I inspected the service:

```bash
sudo systemctl status unattended-upgrades --no-pager
```

The service was **loaded**, **enabled**, and **active (running)**. Its systemd description was **Unattended Upgrades Shutdown**.

![Unattended-upgrades service status](screenshots/phase-8-03-automatic-updates-validation.png)

*Figure 3 — Unattended Upgrades Shutdown service is enabled and running.*

This service status alone does not establish that automatic package installations are scheduled or have succeeded. I verified those points separately.

---

#### Step 4 — Verify Automatic Update Scheduling

I inspected the APT periodic configuration:

```bash
sudo grep -RhsE '^[[:space:]]*APT::Periodic::(Update-Package-Lists|Unattended-Upgrade)' /etc/apt/apt.conf /etc/apt/apt.conf.d/ 2>/dev/null
```

Observed output:

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

These directives configure periodic package-list updates and unattended upgrades with a daily interval. They do not guarantee that an eligible package will be available on every run.

![Automatic update schedule](screenshots/phase-8-04-automatic-update-schedule.png)

*Figure 4 — APT periodic settings specify daily package-list refresh and unattended upgrades.*

---

#### Step 5 — Review Automatic Upgrade History

I checked the unattended-upgrades log:

```bash
sudo tail -n 35 /var/log/unattended-upgrades/unattended-upgrades.log
```

The log showed permitted Debian `trixie` and `trixie-security` package origins and recorded the following events:

| Date | Observed event | Result |
|---|---|---|
| October 24, 2026 | `unbound` selected for upgrade | `All upgrades installed` |
| October 25, 2026 | `libbrotli1` selected for upgrade | `All upgrades installed` |
| October 26, 2026 | Unattended-upgrades run | No eligible packages found; no pending auto-removals |

These entries demonstrate that unattended upgrades actually ran and successfully installed packages, rather than merely being enabled in configuration.

The log also reported that battery-status checks were skipped because `powermgmt-base` was not installed. This message was not presented as an installation failure.

![Unattended-upgrades execution history](screenshots/phase-8-05-unattended-upgrades-history.png)

*Figure 5 — Upgrade logs identify allowed repositories, successful package installations, and a later run with no pending eligible upgrades.*

---

#### Step 6 — Confirm Essential Services Remain Active

Finally, I verified the status of the three services required for remote administration and DNS operation:

```bash
sudo systemctl is-active ssh unbound AdGuardHome
```

Observed output, in the same order as the service names:

```text
active
active
active
```

| Service | Observed status | Role |
|---|---|---|
| `ssh` | `active` | Remote administration |
| `unbound` | `active` | Local DNS resolver |
| `AdGuardHome` | `active` | Client-facing DNS filtering |

![Final security service health](screenshots/phase-8-06-final-security-service-health.png)

*Figure 6 — SSH, Unbound, and AdGuard Home all reported active service states.*

This confirms service activity at the time of testing. It is not a substitute for the DNS resolution and DNSSEC tests documented in Phase 7.

---

#### Challenges & Solutions

##### Securing SSH without losing administrative access

**Challenge:** Disabling SSH password authentication can prevent remote access if the correct key is unavailable.

**Approach:** I used an existing Ed25519 key to establish access and then verified the effective SSH restrictions. The working SSH session was preserved while checking settings.

##### Restricting access while maintaining DNS availability

**Challenge:** A default-deny firewall must still permit necessary DNS and administrative traffic.

**Approach:** The observed UFW rules allowed DNS over TCP and UDP, AdGuard Home's web interface, and SSH from the local subnet. A final service-status check confirmed the core daemons remained active.

##### Distinguishing update configuration from actual update execution

**Challenge:** A running unattended-upgrades service does not independently prove updates are being installed.

**Approach:** I checked the APT periodic settings and the unattended-upgrades log, which recorded successful `unbound` and `libbrotli1` package upgrades.

---

#### Phase 8 Results

- Verified SSH public-key authentication was enabled and SSH password, keyboard-interactive, and root login were disabled.
- Confirmed UFW was active with default-deny incoming traffic and LAN-restricted access to SSH, DNS, and the AdGuard Home web interface.
- Verified the unattended-upgrades shutdown service was running.
- Confirmed APT was configured to run periodic updates daily.
- Verified successful unattended package upgrades from actual logs.
- Confirmed `ssh`, `unbound`, and `AdGuardHome` all reported `active`.
- Captured six original screenshots for the GitHub portfolio.

##### Evidence Limitations

The captured evidence does not establish router-side WAN exposure, packet-level enforcement of each firewall rule, reboot persistence of all services, or the security state of other devices on the LAN. The effective `sshd -T` output represents the default evaluated configuration; connection-specific `Match` directives were not separately tested.

**Phase 8 Status: Validation Complete**

---

---

---

[← Project overview](../README.md)
