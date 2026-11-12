# X6100 BASE firmware installer (Windows, PowerShell 5.1+)
# Copies a .xgf file to the radio via SCP, then prints on-radio steps.
param(
  [string]$Ip = "",
  [string]$File = "",
  [string]$User = "root",
  [int]$Port = 22,
  [string]$Dest = "/usr/firmware",
  [switch]$Yes,
  [switch]$Help
)

$Repo = "9M2PJU/x6100_base_patch"
$FallbackRepo = "gdyuldin/x6100_base_patch"

function Show-ProgressBar($Cur, $Total, $Label) {
  $w = 20
  $f = [int]($Cur * $w / $Total)
  $bar = ("#" * $f).PadRight($w, "-")
  Write-Host ("`r[{0}] {1}/{2} {3}" -f $bar, $Cur, $Total, $Label)
}

function Usage {
  @"
Usage: .\install.ps1 [-Ip 192.168.1.100] [-File path\to\fw.xgf] [-User root] [-Port 22]

Examples:
  .\install.ps1 -Ip 192.168.1.100
  .\install.ps1 -Ip 192.168.1.100 -File firmwares\X6100_BBFW_V1.1.6_230307001_r9.xgf

After upload, on the radio: System settings -> Firmware upgrade -> pick file.
Radio SSH defaults: user 'root', password '123'.
"@
}

if ($Help) { Usage; exit 0 }

if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
  Write-Error "'scp' not found. Install OpenSSH Client: Settings > Apps > Optional features > OpenSSH Client, or: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
  exit 1
}
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
  Write-Error "'ssh' not found. Install OpenSSH Client (see above)."
  exit 1
}

Show-ProgressBar 1 4 "locating firmware"

if ([string]::IsNullOrWhiteSpace($File)) {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $repoRoot = Split-Path -Parent $scriptDir
  $latest = Get-ChildItem (Join-Path $repoRoot "firmwares\*.xgf") -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($latest) {
    $File = $latest.FullName
  } else {
    Write-Host "No local .xgf found. Downloading latest release..."
    $url = $null
    foreach ($r in @($Repo, $FallbackRepo)) {
      try {
        $rel = Invoke-RestMethod "https://api.github.com/repos/$r/releases/latest" -TimeoutSec 20
        $asset = $rel.assets | Where-Object { $_.name -like "*.xgf" } | Select-Object -First 1
        if ($asset) { $url = $asset.browser_download_url; break }
      } catch { }
    }
    if (-not $url) { Write-Error "Download failed. Pass -File PATH manually."; exit 1 }
    $tmp = Join-Path $env:TEMP ([System.IO.Path]::GetFileName($url))
    Write-Host "Downloading: $url"
    Invoke-WebRequest $url -OutFile $tmp
    $File = $tmp
  }
}

if (-not (Test-Path $File)) { Write-Error "File not found: $File"; exit 1 }
if ($File -notlike "*.xgf") { Write-Warning "$File does not end in .xgf - continuing anyway." }

if ([string]::IsNullOrWhiteSpace($Ip)) {
  $Ip = Read-Host "Radio IP (see radio WiFi settings, e.g. 192.168.1.100)"
}
if ([string]::IsNullOrWhiteSpace($Ip)) { Write-Error "No IP given."; exit 1 }

$fname = Split-Path $File -Leaf
Write-Host ""
Write-Host "Radio: $User@$Ip`:$Port"
Write-Host "File:  $File"
Write-Host "Dest:  $Dest/$fname"
if (-not $Yes) {
  $ans = Read-Host "Upload? [Y/n]"
  if ($ans -match '^[nN]') { Write-Host "Aborted."; exit 0 }
}

Show-ProgressBar 2 4 "checking SSH"
ssh -p $Port -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$User@$Ip" "mkdir -p $Dest && ls -ld $Dest"
if ($LASTEXITCODE -ne 0) {
  Write-Error @"
Cannot SSH to $User@$Ip. Check:
  - radio and PC on same WiFi, radio booted WITHOUT SD card (OEM fw)
  - IP correct (radio WiFi settings screen)
  - password is '123' unless you changed it (you will be prompted)
"@
  exit 1
}

Show-ProgressBar 3 4 "uploading via SCP"
scp -P $Port $File "$User@${Ip}:$Dest/$fname"
if ($LASTEXITCODE -ne 0) { Write-Error "SCP upload failed."; exit 1 }

Show-ProgressBar 4 4 "verifying"
ssh -p $Port "$User@$Ip" "ls -lh $Dest/$fname"

@"

Done. Now on the radio:
  1. Connect external power supply (do NOT run on battery for flashing).
  2. System settings -> Firmware upgrade -> choose $fname -> Update.
  3. Reboot, then check System info: BASE version should end in rX (e.g. r13).
  4. If TX power is off, calibrate: see README "TX calibration" section.

If the radio does not list the file, confirm it landed in $Dest (not /root).
"@
