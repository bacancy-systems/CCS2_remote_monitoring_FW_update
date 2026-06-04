#!/bin/bash

# ─────────────────────────────────────────
# remote_cmd.sh — Fix wifi-boot-connect.sh + Restart WiFi Host
# Version: 2
# Purpose: 
#   1. Overwrite wifi-boot-connect.sh with fixed version
#   2. Disable WiFi host (auto-answer y to prompt)
#   3. Re-enable WiFi host with new config
# ─────────────────────────────────────────

TARGET="/home/pizerow/Project/Remote_Debug_Fw/wifi-usb/scripts/wifi-boot-connect.sh"
BACKUP="/home/pizerow/Project/Remote_Debug_Fw/wifi-usb/scripts/wifi-boot-connect.sh.bak"
WIFI_DIR="/home/pizerow/Project/Remote_Debug_Fw/wifi-usb"
DISABLE_SCRIPT="$WIFI_DIR/disable_wifi_host.sh"
SETUP_SCRIPT="$WIFI_DIR/setup_wifi_host.sh"

echo "========================================"
echo "  Remote Command: WiFi Script Update"
echo "  Date : $(date)"
echo "  Host : $(hostname)"
echo "  User : $(whoami)"
echo "========================================"

# ── STAGE 1: Update wifi-boot-connect.sh ──

# STEP 1: Verify target script exists
echo "[STEP 1] Checking target script exists..."
if [ ! -f "$TARGET" ]; then
    echo "  ERROR: Target not found → $TARGET"
    exit 1
fi
echo "  Found → $TARGET"

# STEP 2: Backup existing script
echo "[STEP 2] Creating backup..."
cp "$TARGET" "$BACKUP"
if [ $? -ne 0 ]; then
    echo "  ERROR: Backup failed. Aborting."
    exit 1
fi
echo "  Backup saved → $BACKUP"

# STEP 3: Write fixed script
echo "[STEP 3] Writing fixed wifi-boot-connect.sh..."
cat > "$TARGET" << 'ENDOFSCRIPT'
#!/bin/bash
LOG="/var/log/usb-wifi.log"
CONFIG="/etc/wifi-usb/wifi.conf"
APPLIED="/etc/wifi-usb/applied.conf"

echo "$(date) -- Boot connect script started." >> "$LOG"

if [ ! -f "$CONFIG" ]; then
    echo "$(date) -- No wifi.conf found, skipping." >> "$LOG"
    exit 0
fi

SSID=$(grep '^SSID='         "$CONFIG" | sed 's/^SSID=//'      | tr -d '\r\n' | tr -d '\r' | tr -d '\n')
PASSWORD=$(grep '^PASSWORD=' "$CONFIG" | sed 's/^PASSWORD=//'   | tr -d '\r\n' | tr -d '\r' | tr -d '\n')

APPLIED_SSID=""
APPLIED_PASSWORD=""
if [ -f "$APPLIED" ]; then
    APPLIED_SSID=$(grep '^SSID='         "$APPLIED" | sed 's/^SSID=//'      | tr -d '\r\n' | tr -d '\r' | tr -d '\n')
    APPLIED_PASSWORD=$(grep '^PASSWORD=' "$APPLIED" | sed 's/^PASSWORD=//'  | tr -d '\r\n' | tr -d '\r' | tr -d '\n')
fi

if [ "$SSID" != "$APPLIED_SSID" ] || [ "$PASSWORD" != "$APPLIED_PASSWORD" ]; then
    echo "$(date) -- Wi-Fi changed, connecting to: $SSID" >> "$LOG"

    sudo nmcli connection delete "$SSID" >> "$LOG" 2>&1 || true
    sudo nmcli dev wifi rescan 2>>"$LOG" || true
    sleep 15

    sudo nmcli dev wifi connect "$SSID" password "$PASSWORD" \
        ifname wlan0 >> "$LOG" 2>&1

    if [ $? -eq 0 ]; then
        echo "$(date) -- Wi-Fi connected to $SSID successfully." >> "$LOG"

        cat > "$APPLIED" << EOF
SSID=${SSID}
PASSWORD=${PASSWORD}
EOF
        echo "$(date) -- Applied state saved." >> "$LOG"

    else
        echo "$(date) -- Wi-Fi connection FAILED for $SSID. Applied state NOT saved." >> "$LOG"
        echo "$(date) -- Next boot will retry connection." >> "$LOG"
        exit 1
    fi

else
    echo "$(date) -- Wi-Fi unchanged, skipping." >> "$LOG"
fi

echo "$(date) -- Done." >> "$LOG"
ENDOFSCRIPT

if [ $? -ne 0 ]; then
    echo "  ERROR: Failed to write fixed script. Restoring backup..."
    cp "$BACKUP" "$TARGET"
    exit 1
fi
echo "  Fixed script written successfully."

# STEP 4: Set correct permissions
echo "[STEP 4] Setting permissions..."
chmod 755 "$TARGET"
echo "  Permissions set → 755"

# STEP 5: Verify fix is present in written file
echo "[STEP 5] Verifying written file..."
if grep -q "Applied state NOT saved" "$TARGET"; then
    echo "  Verification passed → fix is present in script."
else
    echo "  ERROR: Verification failed. Restoring backup..."
    cp "$BACKUP" "$TARGET"
    exit 1
fi

# ── STAGE 2: Disable WiFi Host ──

echo "----------------------------------------"
echo "[STEP 6] Checking disable_wifi_host.sh..."
if [ ! -f "$DISABLE_SCRIPT" ]; then
    echo "  ERROR: Disable script not found → $DISABLE_SCRIPT"
    exit 1
fi
echo "  Found → $DISABLE_SCRIPT"

echo "[STEP 7] Disabling WiFi host (auto-confirming prompt)..."
# 'echo y' pipes 'y' automatically to answer any confirmation prompt
echo "y" | sudo bash "$DISABLE_SCRIPT"
if [ $? -ne 0 ]; then
    echo "  ERROR: disable_wifi_host.sh failed."
    exit 1
fi
echo "  WiFi host disabled successfully."

# ── STAGE 3: Re-enable WiFi Host ──

echo "----------------------------------------"
echo "[STEP 8] Checking setup_wifi_host.sh..."
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo "  ERROR: Setup script not found → $SETUP_SCRIPT"
    exit 1
fi
echo "  Found → $SETUP_SCRIPT"

echo "[STEP 9] Re-enabling WiFi host..."
sudo bash "$SETUP_SCRIPT"
if [ $? -ne 0 ]; then
    echo "  ERROR: setup_wifi_host.sh failed."
    exit 1
fi
echo "  WiFi host re-enabled successfully."

# ── STAGE 4: Final Summary ──

echo "========================================"
echo "  All steps completed successfully"
echo "  Script updated : $TARGET"
echo "  Backup at      : $BACKUP"
echo "  WiFi host      : Disabled → Re-enabled"
echo "  Fix applied    : applied.conf saved only on successful connect"
echo "========================================"
