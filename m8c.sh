#!/bin/bash
# m8c launcher for TrimUI Brick / Knulli
# Self-locating version: finds its own folder instead of relying on PortMaster's
# $directory variable, and uses the running kernel version rather than 4.9.191.

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

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

echo "=== m8c launcher ==="
echo "script   : $0"
echo "scriptdir: $SCRIPTDIR"
echo "gamedir  : $GAMEDIR"
echo "kernel   : $(uname -r)"
echo "directory var from PortMaster: $directory"
echo "--- contents of gamedir ---"
ls -la "$GAMEDIR"
echo "---------------------------"

cd "$GAMEDIR" || { echo "FATAL: cannot cd to $GAMEDIR"; exit 1; }

if [ ! -f "$BINARY" ]; then
  echo "FATAL: $BINARY not found in $GAMEDIR"
  exit 1
fi

$ESUDO chmod 666 $CUR_TTY
printf "\033c" > $CUR_TTY
printf "Starting m8c...\n" > $CUR_TTY

chmod 755 "$BINARY"

# --- USB serial (CDC ACM) support for the M8 ---
KVER="$(uname -r)"
if ls /dev/ttyACM* >/dev/null 2>&1; then
  echo "ttyACM device already present, skipping module load"
elif lsmod | grep -q '^cdc_acm'; then
  echo "cdc_acm already loaded, skipping"
else
  if ls *.ko >/dev/null 2>&1; then
    chmod 644 *.ko
    if [ -d "/lib/modules/$KVER" ]; then
      echo "Trying bundled cdc-acm.ko against kernel $KVER"
      cp *.ko "/lib/modules/$KVER/" 2>/dev/null
      depmod "$KVER" 2>/dev/null
      modprobe -a cdc-acm 2>&1 || insmod ./cdc-acm.ko 2>&1 || \
        echo "WARNING: could not load cdc-acm (module built for a different kernel?)"
    else
      echo "No /lib/modules/$KVER directory - trying insmod directly"
      insmod ./cdc-acm.ko 2>&1 || echo "WARNING: insmod cdc-acm.ko failed"
    fi
  else
    echo "WARNING: no cdc-acm.ko found in $GAMEDIR"
  fi
fi

echo "ttyACM devices now: $(ls /dev/ttyACM* 2>/dev/null || echo none)"
echo "--- launching $BINARY ---"

./"$BINARY"
echo "--- $BINARY exited with code $? ---"

pm_finish
printf "\033c" > $CUR_TTY
