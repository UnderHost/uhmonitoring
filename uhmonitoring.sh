#!/bin/bash

# Constants
AGENT_DIR="/opt/uhmonitoring"
AGENT_SCRIPT="uhmonitoring.py"
VISUALIZATION_SERVER="server.py"
DATA_FILE="metrics.json"
VISUALIZATION_HTML="visualization.html"
PUSH_KEY="UH_API_KEY"
KUMA_API_URL="https://monitor.underhost.com"
KUMA_API_KEY="YOUR_UPTIME_KUMA_API_KEY"  # Replace with your API key
SERVICE_NAME="uhmonitoring"
SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')
VISUALIZATION_URL="https://monitor.underhost.com/status/$SERVER_IP"

# Detect package manager
if command -v apt > /dev/null; then
    PKG_MANAGER="apt"
elif command -v yum > /dev/null; then
    PKG_MANAGER="yum"
else
    echo "Unsupported package manager. Please use a system with apt or yum."
    exit 1
fi

# Update and install dependencies
echo "Updating system and installing dependencies..."
if [ "$PKG_MANAGER" = "apt" ]; then
    apt update -y && apt install -y python3 python3-pip wget curl
elif [ "$PKG_MANAGER" = "yum" ]; then
    yum update -y && yum install -y python3 python3-pip wget curl
fi

# Create agent directory
echo "Setting up agent directory..."
mkdir -p $AGENT_DIR

# Write the monitoring script
echo "Creating monitoring script..."
cat << EOF > $AGENT_DIR/$AGENT_SCRIPT
import psutil
import requests
import time
import json
import os

PUSH_KEY = "$PUSH_KEY"
KUMA_API_URL = "$KUMA_API_URL/api/push/" + PUSH_KEY
DATA_FILE = "$AGENT_DIR/$DATA_FILE"
SERVER_NAME = "$SERVER_NAME"
SERVER_IP = "$SERVER_IP"

def get_metrics():
    net_io = psutil.net_io_counters()
    return {
        "cpu_usage": psutil.cpu_percent(interval=1),
        "memory_usage": psutil.virtual_memory().percent,
        "disk_usage": psutil.disk_usage('/').percent,
        "load_avg": psutil.getloadavg(),
        "net_sent": net_io.bytes_sent / 1024 / 1024,  # Convert to MB
        "net_recv": net_io.bytes_recv / 1024 / 1024,  # Convert to MB
        "timestamp": int(time.time())
    }

def send_to_uptime_kuma(metrics):
    status = "up" if metrics["cpu_usage"] < 90 and metrics["memory_usage"] < 85 else "down"
    message = (
        f"CPU: {metrics['cpu_usage']}%, "
        f"RAM: {metrics['memory_usage']}%, "
        f"Disk: {metrics['disk_usage']}%, "
        f"Load: {metrics['load_avg'][0]:.2f}, "
        f"Net Sent: {metrics['net_sent']:.2f} MB, "
        f"Net Received: {metrics['net_recv']:.2f} MB"
    )
    response = requests.post(KUMA_API_URL, json={"status": status, "msg": message})
    print(f"Sent to Uptime Kuma: {response.status_code}, {response.text}")

def save_metrics(metrics):
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'w') as f:
            json.dump([], f)
    with open(DATA_FILE, 'r+') as f:
        data = json.load(f)
        data.append(metrics)
        f.seek(0)
        json.dump(data[-100:], f)  # Keep only the last 100 entries

while True:
    metrics = get_metrics()
    send_to_uptime_kuma(metrics)
    save_metrics(metrics)
    time.sleep(60)
EOF

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install psutil requests flask

# Write the visualization server script
echo "Creating visualization server script..."
cat << EOF > $AGENT_DIR/$VISUALIZATION_SERVER
from flask import Flask, send_from_directory

app = Flask(__name__)

@app.route('/')
def index():
    return send_from_directory('$AGENT_DIR', '$VISUALIZATION_HTML')

@app.route('/metrics.json')
def metrics():
    return send_from_directory('$AGENT_DIR', '$DATA_FILE')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Write the visualization HTML file
echo "Creating visualization HTML file..."
cat << 'EOF' > $AGENT_DIR/$VISUALIZATION_HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <title>Server Metrics</title>
</head>
<body style="font-family: Arial, sans-serif;">
    <h1 style="text-align: center;">Server Metrics</h1>
    <div style="width: 80%; margin: 0 auto;">
        <canvas id="cpuChart"></canvas>
        <canvas id="memoryChart"></canvas>
        <canvas id="diskChart"></canvas>
        <canvas id="netChart"></canvas>
    </div>
    <script>
        async function fetchMetrics() {
            const response = await fetch('/metrics.json');
            return response.json();
        }

        async function renderCharts() {
            const metrics = await fetchMetrics();
            const timestamps = metrics.map(m => new Date(m.timestamp * 1000).toLocaleTimeString());
            const cpuData = metrics.map(m => m.cpu_usage);
            const memoryData = metrics.map(m => m.memory_usage);
            const diskData = metrics.map(m => m.disk_usage);
            const netSentData = metrics.map(m => m.net_sent);
            const netRecvData = metrics.map(m => m.net_recv);

            new Chart(document.getElementById('cpuChart'), {
                type: 'line',
                data: {
                    labels: timestamps,
                    datasets: [{
                        label: 'CPU Usage (%)',
                        data: cpuData,
                        borderColor: 'rgb(75, 192, 192)',
                        fill: false
                    }]
                }
            });

            new Chart(document.getElementById('memoryChart'), {
                type: 'line',
                data: {
                    labels: timestamps,
                    datasets: [{
                        label: 'Memory Usage (%)',
                        data: memoryData,
                        borderColor: 'rgb(153, 102, 255)',
                        fill: false
                    }]
                }
            });

            new Chart(document.getElementById('diskChart'), {
                type: 'line',
                data: {
                    labels: timestamps,
                    datasets: [{
                        label: 'Disk Usage (%)',
                        data: diskData,
                        borderColor: 'rgb(255, 159, 64)',
                        fill: false
                    }]
                }
            });

            new Chart(document.getElementById('netChart'), {
                type: 'line',
                data: {
                    labels: timestamps,
                    datasets: [
                        {
                            label: 'Net Sent (MB)',
                            data: netSentData,
                            borderColor: 'rgb(54, 162, 235)',
                            fill: false
                        },
                        {
                            label: 'Net Received (MB)',
                            data: netRecvData,
                            borderColor: 'rgb(255, 99, 132)',
                            fill: false
                        }
                    ]
                }
            });
        }

        renderCharts();
    </script>
</body>
</html>
EOF

# Create a new monitor in Uptime Kuma
echo "Creating a new monitor in Uptime Kuma..."
MONITOR_ID=$(curl -s -X POST "$KUMA_API_URL/api/monitor" \
    -H "Authorization: Bearer $KUMA_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "'"$SERVER_NAME"' ("'"$SERVER_IP"'")",
        "type": "push",
        "pushInterval": 60,
        "url": "'"$PUSH_KEY"'",
        "description": "### Server Metrics\n\n[View Metrics Dashboard]('"$VISUALIZATION_URL"')"
    }' | jq -r '.id')

if [ -z "$MONITOR_ID" ]; then
    echo "Failed to create monitor. Exiting."
    exit 1
fi

echo "Monitor created with ID: $MONITOR_ID"

# Create systemd service
echo "Creating systemd service for monitoring..."
cat << EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=UnderHost Monitoring Agent
After=network.target

[Service]
ExecStart=/usr/bin/python3 $AGENT_DIR/$AGENT_SCRIPT
Restart=always
User=root
WorkingDirectory=$AGENT_DIR

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for visualization
echo "Creating systemd service for visualization server..."
cat << EOF > /etc/systemd/system/${SERVICE_NAME}_visualization.service
[Unit]
Description=UnderHost Monitoring Visualization Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 $AGENT_DIR/$VISUALIZATION_SERVER
Restart=always
User=root
WorkingDirectory=$AGENT_DIR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the services
echo "Starting the monitoring agent and visualization server..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME
systemctl enable ${SERVICE_NAME}_visualization
systemctl start ${SERVICE_NAME}_visualization

echo "Monitoring agent and visualization server installed and running!"
echo "Visualization available at: $VISUALIZATION_URL"
