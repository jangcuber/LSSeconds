# LSSeconds — iOS 17 / RootHide fork

This is an unofficial fork of [CrazyMind90/LSSeconds](https://github.com/crazymind90/LSSeconds), based on upstream commit [`80ae3fb`](https://github.com/crazymind90/LSSeconds/commit/80ae3fb496cf0b5fa766fa9306fb65b022ff433a).

The fork keeps the original tweak identity (`com.cm90.lsseconds`) and adds an iOS 17/18 implementation and a Preferences bundle. It has been confirmed working on iOS 17 and iOS 18.

## Version 0.0.5

- Positions the replacement clock from the native clock view instead of fixed screen coordinates, preventing overlap with the date and adapting to system layout changes.
- Preserves the wallpaper depth effect for the large hour/minute clock.
- Adds an off-by-default option to keep seconds and AM/PM above wallpaper depth effects.
- Keeps the native charging presentation visible above the clock.

## Changes in this fork

- Adds seconds to iOS 17 status-bar time views while retaining the legacy status-bar path.
- Replaces only the lock-screen clock; the system date, subtitle, and complications remain untouched.
- Prevents duplicate custom clocks on the lock screen.
- Adds a status-bar-only toggle for hiding AM/PM.
- Intentionally pauses and hides seconds during AOD, then resynchronizes on wake.
- Adds global, lock-screen, status-bar, and AM/PM settings with a respring action.
- Adds a lock-screen depth-effect visibility option for seconds and AM/PM.
- Restores this fork's `0.0.4` per-view status-bar timer behavior. No DoubleTapToLock compatibility claim is made.

## Compatibility

| Environment | Status |
| --- | --- |
| iOS 17–18 | Confirmed working |
| iOS 17.3.1 + RootHide | Tested |
| Rootless jailbreak | Package build, layout, and runtime confirmed |
| iOS 15–16 | Legacy hooks retained; not revalidated |

The tweak injects only into SpringBoard and uses private classes whose behavior may vary between iOS builds. PreferenceLoader is required for the Settings pane.

## Packages

Release assets use Theos architecture names:

- `iphoneos-arm64e`: RootHide package
- `iphoneos-arm64`: rootless package (`/var/jb` layout)

Install the package appropriate for the jailbreak environment, then respring. AOD seconds are intentionally disabled.

## Build

[Theos](https://theos.dev/) and an iOS 14.5 SDK are expected. Use a RootHide-capable Theos installation for the RootHide build.

```sh
# RootHide (the default scheme)
THEOS=/path/to/roothide-theos make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide

# Rootless
THEOS=/path/to/theos make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

Packages are written to `packages/`.

## Credits and license status

Original project and code: [@CrazyMind90](https://github.com/crazymind90).

The upstream repository does not provide a license. This fork does not claim ownership of upstream code, and all upstream rights remain with the original author. Do not assume that the repository grants a general-purpose redistribution or relicensing permission.
