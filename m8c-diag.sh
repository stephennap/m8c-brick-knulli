#!/bin/bash
# Standalone hardware/firmware probe for m8c.
#
# Drop this next to m8c.sh in roms/ports/, launch it from the Ports menu with
# the M8 plugged in and in headless mode, then read the report it writes to
# m8c-diag.txt beside this script. Answers whether the bundled cdc-acm.ko can
# work on this device, and whether m8c's libraries are present.
#
# Deliberately does NOT depend on PortMaster, so it runs on any firmware.

SCRIPTDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
OUT="$SCRIPTDIR/m8c-diag.txt"
CUR_TTY="/dev/tty0"

# Tell the user something is happening; the screen is all they can see.
{
  printf "\033c"
  printf "Running m8c diagnostics...\n\n"
} > "$CUR_TTY" 2>/dev/null

exec > "$OUT" 2>&1

echo "===== m8c diagnostic report ====="
echo "date       : $(date 2>/dev/null)"
echo "script dir : $SCRIPTDIR"
echo

echo "----- 1. Device and firmware -----"
echo "uname -a   : $(uname -a 2>/dev/null)"
echo "kernel     : $(uname -r 2>/dev/null)"
echo "arch       : $(uname -m 2>/dev/null)"
for f in /etc/os-release /usr/share/batocera/batocera.version /boot/batocera.version; do
  [ -f "$f" ] && { echo "--- $f ---"; cat "$f"; }
done
echo "device tree model: $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')"
echo

echo "----- 2. Bundled kernel module -----"
KO="$SCRIPTDIR/m8c/cdc-acm.ko"
if [ -f "$KO" ]; then
  MOD_VER="$(grep -ao 'vermagic=[0-9][^ ]*' "$KO" 2>/dev/null | head -1 | cut -d= -f2)"
  echo "cdc-acm.ko found : $KO"
  echo "built for kernel : ${MOD_VER:-unknown}"
  echo "this device runs : $(uname -r)"
  if [ -n "$MOD_VER" ] && [ "$MOD_VER" = "$(uname -r)" ]; then
    echo "VERDICT: versions match - module has a chance of loading."
  else
    echo "VERDICT: MISMATCH - insmod will reject this module. It needs rebuilding"
    echo "         against this device's kernel, OR the driver must be built in."
  fi
else
  echo "cdc-acm.ko not found at $KO (is the m8c/ folder beside this script?)"
fi
echo

echo "----- 3. Is CDC ACM already available? -----"
echo "(if it is, the bundled module is not needed at all)"
echo "lsmod | grep cdc:"
lsmod 2>/dev/null | grep -i cdc || echo "  (no cdc modules loaded)"
echo "built into kernel? checking /proc/config.gz and modules dir:"
zcat /proc/config.gz 2>/dev/null | grep -i 'CONFIG_USB_ACM' || echo "  (/proc/config.gz unavailable)"
ls /lib/modules/"$(uname -r)"/ 2>/dev/null | head -5 || echo "  (no /lib/modules for this kernel)"
find /lib/modules -name 'cdc-acm*' 2>/dev/null | head -5
echo

echo "----- 4. Is the M8 visible? -----"
echo "/dev/ttyACM*:"
ls -la /dev/ttyACM* 2>/dev/null || echo "  NONE - the M8 is not enumerating as a serial device"
echo "USB devices:"
lsusb 2>/dev/null || cat /sys/bus/usb/devices/*/product 2>/dev/null || echo "  (lsusb unavailable)"
echo "recent USB kernel messages:"
dmesg 2>/dev/null | grep -iE 'usb|acm|tty' | tail -25 || echo "  (dmesg unavailable)"
echo

echo "----- 5. Libraries m8c needs -----"
for lib in libserialport.so.0 libSDL2-2.0.so.0; do
  found="$(ldconfig -p 2>/dev/null | grep -F "$lib" | head -2)"
  if [ -n "$found" ]; then
    echo "OK      $lib"
    echo "$found" | sed 's/^/          /'
  else
    hit="$(find /usr/lib /lib /usr/local/lib -name "$lib*" 2>/dev/null | head -2)"
    if [ -n "$hit" ]; then
      echo "OK      $lib (found on disk, not in ldconfig cache)"
      echo "$hit" | sed 's/^/          /'
    else
      echo "MISSING $lib  <-- m8c cannot start without this"
    fi
  fi
done
BIN="$SCRIPTDIR/m8c/m8c-bin"
if [ -f "$BIN" ] && command -v ldd >/dev/null 2>&1; then
  echo "ldd of m8c-bin:"
  ldd "$BIN" 2>&1 | sed 's/^/  /'
fi
echo

echo "----- 6. Controller -----"
ls /dev/input/ 2>/dev/null | sed 's/^/  /'
for f in /sys/class/input/js*/device/name /proc/bus/input/devices; do
  [ -e "$f" ] && { echo "--- $f ---"; cat "$f" 2>/dev/null | head -40; }
done
echo

echo "----- 7. Display -----"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null | sed 's/^/  fb0 virtual_size: /'
cat /sys/class/graphics/fb0/modes 2>/dev/null | sed 's/^/  fb0 modes: /'
echo

echo "===== end of report ====="

{
  printf "\033c"
  printf "Done.\n\nReport written to:\n%s\n\nCopy it off the SD card.\n" "$OUT"
  sleep 6
} > "$CUR_TTY" 2>/dev/null

printf "\033c" > "$CUR_TTY" 2>/dev/null
