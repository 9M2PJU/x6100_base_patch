# X6100 Extended BASE Firmware

![X6100](assets/x6100-header.jpg)

Patched DSP firmware for the **BASE board** (`STM32F427`) of the Xiegu X6100.
Better TX audio, FM, filters, NR/NB, VOX, IF-shift and spectrum flow — works with the stock GUI and with R1CBU / OpenX6100 style GUIs.

> **Disclaimer:** provided as-is, use at your own risk. Flash on external power, never on battery alone.

---

## 30-second overview

| | |
|---|---|
| **What you get** | TX compressor + noise gate, fixed AM/FM, true power control, adaptive notch (ANF), noise reduction (NR) + blanker (NB), VOX, IF-shift, wider spectrum zoom (`fft_span`), TX bandpass control, TX/RX calibration gains |
| **What you flash** | One `.xgf` file to `/usr/firmware`, then flash from the radio menu |
| **How long** | ~5 min (mostly WiFi copy) |
| **Risk** | BASE-only patch; boot stock FW without SD card before uploading |

<details>
<summary><b>Is this for me? Click to check</b></summary>

- Yes, if you use SSB/CW/AM/FM on the X6100 and want cleaner TX/RX.
- Yes, if you use R1CBU GUI — extra sliders (comp ratio, ANF, NR/NB, IF-shift, TX filter, `TX codec gain`) light up.
- No, if you only want stock behavior — skip it.

</details>

## Compatibility

| Your OEM BASE | Use this file | Notes |
|---|---|---|
| `V1.1.6 221112001` | `firmwares/X6100_BBFW_V1.1.6_221112001_r*.xgf` | older BBFW |
| `V1.1.6 230307001` | `firmwares/X6100_BBFW_V1.1.6_230307001_r*.xgf` | recommended, newest DSP |

Check yours on the radio: **System info → BASE**. Pick the highest `rN` for your date. Prebuilt files are in [`firmwares/`](firmwares/) and on the [releases](https://github.com/9M2PJU/x6100_base_patch/releases) page (upstream: [gdyuldin/x6100_base_patch](https://github.com/gdyuldin/x6100_base_patch/releases)).

---

## Option A — Automatic install (recommended, easiest)

You run one small script on your computer. It sends the firmware file to the radio over WiFi. You do **not** need WinSCP or FileZilla. The actual flashing still happens safely from the radio menu.

### Fastest — one line, nothing to download first

The script finds the radio by itself, shows a firmware menu, and downloads the latest firmware if needed. Just paste one line:

**Linux / macOS** (in Terminal):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/9M2PJU/x6100_base_patch/1.1.6/tools/install.sh)
```

**Windows** (in PowerShell):

```powershell
$f="$env:TEMP\x6100-install.ps1"; irm https://raw.githubusercontent.com/9M2PJU/x6100_base_patch/1.1.6/tools/install.ps1 -OutFile $f; & $f
```

Prefer files on disk? Follow Step 1 below, then run the script from the folder.

### What you need

- [ ] Radio with stock firmware booted (**take the SD card out** first)
- [ ] Radio connected to your home WiFi (write down its **IP address** from the radio's WiFi screen, e.g. `192.168.1.100`)
- [ ] Radio plugged into **external power** (do not flash on battery)
- [ ] Your computer on the **same WiFi** as the radio
- [ ] SSH login for the radio: user `root`, password `123` (unless you changed it before)

### Step 1 — Download the installer and the firmware to your computer

**Way 1 — Download ZIP (best for beginners, no extra tools):**

1. Open https://github.com/9M2PJU/x6100_base_patch in your browser.
2. Make sure the branch says `1.1.6`, click the green **`<> Code`** button → **`Download ZIP`**.
3. Unzip the file. You get a folder like `x6100_base_patch-1.1.6` containing:
   - `tools/install.sh` (for Linux / Mac)
   - `tools/install.ps1` (for Windows)
   - `firmwares/` (the `.xgf` firmware files — pick the one matching your BASE date, highest `rN`)

**Way 2 — Git clone (if you already use git):**

```bash
git clone --branch 1.1.6 https://github.com/9M2PJU/x6100_base_patch.git
cd x6100_base_patch
```

**Way 3 — Just 2 files (smallest download):**

1. Download your `.xgf` from [`firmwares/`](firmwares/) (click the file → `Download raw file` button) or from [releases](https://github.com/9M2PJU/x6100_base_patch/releases).
2. Download the script: `tools/install.sh` (Linux/Mac) or `tools/install.ps1` (Windows) the same way (`Download raw file`).
3. Put both in one folder, e.g. `Downloads/x6100/`. When you run the script, point it at the file (see Step 3 examples with `--file` / `-File`).

Not sure which `.xgf`? See [Compatibility](#compatibility): match the date in the filename to your radio's **System info → BASE** date.

### Step 2 — Open a terminal in that folder

**Windows — easiest, no terminal at all:**

Just double-click `tools\install.bat` in the unzipped folder. A window opens and walks you through it. (It runs `tools\install.ps1` for you and keeps the window open at the end so you can read the result.)

**Windows — PowerShell way:**

1. Press the Windows key, type `PowerShell`, open **Windows PowerShell**.
2. Go to the folder you unzipped, e.g.:
   ```powershell
   cd $HOME\Downloads\x6100_base_patch-1.1.6
   dir
   ```
   You should see `tools` and `firmwares`. If `dir` does not show them, you are in the wrong folder — `cd` again.
3. If Windows blocks the script with *"running scripts is disabled"*, allow it for this window only:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

**macOS:**

1. Press `Cmd + Space`, type `Terminal`, open it.
2. ```bash
   cd ~/Downloads/x6100_base_patch-1.1.6
   ls
   ```
   You should see `tools` and `firmwares`.

**Linux:**

1. Press `Ctrl + Alt + T` to open a terminal.
2. ```bash
   cd ~/Downloads/x6100_base_patch-1.1.6
   ls
   ```

### Step 3 — Run the uploader (copy-paste)

The script is a wizard: it **finds the radio on WiFi by itself**, shows a **numbered firmware menu** (just press Enter for the recommended one), then uploads. You only type something if it asks.

**Linux / macOS:**

```bash
chmod +x tools/install.sh
./tools/install.sh
```

It may ask: pick a firmware number (Enter = recommended), confirm `Upload? [Y/n]` (Enter = Yes). When it asks for a password, type `123` (you will see nothing while typing — that is normal) and press Enter. If auto-find fails, it asks for the IP from the radio's WiFi screen.

Skip the questions (replace IP/filename with yours):

```bash
./tools/install.sh --ip 192.168.1.100 --file firmwares/X6100_BBFW_V1.1.6_230307001_r9.xgf --yes
```

**Windows (if you didn't use `install.bat`):**

```powershell
.\tools\install.ps1
```

Same wizard: auto-find, firmware menu, `Upload? [Y/n]`, password `123` when asked. Skip-the-questions version:

```powershell
.\tools\install.ps1 -Ip 192.168.1.100 -File firmwares\X6100_BBFW_V1.1.6_230307001_r9.xgf -Yes
```

A good upload looks like this: `Found your radio at: ...`, SSH check passes, a progress bar moves, then `ls -lh /usr/firmware/xxxx.xgf` prints the file. If it stops with an error, read it — it usually means wrong WiFi, wrong IP, or wrong password.

What each script is:

| Script | How to run it | Use it on |
|---|---|---|
| `tools/install.sh` | Paste the one-liner, or run from Terminal | Linux / macOS |
| `tools/install.bat` | Double-click | Windows 10 / 11 (easiest) |
| `tools/install.ps1` | Paste the one-liner, or run from PowerShell | Windows 10 / 11 |

Both do the same 5 things: (1) pick the `.xgf`, (2) ask/connect to the radio IP, (3) test SSH to `/usr/firmware`, (4) copy the file with `scp`, (5) verify and show the on-radio steps. They never flash by themselves.

<details>
<summary><b>All options (you rarely need these)</b></summary>

```bash
./tools/install.sh --help
# --ip IP, --file PATH, --user (default root), --port (default 22),
# --dest (default /usr/firmware), --no-scan (skip auto-find),
# --list (show firmwares, exit), --yes (skip confirmation)
```

```powershell
.\tools\install.ps1 -Help
# -Ip, -File, -User, -Port, -Dest, -NoScan, -List, -Yes
```

Missing `scp`/`ssh`? Linux: `sudo apt install openssh-client`. macOS: preinstalled (or `brew install openssh`). Windows: Settings → Apps → Optional features → OpenSSH Client.

</details>

### Step 4 — Finish on the radio (flash it)

- [ ] System settings → Firmware upgrade → choose the uploaded `.xgf` → Update
- [ ] Wait, reboot → System info → BASE version ends in `rN` (e.g. `r13`)

If the file is not listed, it landed in the wrong folder. Re-run the script (it always uses `/usr/firmware`) or check with `ssh root@<ip> "ls -lh /usr/firmware"`.

---

## Option B — Manual install (WinSCP / FileZilla / `scp`)

1. Download a `.xgf` from [`firmwares/`](firmwares/) or [releases](https://github.com/9M2PJU/x6100_base_patch/releases).
2. Boot stock firmware (no SD card).
3. Connect radio to WiFi.
4. Copy file to radio with SCP/SFTP:
   - Host: radio IP, user `root`, password `123`, target `/usr/firmware`
   - GUI: WinSCP (SCP mode) / FileZilla, or CLI: `scp fw.xgf root@<ip>:/usr/firmware/`
5. External power on.
6. System settings → Firmware upgrade → pick file → Update.
7. Verify BASE shows `rN` suffix.

### Videos

**WiFi + copy files (same flow, just copy instead of editing):**

[![WiFi and file copy](https://img.youtube.com/vi/9oviNzXT-v8/hqdefault.jpg)](https://www.youtube.com/watch?v=9oviNzXT-v8)

**TX level calibration (required after patching):**

[![TX calibration](https://img.youtube.com/vi/zoN6uAewPK0/hqdefault.jpg)](https://www.youtube.com/watch?v=zoN6uAewPK0)

**Unwanted RX after TX fix demo (r7):**

[![RX after TX fix](https://img.youtube.com/vi/ljKug5yumMA/hqdefault.jpg)](https://www.youtube.com/watch?v=ljKug5yumMA)

---

## After flashing — TX calibration

Patched levels differ from stock, so calibrate once:

1. Dummy load / power meter on, band 20 m (or as in video).
2. R1CBU: `TX codec gain` (older name `Output gain`) → adjust for **10 W**.
3. Other bands low power or high ALC → tweak `Band output gain corr` per band.
4. Full walkthrough in the calibration video above.

---

## Troubleshooting

<details>
<summary><b>Radio not listed in upgrade menu</b></summary>

File is in the wrong folder. It must be `/usr/firmware/xxx.xgf`, not `/root/`. Re-`scp` with the full dest path and `ls -lh /usr/firmware` over SSH.

</details>

<details>
<summary><b>Cannot SSH / SCP: timeout / refused</b></summary>

- Same WiFi network for PC and radio?
- Booted without SD card?
- IP changed? Re-check radio WiFi screen.
- Password `123` fails? You changed it before — use the new one.

</details>

<details>
<summary><b>Wrong `.xgf` for my BASE date?</b></summary>

Flashing a `221112001` file on a `230307001` radio (or reverse) will fail / misbehave. Match the date in the filename to System info → BASE date.

</details>

<details>
<summary><b>Low TX power / high ALC after flash</b></summary>

Expected — do the TX calibration section above. Start with `TX codec gain`, then per-band corr.

</details>

<details>
<summary><b>Back to stock?</b></summary>

Flash the stock `.xgf`/`.img` from Xiegu the same way. This patch only replaces BASE DSP, settings stay in MAIN.

</details>

---

## Changelog

### r13:
* Battery % from voltage LUT in flow data
* Fix AIC PLL setup for 100.000 kHz, DSP optimisations

### r12:
* CESSB (controlled-envelope SSB, configurable via R1CBU)
* CW peak filter + Q control
* Louder BASE→MAIN audio path, IN_3 routing for play/record

### r11:
* VOX (gain / anti-VOX / delay) + PTT/ATU handling
* Move ADC DC-blocker into AIC3204
* SSB RX IQ filter widened to 5000 Hz, NR click fixes

### r10:
* Spectral noise reduction (NR) + level/slope control, NaN guards
* Placed before AGC, survives TX, reset on boot

### r9:
* Fixed AGC on CW
* Updated filters (less ripple/ringing, wider transition)
* TX bandpass filter control (default 160–3000 Hz)

### r8:
* IF shift (RX/TX)
* `fft_span` zoom + `bf16` flow format
* Rewritten FM mod/demod + pre/de-emphasis
* DAC gain control, new decim/interp filters

### r7:
* Fix ghost RX for seconds after TX ([demo](https://www.youtube.com/watch?v=ljKug5yumMA))

### r6:
* Fix SWR scan values
* RX IQ balancing (kills AM hum/distortion)

### r4:
* ADC/DAC gain offsets per HW revision (R1CBU `Output gain` / `TX codec gain`)

### r3:
* Adaptive notch (ANF, R1CBU ≥ v0.30.0), output gain, threshold/makeup fix, CW level

### r2:
* FM squelch, AM/FM DC removal, fewer mode-change clicks, comp ratio 2:1 default + on/off

### r1:
* TX compressor + noise gate (not DATA/CW), 10× FM depth, fixed AM TX + soft limiter, true power control, TX HPF 160 Hz

---

## For developers

Binary patch, not full FW rebuild. `patch.py` splices new code into stock bins:

```bash
# addresses in patch.py + asm/helper.s + Core/Inc/offsets.h must match OEM md5
python3 patch.py <oem.bin>   # -> <oem>_rN.bin (actually .xgf container)
```

* `asm/helper.s` — trampolines (`insert_to_*` + `*_wrapper`)
* `Core/Src/` — `compressor`, `modulations`, `anf`, `noise_reduction`, `noise_blanker`, `if_shift`, `vox`, `cw_peak`, `cessb`, `aic3204`, `comm` (I2C regs + spectrum `flow`)
* `Core/Inc/comm.h` — hijacked I2C regs `12,15,18,19,22-25,35,36,38,44-47`
* Toolchain `arm-none-eabi-gcc`, `cmake` presets in `CMakePresets.json`

Hacking loop (from original notes): update `.text` padding in `stm32f427zgtx_flash.ld` → build → fix `asm/helper.s` → update `patch.py` addresses → run `patch.py`.

## Links

* Releases (this fork): https://github.com/9M2PJU/x6100_base_patch/releases
* Upstream: https://github.com/gdyuldin/x6100_base_patch/releases
* R1CBU GUI (exposes new sliders): search `R1CBU X6100` — needed for comp/ANF/NR/NB/IF-shift UI
