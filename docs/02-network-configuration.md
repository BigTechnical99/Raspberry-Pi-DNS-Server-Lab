# Phase 3 — Network Configuration and DHCP Reservation

#### Objective

Give the Raspberry Pi DNS server a consistent address and confirm reliable wired connectivity before deploying AdGuard Home.

#### Network configuration

| Setting | Value |
| --- | --- |
| Hostname | DNS-SERVER |
| Wired interface | eth0 |
| Reserved IPv4 address | 172.16.0.57 |
| Subnet | 172.16.0.0/24 |
| Default gateway | 172.16.0.1 |
| Router | Netgear Orbi |

These are private LAN addresses. They describe this lab and should not be copied into a different network without checking its configuration.

#### 1. Identify the Ethernet interface

I checked the wired interface and its assigned IPv4 address:

```bash
ip link show eth0
ip -4 addr show eth0
```

The recovered output shows eth0 in the UP state with address 172.16.0.57/24. The Ethernet hardware address was used to identify the correct adapter for the router reservation; it has been hidden in the published screenshot.

![Ethernet interface validation](screenshots/phase-3-03-ethernet-interface-validation.png)

#### 2. Reserve the address in Orbi

I created a DHCP address reservation in the Orbi router for the Pi's Ethernet adapter, assigning 172.16.0.57.

A DHCP reservation tells the router to keep assigning the same address to that adapter. The Pi still obtains its network settings through DHCP; this is different from configuring a static address directly on the Pi. A consistent address allows clients to keep using the Pi as their DNS server.

The recovered Orbi Address Reservation table shows DNS-SERVER reserved at 172.16.0.57. The published image is cropped to this table, with the MAC address masked.

![Orbi DHCP address reservation](screenshots/phase-3-04-router-dhcp-reservation.png)

#### 3. Reboot and verify SSH access

After saving the reservation, I rebooted the Pi and reconnected using its reserved address:

```bash
sudo reboot
```

From the client computer:

```text
ssh <your-pi-username>@172.16.0.57
```

The original screenshot shows the reboot disconnect followed by a successful SSH login to 172.16.0.57. The username, local client path and SSH host fingerprint are redacted. The placeholder above is documentation, not a replacement for original command output.

![Reboot and SSH validation](screenshots/phase-3-02-reboot-ssh-validation.png)

#### 4. Verify the assigned address, route and internet access

```bash
ip -4 addr show eth0
ip route
ping -c 4 8.8.8.8
```

The recovered output shows:

- Ethernet address: 172.16.0.57/24.
- Ethernet default gateway: 172.16.0.1, with route metric 100.
- Wi-Fi was still active at capture time, using 172.16.0.58 and default-route metric 600.
- The Ethernet route had the lower metric and was preferred.
- All four internet ping requests received replies, with 0% packet loss.

![Address, route and connectivity validation](screenshots/phase-3-01-dhcp-reservation-validation.png)

The established filename is retained. This screenshot supports address, routing and connectivity validation; it does not display the router reservation itself.

#### 5. Use Ethernet for the DNS server

Later in the project, I disabled Wi-Fi so the server used its wired connection:

```bash
sudo nmcli radio wifi off
```

The recovered Ethernet-only screenshot confirms `nmcli radio wifi` returned `disabled`, `eth0` was connected, and `wlan0` was unavailable.

![Ethernet-only and domain connectivity validation](screenshots/phase-3-05-ethernet-only-network-validation.png)

The same screenshot records the domain-name connectivity check:

```bash
ping -c 4 google.com
```

The domain resolved to an IPv4 address and all four ping requests received replies, with 0% packet loss.

#### Outcome

The recovered evidence shows the Orbi reservation for 172.16.0.57, successful SSH access at that address after reboot, Ethernet interface and routing validation, and later Ethernet-only operation with successful domain-name connectivity. The earlier routing screenshot still shows Wi-Fi active; the later validation confirms it was disabled.

#### Screenshot inventory and evidence status

| Filename | Evidence |
| --- | --- |
| phase-3-01-dhcp-reservation-validation.png | Assigned Ethernet address, preferred route, internet ping |
| phase-3-02-reboot-ssh-validation.png | Reboot and subsequent successful SSH login |
| phase-3-03-ethernet-interface-validation.png | Ethernet link UP and assigned IPv4 address; retained from the original ZIP |
| phase-3-04-router-dhcp-reservation.png | Orbi Address Reservation table |
| phase-3-05-ethernet-only-network-validation.png | Wi-Fi disabled, Ethernet connected, successful domain ping |

Both previously listed Phase 3 screenshot gaps have been filled by recovered uploads. No screenshots were fabricated. The uploaded Ethernet-only image originally used number 02; its published filename is number 05 to preserve the original ZIP's existing 02 reboot image and prevent collisions. Unredacted originals and the redundant connected-device list are not included.

---

[← Project overview](../README.md)
