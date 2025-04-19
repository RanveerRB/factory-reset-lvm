#!/bin/bash

# Factory Reset Snapshot Initializer Script

# Helper function
function echo_title() {
  echo -e "\n\033[1;32m$1\033[0m"
}

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (sudo)."
  exit 1
fi

echo_title "🔍 Detecting LVM root volume..."

# Detect LVM root volume and VG
ROOT_MOUNT=$(findmnt -n -o SOURCE /)
if [[ "$ROOT_MOUNT" != /dev/mapper/* ]]; then
  echo "❌ LVM not detected. This script only works with LVM root setups."
  exit 1
fi

LV_PATH="$ROOT_MOUNT"
VG_NAME=$(lvs --noheadings -o vg_name "$LV_PATH" | awk '{print $1}')
LV_NAME=$(lvs --noheadings -o lv_name "$LV_PATH" | awk '{print $1}')
SNAP_NAME="root_factory_reset"

# Check if snapshot already exists
if lvdisplay "/dev/${VG_NAME}/${SNAP_NAME}" &>/dev/null; then
  echo "⚠️ Snapshot already exists. Skipping creation."
else
  echo_title "🛠️ Creating snapshot named '${SNAP_NAME}'..."
  lvcreate --size 2G --snapshot --name "$SNAP_NAME" "$LV_PATH"
fi

# Create reset script
RESET_SCRIPT="/usr/local/bin/reset-to-factory.sh"

echo_title "📄 Creating reset script at $RESET_SCRIPT..."

cat <<EOF > "$RESET_SCRIPT"
#!/bin/bash
# Reset system to factory snapshot
# WARNING: This will revert all system changes since snapshot!

echo "⚠️ This will reset the system to the factory snapshot!"
read -p "Type 'RESET' to confirm: " CONFIRM

if [ "\$CONFIRM" != "RESET" ]; then
  echo "❌ Reset cancelled."
  exit 1
fi

echo "🧯 Reverting to factory snapshot..."
sleep 2

# Unmount root, merge snapshot, reboot
echo "➡️ Merging snapshot (requires reboot)..."

# This must be done from a live USB or recovery shell, as root can't be reverted while mounted
echo "❌ Cannot reset while system is running. Please boot from a Live CD and run:"
echo "lvconvert --merge /dev/${VG_NAME}/${SNAP_NAME}"
echo "Then reboot. The system will be restored to factory state."
EOF

chmod +x "$RESET_SCRIPT"

echo_title "✅ Done! Snapshot created and reset script ready."
echo "To reset the system in the future:"
echo "1. Boot from Ubuntu Live CD"
echo "2. Open terminal and run:"
echo "   sudo lvconvert --merge /dev/${VG_NAME}/${SNAP_NAME}"
echo "   sudo reboot"
