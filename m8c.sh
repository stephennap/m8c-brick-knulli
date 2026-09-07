#!/bin/bash
# m8c launcher for TrimUI Brick / Knulli
# Self-locating: finds its own folder instead of relying on PortMaster's
# $directory variable, and uses the running kernel version rather than a
# hardcoded 4.9.191.

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Resolve the folder this script lives in, then the m8c/ folder beside it
SCRIPTDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
GAMEDIR="$SCRIPTDIR/m8c"
CUR_TTY="/dev/tty0"
BINARY="m8c-bin"

export XDG_CONFIG_HOME="$GAMEDIR"
export XDG_DATA_HOME="$GAMEDIR"

# Start logging BEFORE validating anything. A missing game dir is the most
# likely install error, and logging into it would fail silently and leave
# the errors below with nowhere to go.
LOGFILE="$GAMEDIR/log.txt"
[ -d "$GAMEDIR" ] || LOGFILE="$SCRIPTDIR/m8c-launch-error.log"
: > "$LOGFILE" 2>/dev/null || LOGFILE="/tmp/m8c-launch-error.log"
: > "$LOGFILE" 2>/dev/null
exec > >(tee "$LOGFILE") 2>&1

# Restore the console even if the frontend kills us mid-run
cleanup() {
  command -v pm_finish >/dev/null 2>&1 && pm_finish
  printf "\033c" > "$CUR_TTY" 2>/dev/null
}
trap cleanup EXIT INT TERM

echo "=== m8c launcher ==="
echo "script   : $0"
echo "scriptdir: $SCRIPTDIR"
echo "gamedir  : $GAMEDIR"
echo "logfile  : $LOGFILE"
echo "kernel   : $(uname -r)"
echo "directory var from PortMaster: $directory"

if [ ! -d "$GAMEDIR" ]; then
  echo "FATAL: game dir not found: $GAMEDIR"
  echo "Copy both m8c.sh AND the m8c/ folder into roms/ports/."
  exit 1
fi

echo "--- contents of gamedir ---"
ls -la "$GAMEDIR"
echo "---------------------------"

cd "$GAMEDIR" || { echo "FATAL: cannot cd to $GAMEDIR"; exit 1; }

if [ ! -f "$BINARY" ]; then
  echo "FATAL: $BINARY not found in $GAMEDIR"
  exit 1
fi

$ESUDO chmod 666 "$CUR_TTY"
printf "\033c" > "$CUR_TTY"
printf "Starting m8c...\n" > "$CUR_TTY"

chmod 755 "$BINARY"

# SDL reads this for controller mapping; PortMaster ships a copy.
if [ ! -f "$GAMEDIR/m8c/gamecontrollerdb.txt" ] && [ -f "$controlfolder/gamecontrollerdb.txt" ]; then
  cp "$controlfolder/gamecontrollerdb.txt" "$GAMEDIR/m8c/gamecontrollerdb.txt" 2>/dev/null \
    && echo "Installed gamecontrollerdb.txt from PortMaster"
fi

# --- USB serial (CDC ACM) support for the M8 ---
KVER="$(uname -r)"
if ls /dev/ttyACM* >/dev/null 2>&1; then
  echo "ttyACM device already present, skipping module load"
elif lsmod | grep -q '^cdc_acm'; then
  echo "cdc_acm already loaded, skipping"
else
  if ls ./*.ko >/dev/null 2>&1; then
    # insmod rejects any vermagic mismatch, so say so plainly up front
    MOD_VER="$(grep -ao 'vermagic=[0-9][^ ]*' cdc-acm.ko 2>/dev/null | head -1 | cut -d= -f2)"
    if [ -n "$MOD_VER" ] && [ "$MOD_VER" != "$KVER" ]; then
      echo "WARNING: cdc-acm.ko was built for kernel $MOD_VER but this device runs $KVER."
      echo "         The load below will almost certainly fail; the module needs rebuilding."
    fi

    $ESUDO chmod 644 ./*.ko
    if [ -d "/lib/modules/$KVER" ]; then
      echo "Trying bundled cdc-acm.ko against kernel $KVER"
      $ESUDO cp ./*.ko "/lib/modules/$KVER/" 2>/dev/null
      $ESUDO depmod "$KVER" 2>/dev/null
      $ESUDO modprobe -a cdc-acm 2>&1 || $ESUDO insmod ./cdc-acm.ko 2>&1 || \
        echo "WARNING: could not load cdc-acm (module built for a different kernel?)"
    else
      echo "No /lib/modules/$KVER directory - trying insmod directly"
      $ESUDO insmod ./cdc-acm.ko 2>&1 || echo "WARNING: insmod cdc-acm.ko failed"
    fi
  else
    echo "WARNING: no cdc-acm.ko found in $GAMEDIR"
  fi
fi

echo "ttyACM devices now: $(ls /dev/ttyACM* 2>/dev/null || echo none)"

# m8c needs libserialport, which isn't on every image. Without this check the
# dynamic linker fails with no output reaching the log.
if command -v ldd >/dev/null 2>&1; then
  MISSING="$(ldd ./"$BINARY" 2>/dev/null | grep 'not found' | awk '{print $1}')"
  if [ -n "$MISSING" ]; then
    echo "WARNING: missing shared libraries - m8c will not start:"
    echo "$MISSING" | sed 's/^/  /'
  fi
fi

echo "--- launching $BINARY ---"

./"$BINARY"
echo "--- $BINARY exited with code $? ---"
