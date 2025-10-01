#!/bin/bash
# inventory.sh - Focused VPS inventory in JSON

HOST=$(hostname)
NOW=$(date +"%Y-%m-%d %H:%M:%S")

# ---- Running services ----
RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-legend \
  | awk '{print $1}' \
  | jq -R . | jq -s .)

# ---- User cron ----
USER_CRON=$(crontab -l 2>/dev/null | jq -R . | jq -s .)

# ---- System cron ----
SYSTEM_CRON=$(
  { cat /etc/crontab 2>/dev/null; ls -1 /etc/cron.*/* 2>/dev/null; } \
  | jq -R . | jq -s .
)

# ---- Docker ----
DOCKER_CONTAINERS=$(docker ps -a --format '{{.Names}}:{{.Status}}' 2>/dev/null \
  | jq -R . | jq -s .)

# ---- System stats ----
CPU_COUNT=$(nproc)
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
DISK_TOTAL=$(df -BG --output=size / | tail -1 | tr -dc '0-9')
DISK_AVAILABLE=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')

# ---- JSON Output ----
jq -n \
  --arg host "$HOST" \
  --arg generated "$NOW" \
  --argjson running_services "$RUNNING_SERVICES" \
  --argjson user_cron "$USER_CRON" \
  --argjson system_cron "$SYSTEM_CRON" \
  --argjson docker_containers "$DOCKER_CONTAINERS" \
  --arg cpu_count "$CPU_COUNT" \
  --arg mem_total_kb "$MEM_TOTAL" \
  --arg mem_available_kb "$MEM_AVAILABLE" \
  --arg disk_total_gb "$DISK_TOTAL" \
  --arg disk_available_gb "$DISK_AVAILABLE" \
  '{
    host: $host,
    generated: $generated,
    running_services: $running_services,
    user_cron: $user_cron,
    system_cron: $system_cron,
    docker_containers: $docker_containers,
  system_stats: {
    cpu_count: $cpu_count|tonumber,
    mem_total_kb: $mem_total_kb|tonumber,
    mem_available_kb: $mem_available_kb|tonumber,
    disk_total_gb: $disk_total_gb|tonumber,
    disk_available_gb: $disk_available_gb|tonumber
  }

  }'
