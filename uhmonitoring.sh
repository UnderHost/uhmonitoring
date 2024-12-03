#!/bin/bash

# Constants
AGENT_DIR="/opt/uhmonitoring"
AGENT_SCRIPT="uhmonitoring.py"
PUSH_KEY="uk1_5ShIjaHYHV_9bU-z5i3E4mFPz0rvmgHhvAgE7gEq"
KUMA_API_URL="https://monitor.underhost.com"
KUMA_API_KEY="YOUR_UPTIME_KUMA_API_KEY"  # Replace with your API key
SERVER_NAME=$(hostname)
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

PUSH_KEY = "$PUSH_KEY"
KUMA_API_URL = "$KUMA_API_URL/api/push/\$PUSH_KEY"
SERVER_NAME = "$SERVER_NAME"

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

# Create a new monitor in Uptime Kuma
echo "Creating a new monitor in Uptime Kuma..."
MONITOR_ID=$(curl -s -X POST "$KUMA_API_URL/api/monitor" \
    -H "Authorization: Bearer $KUMA_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "'"$SERVER_NAME"'",
        "type": "push",
        "pushInterval": 60,
        "url": "'"$PUSH_KEY"'"
    }' | jq -r '.id')

if [ -z "$MONITOR_ID" ]; then
    echo "Failed to create monitor. Exiting."
    exit 1
fi

echo "Monitor created with ID: $MONITOR_ID"

# Create a new status page in Uptime Kuma
echo "Creating a new status page in Uptime Kuma..."
STATUS_PAGE_ID=$(curl -s -X POST "$KUMA_API_URL/api/status-page" \
    -H "Authorization: Bearer $KUMA_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "title": "'"$SERVER_NAME Status"'",
        "slug": "'"$SERVER_NAME"'",
        "description": "Live status and metrics for '"$SERVER_NAME"'"
    }' | jq -r '.id')

if [ -z "$STATUS_PAGE_ID" ]; then
    echo "Failed to create status page. Exiting."
    exit 1
fi

echo "Status page created with ID: $STATUS_PAGE_ID"

# Add the monitor to the status page
echo "Adding monitor to the status page..."
curl -s -X POST "$KUMA_API_URL/api/status-page/$STATUS_PAGE_ID/monitor" \
    -H "Authorization: Bearer $KUMA_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "monitorID": '"$MONITOR_ID"'
    }'

echo "Monitor added to the status page."

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

echo "Monitoring agent installed and running! Status page created at: $KUMA_API_URL/status-page/$STATUS_PAGE_ID"
