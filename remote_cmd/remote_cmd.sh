#!/bin/bash

# ─────────────────────────────────────────
# remote_cmd.sh — Sample Remote Command Script
# Version: 1
# Purpose: Test that remote command pipeline works
# ─────────────────────────────────────────

echo "========================================"
echo "  Remote Command Script Started"
echo "  Date : $(date)"
echo "  Host : $(hostname)"
echo "  User : $(whoami)"
echo "========================================"

# Test 1: Basic echo
echo "[TEST 1] Basic echo → OK"

# Test 2: Check Pi hardware
echo "[TEST 2] Hardware info:"
echo "  CPU Temp : $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
echo "  Uptime   : $(uptime -p)"
echo "  Free RAM : $(free -h | awk '/^Mem:/ {print $4}') available"

# Test 3: Check disk space
echo "[TEST 3] Disk space:"
df -h / | awk 'NR==2 {print "  Used: "$3" / "$2" ("$5" full)"}'

# Test 4: Check firmware app status
echo "[TEST 4] Firmware app service status:"
systemctl is-active remoteDebugUnitAppSer && echo "  Service → RUNNING" || echo "  Service → STOPPED"

# Test 5: Write a test file to confirm script ran
echo "[TEST 5] Writing proof file..."
echo "remote_cmd ran at $(date)" > /home/pizerow/Project/remote_cmd_proof.txt
echo "  Proof file written → remote_cmd_proof.txt"

echo "========================================"
echo "  Remote Command Script Completed OK"
echo "========================================"
