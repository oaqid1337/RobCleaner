## Что изменено

<!-- Кратко опишите суть изменений. -->

## Тип изменения

- [ ] Исправление ошибки
- [ ] Новая функция
- [ ] Документация
- [ ] Тесты / CI
- [ ] Рефакторинг без изменения поведения

## Чек-лист

- [ ] `tests/Test-RobCleaner.ps1` проходит
- [ ] `RobCleaner.ps1 -WhatIf` не удаляет реальные данные
- [ ] Новые удаляемые пути описаны в README (RU и EN)
- [ ] Общие пути удаляются только с `-IncludeShared`
- [ ] Новое поведение покрыто тестом
- [ ] `CHANGELOG.md` обновлён
- [ ] Нет сетевых запросов, бинарников и обфускации
- [ ] Нет подмены HWID и обхода блокировок
- [ ] `.ps1` сохранён как UTF-8 с BOM и CRLF
- [ ] Совместимость с Windows PowerShell 5.1 сохранена

## Как проверялось

<!-- Команды, окружение, результаты. -->

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-RobCleaner.ps1
powershell -ExecutionPolicy Bypass -File .\RobCleaner.ps1 -WhatIf
```

## Связанные issue

<!-- Closes #123 -->
