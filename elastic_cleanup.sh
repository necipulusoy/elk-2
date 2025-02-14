#!/bin/bash

echo "=== Elasticsearch Complete Cleanup Script ==="

echo "1. Stopping Elasticsearch service..."
sudo systemctl stop elasticsearch 2>/dev/null || echo "Elasticsearch service is not running."

echo "2. Killing any remaining Elasticsearch processes..."
sudo pkill -f elasticsearch 2>/dev/null || echo "No Elasticsearch processes found."

echo "3. Removing Elasticsearch directories and files..."
sudo rm -rf /var/lib/elasticsearch
sudo rm -rf /var/log/elasticsearch
sudo rm -rf /etc/elasticsearch
sudo rm -rf /tmp/elasticsearch*
sudo rm -rf /var/run/elasticsearch*
sudo rm -rf /usr/share/elasticsearch
sudo rm -rf /opt/elasticsearch

echo "4. Removing Elasticsearch YUM repository..."
sudo rm -f /etc/yum.repos.d/elasticsearch.repo

echo "5. Resetting systemd service states..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "6. Removing cached Elasticsearch packages..."
sudo yum remove -y elasticsearch 2>/dev/null || echo "Elasticsearch package already removed."
sudo yum clean all

echo "7. Verifying cleanup..."
remaining_files=$(find /var/lib/elasticsearch /etc/elasticsearch /var/log/elasticsearch /usr/share/elasticsearch /opt/elasticsearch -type d 2>/dev/null)
if [[ -z "$remaining_files" ]]; then
  echo "Elasticsearch has been completely removed from the system."
else
  echo "Warning: Some Elasticsearch files may still exist:"
  echo "$remaining_files"
  echo "Please check and remove manually if necessary."
fi

echo "Cleanup complete."
