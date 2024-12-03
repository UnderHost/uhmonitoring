#!/bin/bash

# Constants
AGENT_DIR="/opt/uhmonitoring"
AGENT_SCRIPT="uhmonitoring.py"
PUSH_KEY="UPDATE"
KUMA_API_URL="https://monitor.underhost.com"
SERVICE_NAME="uhmonitoring"

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
    apt update -y && apt install -y python3 python3-pip wget
elif [ "$PKG_MANAGER" = "yum" ]; then
    yum update -y && yum install -y python3 python3-pip wget
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

PUSH_KEY = "$PUSH_KEY"
KUMA_API_URL = "$KUMA_API_URL/api/push/\$PUSH_KEY"
SERVER_NAME = "$(hostname)"

def get_metrics():
    return {
        "cpu_usage": psutil.cpu_percent(interval=1),
        "memory_usage": psutil.virtual_memory().percent,
        "disk_usage": psutil.disk_usage('/').percent,
        "load_avg": psutil.getloadavg()
    }

def send_to_uptime_kuma(metrics):
    status = "up" if metrics["cpu_usage"] < 90 and metrics["memory_usage"] < 85 else "down"
    message = f"CPU: {metrics['cpu_usage']}%, RAM: {metrics['memory_usage']}%, Disk: {metrics['disk_usage']}%"
    response = requests.post(KUMA_API_URL, json={"status": status, "msg": message})
    print(f"Sent to Uptime Kuma: {response.status_code}, {response.text}")

while True:
    metrics = get_metrics()
    send_to_uptime_kuma(metrics)
    time.sleep(60)
EOF

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install psutil requests

# Create systemd service
echo "Creating systemd service..."
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

# Reload systemd, enable, and start the service
echo "Starting the monitoring agent..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "Monitoring agent installed and running!"
