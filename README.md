# RobCleaner для Rob Run

PowerShell-скрипт для Windows, который удаляет локальные следы идентификации игры **Rob Run** (Kefir): настройки Unity, токен EOS SDK, базы DevToDev, файлы Sentry, логи и временный кэш.

> **Важно:** скрипт **не подменяет HWID** и **не обходит блокировки**. Он только удаляет старые локальные данные, чтобы игра могла сгенерировать новые идентификаторы при следующем запуске.

## Содержание

- [Возможности](#возможности)
- [Требования](#требования)
- [Использование](#использование)
- [Параметры](#параметры)
- [Важно](#важно)
- [Проверка кода](#проверка-кода)
- [Тесты](#тесты)
- [Структура](#структура)
- [Документация](#документация)
- [Участие](#участие)
- [Безопасность](#безопасность)
- [Лицензия](#лицензия)
- [Дисклеймер](#дисклеймер)

## Возможности

| Категория | Что удаляется | По умолчанию |
|---|---|---|
| Unity PlayerPrefs | `HKCU:\Software\Kefir\Rob Run` | да |
| Unity (общее) | `HKCU:\Software\Unity\UnityGraphicsQuality` | только с `-IncludeShared` |
| EOS SDK | `%LOCALAPPDATA%\EpicOnlineServices`, `%LOCALAPPDATA%\Epic Online Services` | да |
| Epic Games Launcher | `%LOCALAPPDATA%\EpicGamesLauncher` | только с `-IncludeShared` |
| DevToDev | `*.db`, `*.sqlite`, `*.sqlite3`, если имя файла или путь содержит `devtodev`, `dtd` или `analytics`; папки `devtodev`/`dtd`/`analytics` в папке игры | да |
| Sentry | файлы и папки `.installation`, `*.installation`, `sentry*` в папке игры | да |
| Sentry (общее) | `%LOCALAPPDATA%\Sentry` | только с `-IncludeShared` |
| Кэш и логи | `%LOCALAPPDATA%\Temp\Kefir`, логи игры | да |
| Unity Analytics | `%LOCALAPPDATA%\Unity\Analytics` | только с `-IncludeShared` |
| Steam Cloud | не трогается | — |

## Требования

- Windows 10/11
- PowerShell 5.1 или новее
- Права администратора не обязательны, но рекомендуются
- Игра и лаунчер должны быть закрыты

## Использование

Сначала посмотрите, что будет удалено:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -WhatIf
```

Затем запустите очистку:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1
```

Без общего подтверждения:

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -Force
```

С общими путями (затронет другие программы):

```powershell
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -IncludeShared
```

## Параметры

| Параметр | Описание |
|---|---|
| `-WhatIf` | Показать, что будет удалено, ничего не удаляя |
| `-Force` | Не спрашивать общее подтверждение перед запуском |
| `-IncludeShared` | Удалить также общие пути Unity/Epic/Sentry |
| `-Confirm` | Запрашивать подтверждение для каждого элемента |

## Важно

- Удаление выполняется **без корзины**. Сделайте резервную копию папки игры:

  ```text
  %USERPROFILE%\AppData\LocalLow\Kefir\Rob Run
  ```

  и, при необходимости, точку восстановления Windows.
- `-IncludeShared` затрагивает данные, которые могут использовать другие программы:
  - `UnityGraphicsQuality` — качество графики во всех Unity-играх;
  - `EpicGamesLauncher` — кэш и настройки лаунчера Epic Games;
  - `Sentry` — общая папка Sentry;
  - `Unity\Analytics` — общий кэш Unity Analytics.
- EOS SDK (`EpicOnlineServices`) общий для всех игр с Epic Online Services. Его удаление может сбросить токены других EOS-игр.
- Скрипт не работает с Steam Cloud. Локальные сохранения не входят в цели, но базы с `devtodev`/`dtd`/`analytics` в имени или пути будут удалены — поэтому резервная копия обязательна.
- Скрипт не отправляет данные в сеть и не скачивает файлы.

## Проверка кода

Скрипт — обычный текстовый `.ps1` без бинарников и обфускации. Перед запуском можно открыть его в редакторе или проверить:

```powershell
Get-Content .\RobCleaner.ps1
```

Хеш файла:

```powershell
Get-FileHash .\RobCleaner.ps1 -Algorithm SHA256
```

Сравните его с SHA-256, указанным в описании релиза.

## Тесты

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-RobCleaner.ps1
```

Тест создаёт временную песочницу и тестовые ключи реестра, подменяет пути в копии скрипта и проверяет, что:

- игровые данные удаляются;
- локальное сохранение `savegame.db` остаётся;
- общие пути по умолчанию не трогаются.

Реальные данные игры не используются. Тот же тест запускается в GitHub Actions при push и pull request.

## Структура

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

## Документация

- [FAQ.md](FAQ.md) — частые вопросы: HWID, баны, сохранения, общие пути.
- [CONTRIBUTING.md](CONTRIBUTING.md) — как предложить изменение и правила кода.
- [SECURITY.md](SECURITY.md) — как приватно сообщить об уязвимости.
- [SUPPORT.md](SUPPORT.md) — куда обратиться за помощью.
- [CHANGELOG.md](CHANGELOG.md) — история изменений.
- [ROADMAP.md](ROADMAP.md) — планы развития.
- [AUTHORS.md](AUTHORS.md) — авторы и происхождение проекта.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — правила поведения в сообществе.

## Участие

Pull request и issue приветствуются. Перед изменением кода прочитайте [CONTRIBUTING.md](CONTRIBUTING.md). Для крупных изменений сначала создайте issue, чтобы обсудить подход.

## Безопасность

Не открывайте публичный issue для уязвимостей. Используйте приватный отчёт GitHub: **Security** → **Advisories** → **Report a vulnerability**. Подробности — в [SECURITY.md](SECURITY.md).

## Лицензия

MIT. Полный текст — в [LICENSE](LICENSE).

## Дисклеймер

Проект предоставлен для образовательных целей и локальной очистки приватности. Автор не несёт ответственности за последствия использования. Использование может нарушать правила игры.
