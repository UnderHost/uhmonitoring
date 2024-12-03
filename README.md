# UnderHost Monitoring Agent (`uhmonitoring`)

`uhmonitoring` is a lightweight monitoring agent that integrates with [Uptime Kuma](https://github.com/louislam/uptime-kuma). It collects server metrics like CPU, RAM, Disk, Load Average, and Network Bandwidth, pushes them to Uptime Kuma, and provides a visualization dashboard for detailed metrics.

## Features
- Automatic integration with Uptime Kuma:
  - Dynamically creates a **Push Monitor**.
  - Adds a **Status Page** with server-specific visualization links.
- Collects server metrics:
  - **CPU Usage**
  - **RAM Usage**
  - **Disk Usage**
  - **Load Average**
  - **Network Bandwidth (Sent/Received)**
- Visualization dashboard:
  - Interactive, real-time charts hosted on the server.
  - Static metric thumbnail embedded into Uptime Kuma's monitor description.

---

## Installation

### Prerequisites
- A running instance of Uptime Kuma.
- An **API Key** from Uptime Kuma for monitor creation.

### One-Click Installer
To install and start monitoring, click "start" monitoring on your @CustomerPanel managed server page.


---

## How It Works
1. **Agent Installation**:
   - The script installs all necessary dependencies (`python3`, `psutil`, `flask`, etc.).
   - Sets up a monitoring agent that collects metrics every minute.
2. **Uptime Kuma Integration**:
   - A new **Push Monitor** is automatically created in Uptime Kuma using the provided API Key.
   - The visualization dashboard link is embedded into the monitor description in Markdown format.
3. **Visualization Dashboard**:
   - Hosted locally on the monitored server at `https://monitor.underhost.com/status/<SERVER_IP>`.
   - Displays interactive charts for all metrics (updated in real-time).
   - Generates static thumbnails for embedding in Uptime Kuma.

---

## Metrics Collected
- **CPU Usage**: Real-time CPU utilization percentage.
- **Memory Usage**: Percentage of RAM in use.
- **Disk Usage**: Percentage of disk space in use.
- **Load Average**: System load averages (1m, 5m, 15m).
- **Network Bandwidth**:
  - Total data sent (MB).
  - Total data received (MB).

---

## Uptime Kuma Integration
1. **Push Monitor**:
   - Automatically created in Uptime Kuma.
   - Updates with `up` or `down` status based on server health (set to open a ticket or send reboot command on `down` or do nothing)
2. **Markdown Description**:
   - Includes a link to the real-time dashboard and a static thumbnail preview:
     ```
     ### Server Metrics
     ![Metrics Thumbnail](https://monitor.underhost.com/status/<SERVER_IP>/thumbnail.png)
     [View Full Dashboard](https://monitor.underhost.com/status/<SERVER_IP>)
     ```

---

## Visualization Dashboard
- Hosted on the server, accessible using your @CustomerPanel user/pass login at:
  ```
  https://monitor.underhost.com/status/<SERVER_IP>
  ```
- Provides interactive, real-time charts for:
  - CPU Usage
  - Memory Usage
  - Disk Usage
  - Network Bandwidth (IN/OUT)

---

## Requirements
- **Python 3.x**
- **Uptime Kuma API Key**

---

## FAQ

### How do I get the Uptime Kuma API Key?
1. Log in to our @CustomerPanel and select your Server.
2. Navigate to **Settings → API Keys**.
3. Generate a new API Key and use it during the installation.

### Can I reuse the same Push Monitor for multiple servers?
No, each server creates its own unique Push Monitor to ensure metrics are isolated and easily traceable.

### How do I access the visualization dashboard?
Visit:
```
https://monitor.underhost.com/status/<SERVER_IP>
```
Replace `<SERVER_IP>` with the server's actual IP address.

---

## Support
For any issues, please contact **UnderHost Support** or open a ticket via [CustomerPanel](https://customerpanel.ca/client/clientarea.php).

---

## License
This project is licensed under the **MIT License**. Feel free to use, modify, and distribute.
