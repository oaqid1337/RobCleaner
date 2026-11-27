# RobCleaner for Rob Run

A Windows PowerShell script that removes local identity traces left by the game **Rob Run** (Kefir): Unity settings, EOS SDK device token, DevToDev databases, Sentry files, logs, and temporary cache.

> **Important:** this script **does not spoof HWID** and **does not bypass bans**. It only removes old local identity data so the game can generate fresh identifiers on the next launch.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Usage](#usage)
- [Parameters](#parameters)
- [Important](#important)
- [Code review](#code-review)
- [Tests](#tests)
- [Repository layout](#repository-layout)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)
- [Disclaimer](#disclaimer)

## Features

| Category | Target | Default |
|---|---|---|
| Unity PlayerPrefs | `HKCU:\Software\Kefir\Rob Run` | yes |
| Unity (shared) | `HKCU:\Software\Unity\UnityGraphicsQuality` | `-IncludeShared` only |
| EOS SDK | `%LOCALAPPDATA%\EpicOnlineServices`, `%LOCALAPPDATA%\Epic Online Services` | yes |
| Epic Games Launcher | `%LOCALAPPDATA%\EpicGamesLauncher` | `-IncludeShared` only |
| DevToDev | `*.db`, `*.sqlite`, `*.sqlite3` whose file name or path contains `devtodev`, `dtd`, or `analytics`; `devtodev`/`dtd`/`analytics` folders in the game folder | yes |
| Sentry | `.installation`, `*.installation`, `sentry*` files and folders in the game folder | yes |
| Sentry (shared) | `%LOCALAPPDATA%\Sentry` | `-IncludeShared` only |
| Cache and logs | `%LOCALAPPDATA%\Temp\Kefir`, game logs | yes |
| Unity Analytics | `%LOCALAPPDATA%\Unity\Analytics` | `-IncludeShared` only |
| Steam Cloud | not touched | — |

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator rights are not required but recommended
- The game and launcher must be closed

## Usage

Preview first:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -WhatIf
```

Run the cleanup:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1
```

Skip the initial confirmation:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -Force
```

Include shared paths (affects other applications):

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -IncludeShared
```

## Parameters

| Parameter | Description |
|---|---|
| `-WhatIf` | Show what would be deleted without deleting anything |
| `-Force` | Skip the initial confirmation prompt |
| `-IncludeShared` | Also delete shared Unity/Epic/Sentry paths |
| `-Confirm` | Prompt for each item |

## Important

- Deletion is permanent (no Recycle Bin). Back up the game folder first:

  ```text
  %USERPROFILE%\AppData\LocalLow\Kefir\Rob Run
  ```

  Create a Windows restore point if needed.
- `-IncludeShared` touches data that may be used by other applications:
  - `UnityGraphicsQuality` — graphics quality for all Unity games;
  - `EpicGamesLauncher` — Epic Games Launcher cache and settings;
  - `Sentry` — shared Sentry folder;
  - `Unity\Analytics` — shared Unity Analytics cache.
- EOS SDK (`EpicOnlineServices`) is shared by all Epic Online Services games. Removing it may reset tokens for other EOS games.
- The script does not touch Steam Cloud. Local saves are not targets, but databases with `devtodev`/`dtd`/`analytics` in the name or path will be deleted — a backup is mandatory.
- The script does not send data over the network and does not download files.

## Code review

The script is a plain-text `.ps1` with no binaries or obfuscation. You can inspect it before running:

```powershell
Get-Content .\RobCleaner.ps1
```

File hash:

```powershell
Get-FileHash .\RobCleaner.ps1 -Algorithm SHA256
```

Compare it with the SHA-256 published in the release notes.

## Tests

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-RobCleaner.ps1
```

The test creates a temporary sandbox and test registry keys, replaces paths in a copy of the script, and verifies that:

- game data is removed;
- the local `savegame.db` file is kept;
- shared paths are not touched by default.

Real game data is not used. The same test runs in GitHub Actions on push and pull request.

## Repository layout

```text
RobCleaner/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── workflows/
│   │   ├── release.yml
│   │   └── test.yml
│   ├── dependabot.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── tests/
│   └── Test-RobCleaner.ps1
├── RobCleaner.ps1
├── README.md
├── README.en.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── SUPPORT.md
├── FAQ.md
├── AUTHORS.md
├── ROADMAP.md
├── LICENSE
├── PSScriptAnalyzerSettings.psd1
├── .editorconfig
├── .gitattributes
└── .gitignore
```

## Documentation

- [FAQ.md](FAQ.md) — common questions about HWID, bans, saves, and shared paths (Russian).
- [CONTRIBUTING.md](CONTRIBUTING.md) — contribution process and coding rules (Russian).
- [SECURITY.md](SECURITY.md) — private vulnerability reporting.
- [SUPPORT.md](SUPPORT.md) — where to get help (Russian).
- [CHANGELOG.md](CHANGELOG.md) — change history.
- [ROADMAP.md](ROADMAP.md) — planned improvements (Russian).
- [AUTHORS.md](AUTHORS.md) — authors and project origin.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — community standards (Russian).

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing code. For larger changes, open an issue first to discuss the approach.

## Security

Do not open a public issue for vulnerabilities. Use GitHub private reporting: **Security** → **Advisories** → **Report a vulnerability**. See [SECURITY.md](SECURITY.md) for details.

## License

MIT. See [LICENSE](LICENSE) for the full text.

## Disclaimer

Provided for educational and local privacy-cleanup purposes only. The author is not responsible for any consequences. Use may violate the game's terms of service.
