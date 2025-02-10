#!/bin/bash

# Set the log file path
LOG_FILE="/var/log/node_exporter_setup.log"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Node Exporter setup..."

# Download and install Node Exporter
echo "Downloading Node Exporter..."
VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/prometheus/node_exporter/releases/download/$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz
tar xvfz node_exporter-$VERSION.linux-amd64.tar.gz
sudo cp node_exporter-$VERSION.linux-amd64/node_exporter /usr/local/bin/

echo "Node Exporter downloaded and binary placed in /usr/local/bin"

# Create the node_exporter user if it doesn't already exist
echo "Creating node_exporter user..."
if ! id "node_exporter" &>/dev/null; then
    sudo useradd -rs /bin/false node_exporter
fi
echo "User node_exporter created or already exists."

# Create the systemd service file for Node Exporter
echo "Creating systemd service file..."
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service file created."

# Reload systemd to apply new changes
echo "Reloading systemd..."
sudo systemctl daemon-reload
echo "Systemd reloaded."

# Enable and start the Node Exporter service
echo "Enabling and starting Node Exporter service..."
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
echo "Node Exporter service enabled and started."

# Open port 9100 on the firewall
echo "Configuring the firewall..."
sudo ufw allow 9100/tcp
echo "Firewall configured to allow traffic on port 9100."

# Verify service status
echo "Checking the service status..."
sudo systemctl status node_exporter | grep Active

echo "Node Exporter setup completed successfully."
