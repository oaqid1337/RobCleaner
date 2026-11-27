# Changelog

Все заметные изменения проекта.

## [1.0.0] - 2026-11-28

Первый публичный релиз.

### Добавлено

- Русская версия скрипта с корректными командами PowerShell.
- Параметры `-WhatIf`, `-Force`, `-IncludeShared`, `-Confirm`.
- Разделение игровых и общих путей.
- Проверка ОС и прав администратора.
- Итоговый отчёт и коды выхода.
- Интеграционный тест в `tests/Test-RobCleaner.ps1` (14 проверок).
- Документация: `README.md`, `README.en.md`, `FAQ.md`, `CHANGELOG.md`.
- Файлы сообщества: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `AUTHORS.md`, `ROADMAP.md`.
- Шаблоны GitHub: bug report, feature request, pull request.
- CI: тест на push и pull request, релизный workflow по тегу `v*`.
- Dependabot для GitHub Actions.
- `.editorconfig`, `.gitattributes`, `PSScriptAnalyzerSettings.psd1`.

### Изменено

- Базы DevToDev определяются по имени файла или пути (`devtodev`, `dtd`, `analytics`), а не по любому расширению `.db`/`.sqlite`.
- Тест дополнительно проверяет, что локальное сохранение `savegame.db` остаётся на месте.
- README дополнен структурой репозитория и ссылками на документацию.

### Исправлено

- Исправлены имена команд и свойств после машинного перевода.
- Убрана заглушка Steam Cloud.
- Удаление общих путей вынесено за `-IncludeShared`.
- Использованы `-LiteralPath` и `Join-Path` для безопасной работы с путями.

### Безопасность

- Скрипт не подменяет HWID и не обходит блокировки.
- Общие пути не удаляются без явного `-IncludeShared`.
- Нет сетевых запросов, бинарников и обфускации.

### Основа

- [nettlebyte/TraceCleaner](https://github.com/nettlebyte/TraceCleaner).
