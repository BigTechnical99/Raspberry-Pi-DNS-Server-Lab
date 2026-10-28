# Phase 6 — Client-Specific DNS Filtering & Family Protection

#### Objective

The objective of this phase was to configure client-specific DNS security policies using AdGuard Home and validate that different devices could receive different filtering behavior.

During Phase 5, I successfully integrated my Raspberry Pi DNS server with a Windows client and the NETGEAR Orbi router.

However, the Orbi router acted as a DNS proxy, forwarding DNS requests under its own IP address (`172.16.0.1`). This limited AdGuard Home's ability to identify individual household devices.

To address this limitation, I configured my Windows PC as a persistent client in AdGuard Home and enabled custom security policies, including DNS filtering, browsing security, parental controls, and Safe Search.

I then validated the policies using controlled DNS queries and AdGuard Home's Query Log.

---

#### Step 1 — Configure a Persistent Windows Client

I opened the AdGuard Home administration interface and navigated to:

**Settings → Client settings**

Under **Persistent clients**, I configured the following client:

| Setting | Value |
|---|---|
| Client name | `Windows-PC` |
| Client identifier | `172.16.0.74` |
| Client settings | Custom |
| Blocked services | Global |
| Upstream DNS servers | Global |

This configuration allowed AdGuard Home to associate DNS requests from `172.16.0.74` with the Windows PC and apply custom client-specific protection settings.

The client overview also displayed its accumulated DNS request count, confirming that AdGuard Home was tracking activity associated with the persistent client.

![Persistent Windows client configuration](screenshots/phase-6-01-persistent-client-configuration.png)

*Figure 1 — AdGuard Home Persistent Clients page showing Windows-PC configured with a custom client policy.*

---

#### Step 2 — Configure Client-Specific Security Settings

I opened the Windows-PC client configuration and reviewed the available protection settings.

I disabled **Use global settings**, allowing the Windows PC to use its own protection configuration rather than inheriting all global settings.

The following security features were enabled:

- Block domains using filters and hosts files
- Use AdGuard browsing security web service
- Use AdGuard parental control web service
- Use Safe Search

Safe Search was enabled for the following supported services:

- Bing
- DuckDuckGo
- Ecosia
- Google
- Pixabay
- Yandex
- YouTube

The options to ignore the client in the Query Log and statistics were disabled, allowing DNS requests from Windows-PC to remain visible for monitoring and troubleshooting.

The client continued using the global blocked-service configuration and global upstream DNS settings, as indicated in the persistent-client overview.

![Windows client security settings](screenshots/phase-6-02-client-security-settings.png)

*Figure 2 — Custom DNS filtering, browsing security, parental controls, and Safe Search settings configured for Windows-PC.*

---

#### Step 3 — Validate Client-Specific DNS Filtering

To verify that custom filtering policies could affect the Windows PC independently, I tested DNS queries for:

`example.org`

I reviewed the resulting requests in AdGuard Home's Query Log.

The log showed the following behavior:

| Client | IP Address | DNS Response |
|---|---|---|
| Windows-PC | `172.16.0.74` | Blocked — Custom filtering rules |
| Orbi router | `172.16.0.1` | Processed |

For the Windows PC, both A and AAAA requests were blocked by custom filtering rules.

Meanwhile, requests associated with the Orbi router were processed.

The log also retained earlier requests from Windows-PC that had been processed before the blocked results.

This demonstrated that AdGuard Home could apply different DNS filtering outcomes based on the identified client.

![Client-specific DNS policy validation](screenshots/phase-6-03-client-specific-policy-validation.png)

*Figure 3 — Query Log showing example.org blocked for Windows-PC while requests from the Orbi router were processed.*

**Result:** The observed DNS responses demonstrated successful client-specific filtering behavior.

---

#### Step 4 — Validate Safe Search Enforcement

Next, I tested AdGuard Home's Safe Search handling using Google DNS requests.

I filtered the Query Log for:

`www.google.com`

The results showed:

| Client | IP Address | Response |
|---|---|---|
| Windows-PC | `172.16.0.74` | Safe Search |
| Orbi router | `172.16.0.1` | Processed |

The Windows PC's Google A and AAAA DNS requests were labeled **Safe Search**.

Requests associated with the Orbi router were processed normally.

This provided evidence that AdGuard Home was applying Safe Search DNS handling to the Windows client while treating router-forwarded requests differently.

![Safe Search validation](screenshots/phase-6-04-safe-search-validation.png)

*Figure 4 — Query Log showing Safe Search responses for Windows-PC and normal processed responses for the Orbi router.*

**Evidence limitation:** The Query Log confirms AdGuard Home's Safe Search DNS handling. It does not independently demonstrate the resulting search engine settings or browser-level content filtering.

---

#### Step 5 — Validate Client-Specific Service Blocking

To test application and service blocking, I reviewed DNS requests associated with Amazon.

The Query Log showed requests for:

`www.amazon.com`

For the Windows PC, AdGuard Home returned:

**Blocked service — Amazon**

The log recorded blocked A and HTTPS DNS queries for the Windows client.

An Amazon-related hostname requested through the Orbi router was processed.

| Client | Requested Domain | Result |
|---|---|---|
| Windows-PC (`172.16.0.74`) | `www.amazon.com` | Blocked service — Amazon |
| Orbi router (`172.16.0.1`) | `unagi-na.amazon.com` | Processed |

This demonstrated that AdGuard Home's service-blocking feature was active for the Windows PC.

However, because the two clients requested different Amazon-related domains, the screenshot does not independently prove how both clients would have handled the exact same domain.

![Client-specific service blocking](screenshots/phase-6-05-client-service-blocking-validation.png)

*Figure 5 — AdGuard Home Query Log showing Amazon service blocking for Windows-PC and a processed Amazon-related request from the Orbi router.*

**Result:** The Windows client received the expected blocked-service DNS responses.

---

#### Challenges & Solutions

##### Challenge 1 — Router DNS Proxy Limited Individual Client Identification

**Problem:**

The NETGEAR Orbi router forwarded household DNS queries using its own address, `172.16.0.1`.

As a result, AdGuard Home could not reliably distinguish every individual device behind the router.

**Solution:**

I configured the Windows PC to communicate directly with AdGuard Home and registered it as a persistent client using `172.16.0.74`.

This allowed custom policies to be associated with that client.

##### Challenge 2 — Applying Different DNS Policies to Different Clients

**Problem:**

Global filtering policies are not sufficient when individual devices require different security restrictions.

**Solution:**

I disabled global protection settings for the Windows persistent client and enabled custom security controls.

I then compared Query Log responses from Windows-PC and the Orbi router.

The results showed different filtering outcomes for `example.org` and Google Safe Search requests.

##### Challenge 3 — Verifying Filtering Without Relying Only on Configuration Screenshots

**Problem:**

An enabled checkbox does not independently prove that DNS filtering is working.

**Solution:**

I used AdGuard Home's Query Log to validate actual DNS responses.

The screenshots demonstrated:

- Custom filtering rules blocking `example.org`
- Safe Search handling for `www.google.com`
- Amazon service blocking for the Windows PC
- Processed requests associated with the Orbi router

This provided evidence of both configured security policies and observed DNS behavior.

---

#### Phase 6 Results

By the end of Phase 6, I had successfully:

- Configured a persistent Windows client in AdGuard Home.
- Assigned a recognizable client name and LAN IP identifier.
- Enabled custom DNS protection settings.
- Enabled browsing security and parental control services.
- Enabled Safe Search for seven supported services.
- Verified custom filtering rules using `example.org`.
- Verified Safe Search DNS handling using Google requests.
- Verified Amazon service blocking for Windows-PC.
- Compared direct-client and router-forwarded DNS behavior.
- Documented the limitations introduced by the Orbi DNS proxy.

##### Evidence Summary

| Screenshot | Verified Evidence |
|---|---|
| 01 | Persistent Windows client registration |
| 02 | Custom security and Safe Search configuration |
| 03 | Client-specific DNS filtering |
| 04 | Safe Search DNS handling |
| 05 | Amazon service blocking |

##### Evidence Limitations

The screenshots demonstrate AdGuard Home configuration and recorded DNS filtering behavior.

They do not independently verify that every household device received an individually assigned policy, that Safe Search restricted browser-visible results, or that every Amazon-related domain was blocked.

The Orbi DNS proxy continued to limit individual identification of devices whose requests were forwarded through the router.

**Phase 6 Status: Complete**

---

---

---

[← Project overview](../README.md)
