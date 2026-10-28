# DNS Infrastructure Architecture

```mermaid
flowchart TB
    Devices["Household devices / phones"] --> Orbi["NETGEAR Orbi router<br/>172.16.0.1<br/>DHCP + DNS proxy"]
    Windows["Windows PC<br/>Direct DNS configuration"] --> AG
    Orbi --> AG["AdGuard Home<br/>172.16.0.57:53<br/>Filtering · Query logs · Client policies"]
    AG --> UB["Unbound<br/>127.0.0.1:5335<br/>Recursive DNS · Cache · DNSSEC"]
    UB --> Auth["Root / TLD / Authoritative DNS servers"]
```

**DNS request direction:** clients → AdGuard Home → Unbound → authoritative DNS infrastructure. Replies travel in the reverse direction. Unbound listens on loopback only. The router proxies many household queries, so direct Windows DNS configuration enables more precise client-specific filtering.

[← Project overview](../README.md)
