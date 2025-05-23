# 🚀 UnderHost Monitoring Agent (`uhmonitoring`)

![UnderHost Monitoring Dashboard](https://via.placeholder.com/800x400?text=UnderHost+Monitoring+Dashboard)

## Enterprise-Grade Server Monitoring Solution

`uhmonitoring` is a lightweight Python agent that integrates with [Uptime Kuma](https://github.com/louislam/uptime-kuma) to provide comprehensive server monitoring. Part of the [UnderHost Dedicated Server Toolkit](https://underhost.com/servers.php).

---

## 🌟 Key Features

### Real-Time Monitoring
- CPU, RAM, and Disk utilization
- Network bandwidth (in/out)
- System load averages

### Seamless Integration
- Automatic Uptime Kuma push monitor creation
- Embedded visualization in status pages
- Custom alert thresholds

### Beautiful Visualization
- Interactive dashboard with historical data
- Static thumbnails for Uptime Kuma
- Mobile-responsive design

---

## ⚡ Quick Installation

### Prerequisites
- Uptime Kuma instance ([self-hosted](https://github.com/louislam/uptime-kuma) or [UnderHost Managed](https://monitor.underhost.com))
- API Key with monitor creation permissions

### Installation Options

**For UnderHost Customers:**
```
wget -qO- https://monitor.underhost.com/install | bash
```

**Manual Installation:**
```
wget https://github.com/UnderHost/uhmonitoring/releases/latest/download/install.sh
chmod +x install.sh
sudo ./install.sh --api-key YOUR_API_KEY
```

---

## 📊 Metrics Collected

| Metric            | Description                     | Alert Threshold |
|-------------------|---------------------------------|-----------------|
| CPU Usage         | Total CPU utilization           | >90% for 5m     |
| Memory Usage      | RAM consumption                 | >85%            |
| Disk Usage        | Root partition space            | >90%            |
| Network Bandwidth | Data sent/received (MB)         | Customizable    |
| Load Average      | System load (1m, 5m, 15m)       | >CPU cores × 2  |

---

## 🔗 Uptime Kuma Integration

1. **Auto-Created Push Monitor**

2. **Smart Alerting**
   - Configurable thresholds
   - Multiple notification methods
   - Auto-remediation options

---

## 🖥️ Dashboard Access

**Web Interface:**
```
https://monitor.underhost.com/status/YOUR_SERVER_IP
```

**CustomerPanel Integration:**
Available under *Server → Monitoring* in your [CustomerPanel](https://customerpanel.ca)

---

## ❓ Frequently Asked Questions

### How do I get an API Key?
1. Log in to [CustomerPanel](https://customerpanel.ca)
2. Navigate to *Settings → API Keys*
3. Generate key with "Monitor" permissions

### Can I monitor multiple servers?
Yes! Each server maintains:
- Isolated push monitor
- Dedicated dashboard
- Independent alert rules

### How often are metrics collected?
- Default: 60-second intervals
- Configurable in `/opt/uhmonitoring/config.yaml`

---

## 🛡️ Security Features

- **Encrypted communications** (TLS 1.2+)
- **Least privilege access**
- **Systemd sandboxing**
- **Regular security updates**

---

## 📞 Support

**Managed Clients:**
- 24/7 Ticket Support via [CustomerPanel](https://customerpanel.ca/)

**Community Users:**
- [GitHub Issues](https://github.com/UnderHost/uhmonitoring/issues)
- Documentation: [docs.underhost.com](https://docs.underhost.com)

---

## 📜 License

GNU GPLv3 © 2023-2025 UnderHost.com  
*Free for personal and commercial use*
