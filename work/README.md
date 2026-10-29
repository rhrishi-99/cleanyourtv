# Our TV: Xiaomi MiTV-AXSO0 (Mi TV 4A Pro / 4C Pro), cleaned up on 29 October 2026

Android TV 9, firmware PI.6036. Everything below was done over ADB from this PC, from the
`cleanyourtv` folder. Nothing was uninstalled or rooted: every change can be undone.

## What was changed

- **27 apps disabled** (list and reasons in [`debloat.txt`](debloat.txt)): Xiaomi and Google telemetry,
  PatchWall and the sponsored rows, the partner auto-installer, TV Manager, the Handbook, Mi Music,
  Mi Gallery, Play Games, Play Movies, Camera, Gallery, Print spooler, SMS push, **Google Assistant**,
  **Xiaomi firmware updates**, and **Airtel Xstream, SonyLIV, ZEE5, Sun NXT**.
- **Kept on purpose:** Netflix, Prime Video, YouTube, YouTube Music, JioHotstar, Spotify, Chromecast,
  Mi Cast / Miracast screen mirroring, the TV app and HDMI/AV/tuner inputs, Media Player, Play Store,
  the keyboard, the screensaver and TV lock.
- **New Home screen** (`com.gathin.tvhome`, built from `launcher/`): a dock with Netflix, JioHotstar,
  YouTube and Prime Video, the other apps in a grid below, Inputs / Wi-Fi / Settings at the top right.
  The stock launcher (`com.google.android.tvlauncher`) is disabled.
- **Ad-blocking DNS:** Private DNS is set to `dns.adguard-dns.com`. It blocks many ad and tracking
  domains, **not** YouTube ads.

## Files

| File | What it is |
|---|---|
| `work/debloat.txt` | The list of disabled apps, used by apply and undo |
| `work/restore.ps1` | Undo everything |
| `work/build-and-install.ps1` | Rebuild the Home screen after a change and put it on the TV |
| `work/theme/config.json` | A starting point for changing the dock or adding a wallpaper without rebuilding |
| `backup/` | Package lists, `getprop` and all settings from before any change, plus a copy of the undo record. On the PC only, never in git: it holds the TV's serial and account details |
| `%USERPROFILE%\.cleanyourtv\recovery-*.json` | The undo record `restore.ps1` replays. On the PC only. Keep it. |

## Before any change: switch ADB back on

Every command here needs ADB on the TV. It was switched off at the end for safety.

1. On the TV: **Settings > Device Preferences > About**, press OK on **Build** 7 times, if Developer
   options are not shown yet.
2. **Settings > Device Preferences > Developer options > USB debugging: on.** On this TV that also opens
   network ADB on port 5555.
3. Find the TV's IP under **Settings > Network & Internet**, and run the
   commands below from a PowerShell window in the `cleanyourtv` folder. Accept the "Allow USB
   debugging?" prompt on the TV the first time.
4. When done, switch USB debugging off again, under **Developer options**.

```powershell
$env:TV_HOST = '<tv ip>'          # the TV's IP
tools\venv\Scripts\python.exe -I tools\tv.py --probe
```

## Re-enable one app

```powershell
tools\venv\Scripts\python.exe -I tools\tv.py 'pm enable com.google.android.katniss'   # Google Assistant
```

Package names are in `work/debloat.txt`. Assistant needs both `com.google.android.katniss` and
`com.google.android.speech.pumpkin`. To check for a firmware update, enable
`com.xiaomi.mitv.updateservice`. To disable an app again:
`tools\venv\Scripts\python.exe -I tools\tv.py 'pm disable-user --user 0 <package>'`.

## Undo everything

```powershell
powershell -ExecutionPolicy Bypass -File work\restore.ps1 -TvHost <tv ip>
```

This turns the 27 apps and the stock launcher back on, gives Home back to the stock launcher and puts
Private DNS back to automatic. Add `-KeepDns` to keep AdGuard, and `-RemoveLauncher` to uninstall the
new Home screen as well. If the TV's IP has changed since 29 October, the script enables the whole list
instead of replaying the record. On this TV that's the same thing, because nothing was disabled
beforehand.

## Change the dock (apps, order, number of slots)

**Option A: edit and rebuild.** Edit `launcher\app\src\main\res\values\config.xml`:

```xml
<string-array name="dock_apps">
    <item>com.netflix.ninja</item>               <!-- Netflix -->
    <item>in.startv.hotstar</item>               <!-- JioHotstar -->
    <item>com.google.android.youtube.tv</item>   <!-- YouTube -->
    <item>com.amazon.amazonvideo.livingroom</item><!-- Prime Video -->
</string-array>
...
<integer name="columns">4</integer>              <!-- dock slots and grid columns: 4, 5, 6 or 7 -->
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File work\build-and-install.ps1 -TvHost <tv ip>
```

Other package names: Spotify `com.spotify.tv.android`, YouTube Music `com.google.android.youtube.tvmusic`,
Play Store `com.android.vending`, Media Player `com.xiaomi.mitv.mediaexplorer`.

**Option B: no rebuild.** Edit `work\theme\config.json` (same keys, same package names), then:

```powershell
powershell -ExecutionPolicy Bypass -File tools\theme.ps1 -TvHost <tv ip> work\theme
```

A pushed theme overrides `config.xml`. If you go back to Option A later, clear it first with
`tools\theme.ps1 -TvHost <tv ip> -Reset`.

## Change the wallpaper

Put a dark 1920x1080 JPEG of about 300 KB or less into `work\theme\` as `wallpaper.jpg`. Set
`"wallpaper": true` in `work\theme\config.json`, then push it with the `tools\theme.ps1` command
above. For a rotating set, use a `wallpapers\` folder instead. `themes\README.md` lists every key,
such as `wallpaper_dim` and `wallpaper_rotation_minutes`. The ready-made themes in `themes\`
(`aurora`, `glass`, `scenes`, ...) can be pushed the same way, but their own `dock_apps` replace yours.
Copy your `dock_apps` into the theme's `config.json` first.

## Private DNS (AdGuard)

Undo on its own:

```powershell
tools\venv\Scripts\python.exe -I tools\tv.py 'settings put global private_dns_mode opportunistic'
```

This TV's own Settings may not show a Private DNS option, so use the command. If an app stops loading,
switch Private DNS off first to rule it out. If the router ever gets Pi-hole, AdGuard Home or a VPN with domain
rules, switch this off: Private DNS bypasses the router's DNS.

## Things that behave differently now

- **Netflix doesn't leave on Back.** That's the Netflix app itself: Back moves around inside it but
  never exits. Press **Home**. JioHotstar and YouTube do exit on Back.
- **Home** always goes to the first dock tile. **Back** out of an app returns to the tile you opened it
  from.
- **The PatchWall button and the mic button do nothing**, because PatchWall and Assistant are off. The
  launcher can remap the PatchWall button (`input_key_keycodes` / `app_keys` with its key helper,
  `-InputKeyService`), but that wasn't wanted.
- **The Wi-Fi pill says "Wi-Fi"**, not the network name. Android 9 only gives the name to apps while
  Location is on, and Location was left off for privacy.
- **Google sign-in prompts have nowhere to show.** The stock launcher's notification panel and
  `com.google.android.tvrecommendations` are off. If Play Store ever says "Authentication is required",
  enable both, open `com.google.android.tvlauncher/.notifications.NotificationsSidePanelActivity` with
  `am start -n`, sign in from the notice, then disable both again.
- **No firmware update checks** until `com.xiaomi.mitv.updateservice` is enabled again.
- The Live TV app is hidden from the grid. Open it from **Inputs > Live TV**, or pick an HDMI port there.

## Rebuilding needs

A portable **JDK 17** in `%LOCALAPPDATA%\cleanyourtv-jdk17` and the **Android SDK**
(platform 34, build-tools 34.0.0) in `%LOCALAPPDATA%\Android\Sdk`, about 2 GB with
Gradle's cache in `%USERPROFILE%\.gradle`. Nothing was added to PATH. If you don't need to rebuild
again, delete those three folders and `%LOCALAPPDATA%\cleanyourtv-dl` to get the
space back. `work\build-and-install.ps1` then needs a JDK 17 to 22 again, via Android Studio or
`JAVA_HOME`.
