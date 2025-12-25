#!/bin/bash

set -eu pipefail

while true; do
    CPU_LOAD=$(uptime | awk '{print $9}' | cut -d',' -f1)
    FREE_MEM=$(free -m | awk 'NR==2{print $4}')
    DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | cut -d '%' -f1)
    NGINX_STATUS=""

    # Medic Logic (Service):
    if ! systemctl status nginx &> /dev/null; then
        NGINX_STATUS="inactive"
        echo "Nginx is down! Attempting restart..."
        sudo systemctl restart nginx
    else
        NGINX_STATUS="active"
    fi

    # Janitor
    if [[ $DISK_USAGE -ge 80 ]]; then
        echo "Disk Critical! Cleaning logs..."
        rm -rf "/tmp/*.tmp"
        echo "Temp files cleaned successfully"
    fi

    echo "------------- State Report --------------"
    echo "CPU_LOAD = $CPU_LOAD"
    echo "FREE_MEM = $FREE_MEM MB"
    echo "DISK_USAGE = $DISK_USAGE%"
    echo "NGINX_STATUS = $NGINX_STATUS"
    echo "------------- End of Report --------------"

    sleep 5
done
