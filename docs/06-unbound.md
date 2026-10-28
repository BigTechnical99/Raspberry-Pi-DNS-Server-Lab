# Phase 7 — Unbound Recursive DNS & DNSSEC

#### Objective

In this phase, I verified a local Unbound DNS resolver on my Raspberry Pi, checked its integration with AdGuard Home, and tested DNSSEC validation.

The intended DNS path is:

```text
Windows PC / Household Devices
            |
            v
AdGuard Home — 172.16.0.57:53
            |
            v
Unbound — 127.0.0.1:5335
            |
            v
DNS infrastructure
```

The screenshots establish that Unbound was running and accepting local queries, AdGuard Home was configured to use it as an upstream, and DNSSEC tests produced the expected results.

They do not independently establish whether Unbound uses full recursion rather than forwarding, or prove the exact upstream path taken by every query.

---

#### Step 1 — Verify Unbound Service Health

I connected to the Raspberry Pi using SSH key authentication and checked the service:

```bash
sudo systemctl status unbound --no-pager
```

The service was **loaded**, **enabled**, and **active (running)**.

The log identified Unbound **1.26.2**, with the `validator` and `iterator` modules initialized.

The observed service start was October 24, 2026, at 06:43 EDT.

![Unbound service health](screenshots/phase-7-01-unbound-service-health.png.png)

*Figure 1 — Unbound service running, enabled, and reporting validator/iterator initialization.*

An enabled service is configured to start at boot, but this screenshot alone does not demonstrate a successful restart following a reboot.

---

#### Step 2 — Verify the Local DNS Listener

I checked which interfaces and ports Unbound was listening on:

```bash
sudo ss -tulnp | grep 5335
```

The output showed the `unbound` process listening on **127.0.0.1:5335** over both UDP and TCP.

The observed process ID was `36032`.

This local-only listener separates Unbound from AdGuard Home's client-facing port 53 and avoids exposing Unbound directly on the LAN through this socket.

![Unbound listener validation](screenshots/phase-7-02-unbound-listener-validation.png)

*Figure 2 — TCP and UDP listeners bound to the loopback address on port 5335.*

---

#### Step 3 — Validate the Unbound Configuration

I ran:

```bash
sudo unbound-checkconf
```

The configuration validator returned:

```text
unbound-checkconf: no errors in /etc/unbound/unbound.conf
```

This confirms the configuration passed Unbound's validation check; it does not by itself demonstrate successful DNS queries.

![Unbound configuration validation](screenshots/phase-7-03-unbound-configuration-validation.png.png)

*Figure 3 — Unbound reports no configuration errors.*

---

#### Step 4 — Test Direct DNS Resolution

To test Unbound independently of AdGuard Home, I queried the local resolver:

```bash
dig @127.0.0.1 -p 5335 example.com A
```

Observed results:

| Field | Result |
|---|---|
| Resolver | `127.0.0.1#5335` |
| Status | `NOERROR` |
| Record type | `A` |
| Answers | `172.66.147.243`, `104.20.23.154` |
| Query time | 59 ms |
| Transport | UDP |

The successful response demonstrates that Unbound answered an IPv4 DNS lookup on its configured local port.

![Direct Unbound DNS resolution](screenshots/phase-7-04-unbound-dns-resolution.png)

*Figure 4 — Successful example.com resolution through Unbound at 127.0.0.1:5335.*

---

#### Step 5 — Verify AdGuard Home Upstream Configuration

In **AdGuard Home → Settings → DNS settings**, I inspected the **Upstream DNS servers** field.

The configured upstream was:

```text
127.0.0.1:5335
```

The screenshot showed this as the only listed upstream server, with **Load-balancing** selected as the upstream selection mode.

This establishes that AdGuard Home was configured to send upstream DNS requests to local Unbound.

A configuration screenshot alone does not trace the network path of individual DNS queries.

![AdGuard Home upstream DNS configuration](screenshots/phase-7-05-adguard-unbound-integration.png.png)

*Figure 5 — AdGuard Home configured to use the local Unbound resolver on port 5335.*

---

#### Step 6 — Validate DNSSEC Behavior

I tested a correctly signed domain and a deliberately broken DNSSEC domain directly against Unbound:

```bash
dig @127.0.0.1 -p 5335 cloudflare.com A +dnssec
dig @127.0.0.1 -p 5335 dnssec-failed.org A +dnssec
```

| Test | Observed result |
|---|---|
| `cloudflare.com` | `NOERROR`, two A records and an RRSIG record |
| `dnssec-failed.org` | `SERVFAIL`, zero answers |

The valid signed domain resolved, while the deliberately invalid DNSSEC test domain failed.

Together, these results provide strong evidence of functioning DNSSEC validation.

The positive response did not visibly contain the `ad` flag, so the conclusion relies on the paired positive/negative test behavior rather than claiming that the flag was observed.

![DNSSEC positive and negative validation](screenshots/phase-7-06-dnssec-validation.png.png)

*Figure 6 — Signed-domain resolution succeeds while the deliberately invalid DNSSEC domain returns SERVFAIL.*

---

#### Step 7 — Validate DNS Resolution Through AdGuard Home

Finally, I sent a DNS query to AdGuard Home's LAN-facing DNS service:

```bash
dig @172.16.0.57 example.com A
```

Observed results:

| Field | Result |
|---|---|
| DNS server | `172.16.0.57#53` |
| Status | `NOERROR` |
| Answers | `172.66.147.243`, `104.20.23.154` |
| Query time | 19 ms |
| Transport | UDP |
| Response flags | Included `ad` |

This confirms that AdGuard Home answered the DNS request successfully.

The `ad` flag indicates that the response was marked as authenticated.

Combined with the upstream setting and direct Unbound tests, this supports the intended integration; it does not independently trace every resolver hop.

![End-to-end DNS resolution through AdGuard Home](screenshots/phase-7-07-end-to-end-dns-validation.png.png)

*Figure 7 — Successful DNS resolution through AdGuard Home at 172.16.0.57:53.*

---

#### Challenges & Solutions

##### Separating AdGuard Home and Unbound on the Same Raspberry Pi

**Challenge:** Both services perform DNS-related work, so their listening ports must not conflict.

**Implementation verified:** AdGuard Home served client DNS on port 53, while Unbound listened locally on port 5335.

##### Proving DNSSEC Rather Than Assuming It from Successful Resolution

**Challenge:** A successful DNS lookup alone does not establish DNSSEC validation.

**Solution:** I compared a valid signed domain (`cloudflare.com`) with an intentionally invalid DNSSEC domain (`dnssec-failed.org`).

The expected `NOERROR` and `SERVFAIL` responses were observed.

##### Avoiding Overstatement of Recursive DNS Operation

**Limitation:** The collected evidence confirms Unbound's operation and AdGuard Home's upstream setting, but does not include the Unbound configuration directives or a trace proving whether Unbound performs full recursion instead of forwarding.

**Documentation approach:** Describe full recursion as the intended architecture until the relevant configuration is inspected.

---

#### Phase 7 Results

- Verified that Unbound 1.26.2 was enabled and running.
- Confirmed local UDP and TCP listeners on `127.0.0.1:5335`.
- Validated the Unbound configuration without errors.
- Resolved `example.com` directly through Unbound.
- Confirmed AdGuard Home's upstream setting pointed to local Unbound.
- Observed successful DNSSEC positive and negative test behavior.
- Resolved `example.com` through AdGuard Home at `172.16.0.57:53`.
- Collected seven original screenshots documenting the validation sequence.

##### Evidence Limitations

These screenshots do not independently prove reboot persistence, full iterative recursion rather than forwarding, or the precise upstream path of each DNS query.

No additional configuration files or packet traces were collected as part of this documented validation sequence.

**Phase 7 Status: Validation Complete**

---

---

---

[← Project overview](../README.md)
