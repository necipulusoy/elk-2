#!/bin/bash

echo "Stopping Elasticsearch service..."
sudo systemctl stop elasticsearch

echo "Disabling Elasticsearch service..."
sudo systemctl disable elasticsearch

echo "Removing Elasticsearch package..."
sudo dnf remove -y elasticsearch

echo "Removing Elasticsearch repository..."
if [ -f /etc/yum.repos.d/elasticsearch.repo ]; then
    sudo rm -f /etc/yum.repos.d/elasticsearch.repo
    echo "Elasticsearch repository removed."
else
    echo "Elasticsearch repository not found."
fi

echo "Removing Elasticsearch configuration files..."
sudo rm -rf /etc/elasticsearch

echo "Checking for elasticsearch.yml.rpmsave..."
if [ -f /etc/elasticsearch/elasticsearch.yml.rpmsave ]; then
    sudo rm -f /etc/elasticsearch/elasticsearch.yml.rpmsave
    echo "elasticsearch.yml.rpmsave file removed."
fi

echo "Removing Elasticsearch log files..."
sudo rm -rf /var/log/elasticsearch

echo "Removing Elasticsearch data files..."
sudo rm -rf /var/lib/elasticsearch

echo "Removing Elasticsearch cache and temporary files..."
sudo rm -rf /data/elasticsearch

echo "Checking if Elasticsearch package is still installed..."
rpm -qa | grep elasticsearch
if [ $? -ne 0 ]; then
    echo "Elasticsearch has been successfully removed."
else
    echo "Elasticsearch package is still present. Manual check recommended."
fi
