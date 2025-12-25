#!/bin/bash

set -euo pipefail

while true; do
    CPU_LOAD=$(uptime | awk '{print $9}' | cut -d',' -f1)
    FREE_MEM=$(free -m | awk 'NR==2{print $4}')
    DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | cut -d '%' -f1)
    NGINX_STATUS=""

    # Medic Logic (Service):
    if ! systemctl status nginx &> /dev/null; then
        NGINX_STATUS="inactive"
        echo "Nginx is down! Attempting restart..."
        # systemctl restart nginx
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

    payload=$(jq -n \
        --arg cpu_load "$CPU_LOAD" \
        --arg ram_usage "$FREE_MEM" \
        --arg status "$NGINX_STATUS" \
        '{"cpu": $cpu_load, "ram": $ram_usage, "status": $status}'
    )

    echo "$payload"

    # Sending data over api
    curl -s -X POST \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        http://0.0.0.0:8000/report &> /dev/null
    echo "Data sent to http://0.0.0.0:8000/report"

    sleep 5
done