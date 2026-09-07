# m8c for TrimUI Brick

Precompiled **m8c client** and required **kernel module** for using the **DirtyWave M8 Headless firmware** on the **TrimUI Brick** handheld (Allwinner A133 Plus).

> ⚠️ Tested on TrimUI Brick with **Knulli CFW "Gladiator"** (kernel 4.9.191), M8 Headless firmware 6.5.2

> This is a fork of [f32-0/m8c-brick-knulli](https://github.com/f32-0/m8c-brick-knulli) with a
> [reworked launcher](#-whats-different-in-this-fork) and the binaries committed to the repo, so
> there is no separate download step.

---

## 📦 What's in here

Everything needed to run m8c lives in this repo — no release zip to fetch:

- `m8c.sh` — launch script
- `m8c/` — client binary, kernel module and config
  - `m8c-bin` — compiled m8c client (aarch64)
  - `cdc-acm.ko` — USB serial kernel module, built for kernel **4.9.191**
  - `m8c/config.ini` — default config, already mapped for the Brick's controls

---

## 📥 Installation (Knulli CFW)

1. **Install PortMaster** on your TrimUI Brick.
2. Download this repo: **Code → Download ZIP**, then extract it. (Or `git clone https://github.com/stephennap/m8c-brick-knulli.git`.)
3. Locate the `roms/ports/` folder on the SD card (usually inside the `SHARE` volume).
4. Copy **`m8c.sh`** and the **`m8c/`** folder into `roms/ports/`. Everything else — `README.md`, `LICENSE`, `.git*` — stays behind.

```
/SHARE/roms/ports/
              ├── m8c.sh
              └── m8c/
                  ├── m8c-bin
                  ├── cdc-acm.ko
                  └── m8c/
                      └── config.ini
```

5. Refresh the games list (or reboot) and launch **m8c** from the **Ports** collection.

> 💡 Plug the M8 in **before** launching. The script loads the USB serial module at startup and then looks for the device.

### Make Files Executable

If the launcher fails with **"Permission denied"**, open an SSH session and run:

```bash
cd /userdata/roms/ports
chmod 755 m8c.sh
```

The script sets the permissions on `m8c-bin` and the kernel module itself, so `m8c.sh` is the only one that needs this.

---

## 🎮 Key Mapping

```
DPAD        - LEFT, RIGHT, UP, DOWN
SELECT      - SHIFT
START       - PLAY
B           - EDIT
A           - OPTIONS
SELECT + Y  - Close application
```

Remap these in `m8c/m8c/config.ini` under `[gamepad]`. Note that m8c **rewrites that file on exit**, so edit it with the app closed.

---

## 🔧 Troubleshooting

Every launch writes a full log to **`roms/ports/m8c/log.txt`**, including the resolved paths, the running kernel and whether the module loaded. Read that first.

If the `m8c/` folder is missing entirely, the log can't go there — the script falls back to **`m8c-launch-error.log`** next to `m8c.sh`.

| Symptom | Likely cause |
| --- | --- |
| `FATAL: game dir not found` | Only `m8c.sh` was copied. The `m8c/` folder has to sit beside it — compare against the tree above. |
| `FATAL: m8c-bin not found` | `m8c/` is there but empty, or nested one level too deep. |
| `WARNING: cdc-acm.ko was built for kernel X but this device runs Y` | The bundled module only loads on the kernel it was compiled against. It needs rebuilding for yours. |
| `WARNING: missing shared libraries` | The image lacks a library m8c needs — usually `libserialport.so.0`. Install it, or copy one in and set `LD_LIBRARY_PATH`. |
| `ttyACM devices now: none` | M8 not detected — confirm it's in **headless** mode, plugged into the USB-C data port, and connected before launch. |
| `bad interpreter: /bin/bash^M` | `m8c.sh` picked up Windows CRLF line endings. Re-copy it, or run `dos2unix m8c.sh` on the device. |
| Nothing happens, no log written anywhere | `m8c.sh` isn't executable, so it never ran — see [Make Files Executable](#make-files-executable). |

---

## 🔀 What's different in this fork

The launcher was rewritten to be portable ([details](https://github.com/f32-0/m8c-brick-knulli/pull/2)):

- **Self-locating** — finds its own folder via `readlink -f` instead of relying on PortMaster's `$directory` variable, so it works wherever the port is installed.
- **Kernel-version agnostic** — uses `uname -r` rather than a hardcoded `/lib/modules/4.9.191`, with an `insmod` fallback.
- **Re-launch safe** — skips loading the module when the device or `cdc_acm` is already present, instead of spamming modprobe errors.
- **Diagnosable** — fails with a clear message when files are missing, and logs the environment to `log.txt`. Logging starts before any validation, so a missing `m8c/` folder still produces a log rather than silence.
- **Preflight checks** — compares the module's `vermagic` against the running kernel and reports missing shared libraries, instead of letting either fail cryptically.
- **Console-safe** — restores the TTY from an `EXIT`/`INT`/`TERM` trap, so quitting or being killed by the frontend doesn't leave a garbled screen.
- **Correct privileges** — module loading uses `$ESUDO` like the rest of the script, rather than assuming root.

Binaries are byte-identical to the upstream v0.1 release:

```
m8c-bin     f569c7b98f6aacc5ac46872f5da066b56684fb65662bc159856991391eb695e2
cdc-acm.ko  d581b891d21721c464d6ea83e07454465b263eff60fd3ee8e22b4ec5916c5ee1
```

---

## 🔗 Useful Links

- [f32-0/m8c-brick-knulli (upstream)](https://github.com/f32-0/m8c-brick-knulli)
- [Knulli CFW Website](https://knulli.org/)
- [laamaa/m8c (Original Client)](https://github.com/laamaa/m8c)
- [Dirtywave/M8 Headless Firmware](https://github.com/Dirtywave/M8HeadlessFirmware)
- [jamesMcMeex/m8c-rg35xx-knulli](https://github.com/jamesMcMeex/m8c-rg35xx-knulli)

---

## 🎵 Demo Video

[![Last Boss - Synthwave & Chiptune inspired M8 Headless Track](https://img.youtube.com/vi/CQViXEN8nNE/maxresdefault.jpg)](https://www.youtube.com/watch?v=CQViXEN8nNE "Last Boss - Synthwave & Chiptune inspired M8 Headless Track")

---
