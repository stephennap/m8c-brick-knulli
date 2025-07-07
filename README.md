# m8c for TrimUI Brick

Precompiled **m8c client** and required **kernel module** for using the **DirtyWave M8 Headless firmware** on the **TrimUI Brick** handheld (Allwinner A133 Plus).

> ⚠️ Tested on TrimUI Brick with **Knulli CFW "Gladiator"**

---

## 📦 Download

Binaries are available in the [Releases section](https://github.com/f32-0/m8c-brick-knulli/releases/latest).

- `m8c/` — compiled client binary, config and kernel module
- `m8c.sh` — launch script


---

## 📥 Installation (Knulli CFW)

1. **Install Portmaster** on your TrimUI Brick.
2. Download the `m8c-brick-knulli.zip` file from [Releases](https://github.com/f32-0/m8c-brick-knulli/releases/latest) and extract it.
3. Locate the `roms/ports/` folder on the SD card (usually inside the `SHARE` volume).
4. Copy the extracted `m8c/` folder and `m8c.sh` script into `roms/ports/`.

```
/SHARE/roms/ports/
              ├── m8c.sh
              └── m8c/
                  ├── m8c-bin
                  ├── cdc-acm.ko
                  └── m8c/
                      └── config.ini
```

### Make Files Executable

If the launcher fails with **"Permission denied"**, open a ssh session and run:

```bash
cd /userdata/roms/ports
chmod 755 m8c.sh
```
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


## 🔗 Useful Links

- [Knulli CFW Website](https://knulli.org/)
- [laamaa/m8c (Original Client)](https://github.com/laamaa/m8c)
- [Dirtywave/M8 Headless Firmware](https://github.com/Dirtywave/M8HeadlessFirmware)
- [jamesMcMeex/m8c-rg35xx-knulli](https://github.com/jamesMcMeex/m8c-rg35xx-knulli)

---

## 🎵 Demo Video

[![Synthwave - M8 Headless Tracker](https://img.youtube.com/vi/zaukeZiJM68/maxresdefault.jpg)](https://www.youtube.com/watch?v=zaukeZiJM68 "Synthwave - M8 Headless Tracker")

---

