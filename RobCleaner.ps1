#Requires -Version 5.1
<#
.SYNOPSIS
    Очистка локальных следов идентификации игры Rob Run (Kefir).

.DESCRIPTION
    Удаляет локальные данные, которые игра и её SDK используют для
    запоминания идентификатора устройства:
      - Unity PlayerPrefs в реестре;
      - локальное хранилище Epic Online Services (EOS SDK);
      - базы DevToDev Analytics;
      - файлы Sentry Crash Reporter;
      - игровые логи, кэш и временные файлы.

    Скрипт НЕ подменяет HWID и НЕ обходит блокировки. Он только удаляет
    старые локальные следы, чтобы игра сгенерировала новые идентификаторы
    при следующем запуске.

.PARAMETER Force
    Не спрашивать подтверждение перед запуском. Не отключает -Confirm.

.PARAMETER IncludeShared
    Дополнительно удалять общие пути, которые используются другими
    программами:
      HKCU:\Software\Unity\UnityGraphicsQuality
      %LOCALAPPDATA%\EpicGamesLauncher
      %LOCALAPPDATA%\Sentry
      %LOCALAPPDATA%\Unity\Analytics
    По умолчанию эти пути не трогаются.

.EXAMPLE
    .\RobCleaner.ps1 -WhatIf
    Показать, что будет удалено, ничего не удаляя.

.EXAMPLE
    .\RobCleaner.ps1
    Запустить очистку с подтверждением.

.EXAMPLE
    .\RobCleaner.ps1 -Force -IncludeShared
    Запустить без подтверждения, включая общие пути.

.NOTES
    Требуется Windows и PowerShell 5.1+.
    Удаление выполняется без корзины. Сделайте резервную копию.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force,
    [switch]$IncludeShared
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

trap {
    Write-Host ""
    Write-Host "Критическая ошибка: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.InvocationInfo -and $_.InvocationInfo.ScriptLineNumber) {
        Write-Host "Строка: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
    }
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected) {
        Read-Host "Нажмите Enter, чтобы выйти"
    }
    exit 1
}

if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
    Write-Host "Скрипт предназначен только для Windows." -ForegroundColor Red
    exit 1
}

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$userProfile  = [Environment]::GetFolderPath('UserProfile')
$gameFolder   = Join-Path $userProfile 'AppData\LocalLow\Kefir\Rob Run'

if (-not $localAppData -or -not $userProfile) {
    throw "Не удалось определить пути пользователя."
}

$cleaned = 0
$failed  = 0
$skipped = 0
$whatIf  = 0

function Remove-Target {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "  [SKIP]    $Description (не найдено)" -ForegroundColor DarkGray
        $script:skipped++
        return
    }

    if ($WhatIfPreference) {
        Write-Host "  [WHATIF]  $Description" -ForegroundColor Cyan
        Write-Host "            $Path" -ForegroundColor DarkGray
        $script:whatIf++
        return
    }

    if (-not $Cmdlet.ShouldProcess($Path, "Удалить: $Description")) {
        $script:skipped++
        return
    }

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Write-Host "  [CLEANED] $Description" -ForegroundColor Green
        Write-Host "            $Path" -ForegroundColor DarkGray
        $script:cleaned++
    }
    catch {
        Write-Host "  [FAILED]  $Description" -ForegroundColor Red
        Write-Host "            $Path" -ForegroundColor DarkGray
        Write-Host "            $($_.Exception.Message)" -ForegroundColor DarkRed
        $script:failed++
    }
}

function Skip-Shared {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    Write-Host "  [SKIP]    $Description" -ForegroundColor DarkGray
    Write-Host "            $Path" -ForegroundColor DarkGray
    Write-Host "            Общий путь, не удалён. Используйте -IncludeShared, чтобы включить." -ForegroundColor DarkGray
    $script:skipped++
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [string]$Note = ''
    )

    Write-Host ""
    Write-Host $Title -ForegroundColor White
    if ($Note) {
        Write-Host "     $Note" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RobCleaner for Rob Run v1.0.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Скрипт удаляет локальные следы, которые игра использует" -ForegroundColor Yellow
Write-Host "для запоминания идентификатора устройства." -ForegroundColor Yellow
Write-Host "Он НЕ подменяет HWID и НЕ обходит блокировки." -ForegroundColor Yellow
Write-Host ""
Write-Host "Перед запуском закройте игру!" -ForegroundColor Red
Write-Host ""

$confirmRequested = $PSBoundParameters.ContainsKey('Confirm')
if (-not $Force -and -not $WhatIfPreference -and -not $confirmRequested) {
    if ([Console]::IsInputRedirected) {
        Write-Host "Неинтерактивный запуск: используйте -Force для подтверждения." -ForegroundColor Red
        exit 1
    }
    $answer = Read-Host "Продолжить? (y/n)"
    if ($answer -notmatch '^(y|yes|д|да)$') {
        Write-Host "Отменено." -ForegroundColor Gray
        exit 0
    }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Host "Примечание: скрипт запущен без прав администратора." -ForegroundColor Yellow
    Write-Host "HKCU и AppData доступны, но некоторые файлы могут не удалиться." -ForegroundColor Yellow
    Write-Host ""
}

# ------------------------------------------------------------
Write-Section "[1/5] Unity PlayerPrefs (реестр Windows)" "Игра хранит настройки и локальные идентификаторы в реестре Windows."
# ------------------------------------------------------------

Remove-Target -Cmdlet $PSCmdlet -Path 'HKCU:\Software\Kefir\Rob Run' -Description 'Ключ реестра игры (Unity PlayerPrefs)'

if ($IncludeShared) {
    Remove-Target -Cmdlet $PSCmdlet -Path 'HKCU:\Software\Unity\UnityGraphicsQuality' -Description 'Глобальные настройки качества графики Unity'
} else {
    Skip-Shared -Path 'HKCU:\Software\Unity\UnityGraphicsQuality' -Description 'Глобальные настройки качества графики Unity'
}

# ------------------------------------------------------------
Write-Section "[2/5] EOS SDK (Epic Online Services)" "Хранит уникальный токен устройства. Общий для игр с EOS."
# ------------------------------------------------------------

Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'EpicOnlineServices') -Description 'Локальное хранилище EOS SDK'
Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'Epic Online Services') -Description 'Альтернативный путь EOS SDK'

if ($IncludeShared) {
    Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'EpicGamesLauncher') -Description 'Данные Epic Games Launcher'
} else {
    Skip-Shared -Path (Join-Path $localAppData 'EpicGamesLauncher') -Description 'Данные Epic Games Launcher'
}

# ------------------------------------------------------------
Write-Section "[3/5] DevToDev Analytics" "Базы SQLite с текущими и предыдущими идентификаторами устройства."
# ------------------------------------------------------------

if (Test-Path -LiteralPath $gameFolder) {
    # Удаляются только базы, связанные с DevToDev (по имени файла или пути),
    # чтобы не задеть локальные сохранения игры с расширением .db/.sqlite.
    $dbFiles = @(
        Get-ChildItem -LiteralPath $gameFolder -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Extension -in '.db', '.sqlite', '.sqlite3' -and
                $_.FullName -match '(?i)devtodev|dtd|analytics'
            }
    )
    if ($dbFiles.Count -gt 0) {
        foreach ($f in $dbFiles) {
            Remove-Target -Cmdlet $PSCmdlet -Path $f.FullName -Description "База DevToDev: $($f.Name)"
        }
    } else {
        Write-Host "  [SKIP]    Подходящие базы DevToDev (.db/.sqlite/.sqlite3) не найдены" -ForegroundColor DarkGray
        $skipped++
    }

    $dtdFolders = @(
        Get-ChildItem -LiteralPath $gameFolder -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'devtodev|dtd|analytics' }
    )
    if ($dtdFolders.Count -gt 0) {
        foreach ($f in $dtdFolders) {
            Remove-Target -Cmdlet $PSCmdlet -Path $f.FullName -Description "Папка DevToDev: $($f.Name)"
        }
    } else {
        Write-Host "  [SKIP]    Папки DevToDev не найдены" -ForegroundColor DarkGray
        $skipped++
    }
} else {
    Write-Host "  [SKIP]    Папка игры не найдена: $gameFolder" -ForegroundColor DarkGray
    $skipped++
}

# ------------------------------------------------------------
Write-Section "[4/5] Sentry Crash Reporter" "Постоянный installation ID и данные crash reporter."
# ------------------------------------------------------------

if (Test-Path -LiteralPath $gameFolder) {
    $sentryItems = @(
        Get-ChildItem -LiteralPath $gameFolder -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -eq '.installation' -or
                $_.Name -like '*.installation' -or
                $_.Name -like 'sentry*'
            } |
            Sort-Object { $_.FullName.Length } -Descending
    )
    if ($sentryItems.Count -gt 0) {
        foreach ($f in $sentryItems) {
            Remove-Target -Cmdlet $PSCmdlet -Path $f.FullName -Description "Sentry: $($f.Name)"
        }
    } else {
        Write-Host "  [SKIP]    Файлы Sentry не найдены" -ForegroundColor DarkGray
        $skipped++
    }
}

if ($IncludeShared) {
    Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'Sentry') -Description 'Общая папка Sentry'
} else {
    Skip-Shared -Path (Join-Path $localAppData 'Sentry') -Description 'Общая папка Sentry'
}

# ------------------------------------------------------------
Write-Section "[5/5] Кэш, логи и временные файлы" "Логи, crash dumps и временные данные игры."
# ------------------------------------------------------------

Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'Temp\Kefir') -Description 'Временные данные Kefir'

if (Test-Path -LiteralPath $gameFolder) {
    $logFiles = @(
        Get-ChildItem -LiteralPath $gameFolder -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '\.(log|log\.bak)$' -or
                $_.Name -in 'Player.log', 'Player-prev.log', 'output_log.txt'
            }
    )
    if ($logFiles.Count -gt 0) {
        foreach ($f in $logFiles) {
            Remove-Target -Cmdlet $PSCmdlet -Path $f.FullName -Description "Лог: $($f.Name)"
        }
    } else {
        Write-Host "  [SKIP]    Логи не найдены" -ForegroundColor DarkGray
        $skipped++
    }
} else {
    Write-Host "  [SKIP]    Папка игры не найдена: $gameFolder" -ForegroundColor DarkGray
    $skipped++
}

if ($IncludeShared) {
    Remove-Target -Cmdlet $PSCmdlet -Path (Join-Path $localAppData 'Unity\Analytics') -Description 'Общий кэш Unity Analytics'
} else {
    Skip-Shared -Path (Join-Path $localAppData 'Unity\Analytics') -Description 'Общий кэш Unity Analytics'
}

# ------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  РЕЗУЛЬТАТЫ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($WhatIfPreference) {
    Write-Host "  Будет удалено: $whatIf" -ForegroundColor Cyan
} else {
    Write-Host "  Очищено:       $cleaned" -ForegroundColor Green
}
Write-Host "  Пропущено:     $skipped" -ForegroundColor Gray
if ($failed -gt 0) {
    Write-Host "  Ошибок:        $failed" -ForegroundColor Red
} else {
    Write-Host "  Ошибок:        $failed" -ForegroundColor Gray
}
Write-Host ""

if ($failed -gt 0) {
    Write-Host "Некоторые элементы не удалось удалить." -ForegroundColor Yellow
    Write-Host "Попробуйте запустить PowerShell от имени администратора." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if (-not $WhatIfPreference) {
    Write-Host "Готово. Перед следующим запуском игры закройте её." -ForegroundColor Green
}

exit 0
