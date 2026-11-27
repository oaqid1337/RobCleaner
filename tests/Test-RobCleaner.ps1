#Requires -Version 5.1
<#
.SYNOPSIS
    Интеграционный тест RobCleaner.ps1 в изолированной песочнице.

.DESCRIPTION
    Создаёт временную папку и тестовые ключи реестра, подменяет пути
    в копии скрипта и проверяет, что:
      - игровые данные удаляются;
      - общие пути (Epic Games Launcher, Sentry, Unity Analytics,
        UnityGraphicsQuality) по умолчанию не трогаются.

    Реальные данные игры и реестра не используются.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tests\Test-RobCleaner.ps1
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot     = Split-Path -Parent $PSScriptRoot
$sourceScript = Join-Path $repoRoot 'RobCleaner.ps1'
$sandbox      = Join-Path $env:TEMP "RobCleanerTest_$PID"
$testRegRoot  = "HKCU:\Software\RobCleanerTest_$PID"
$testGameKey  = "$testRegRoot\Rob Run"
$testSharedKey = "$testRegRoot\UnityGraphicsQuality"

if (-not (Test-Path -LiteralPath $sourceScript)) {
    throw "Не найден скрипт: $sourceScript"
}

function New-TestFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Content = 'test'
    )
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding ASCII
}

if (Test-Path -LiteralPath $sandbox) {
    Remove-Item -LiteralPath $sandbox -Recurse -Force
}
$localLow = Join-Path $sandbox 'AppData\LocalLow\Kefir\Rob Run'
$local    = Join-Path $sandbox 'AppData\Local'

New-TestFile (Join-Path $localLow 'devtodev\device.db')
New-TestFile (Join-Path $localLow 'analytics.sqlite')
New-TestFile (Join-Path $localLow 'savegame.db')
New-TestFile (Join-Path $localLow 'Sentry\ABC\.installation')
New-TestFile (Join-Path $localLow 'Player.log')
New-TestFile (Join-Path $localLow 'output_log.txt')
New-TestFile (Join-Path $local 'Temp\Kefir\crash.dmp')
New-TestFile (Join-Path $local 'EpicOnlineServices\token.bin')
New-TestFile (Join-Path $local 'EpicGamesLauncher\cache.bin')
New-TestFile (Join-Path $local 'Sentry\global.bin')
New-TestFile (Join-Path $local 'Unity\Analytics\cache.bin')

New-Item -Path $testGameKey -Force | Out-Null
New-ItemProperty -Path $testGameKey -Name Test -Value 1 -Force | Out-Null
New-Item -Path $testSharedKey -Force | Out-Null
New-ItemProperty -Path $testSharedKey -Name Test -Value 1 -Force | Out-Null

$text = [System.IO.File]::ReadAllText($sourceScript, [System.Text.Encoding]::UTF8)
$text = $text.Replace("[Environment]::GetFolderPath('LocalApplicationData')", "'" + (Join-Path $sandbox 'AppData\Local') + "'")
$text = $text.Replace("[Environment]::GetFolderPath('UserProfile')", "'" + $sandbox + "'")
$text = $text.Replace("'HKCU:\Software\Kefir\Rob Run'", "'" + $testGameKey + "'")
$text = $text.Replace("'HKCU:\Software\Unity\UnityGraphicsQuality'", "'" + $testSharedKey + "'")
$testScript = Join-Path $sandbox 'RobCleaner_test.ps1'
[System.IO.File]::WriteAllText($testScript, $text, (New-Object System.Text.UTF8Encoding($true)))

"--- Запуск RobCleaner.ps1 -Force (общие пути отключены) ---"
$out  = & $testScript -Force *>&1
$code = $LASTEXITCODE
"Exit code: $code"

$checks = [ordered]@{
    'Ключ реестра игры удалён'        = -not (Test-Path -LiteralPath $testGameKey)
    'Общий ключ Unity сохранён'       = (Test-Path -LiteralPath $testSharedKey)
    'Папка игры осталась'             = (Test-Path -LiteralPath $localLow)
    'Папка DevToDev удалена'          = -not (Test-Path -LiteralPath (Join-Path $localLow 'devtodev'))
    'База DevToDev удалена'           = -not (Test-Path -LiteralPath (Join-Path $localLow 'analytics.sqlite'))
    'Локальное сохранение не тронуто' = (Test-Path -LiteralPath (Join-Path $localLow 'savegame.db'))
    'Папка Sentry игры удалена'       = -not (Test-Path -LiteralPath (Join-Path $localLow 'Sentry'))
    'Player.log удалён'               = -not (Test-Path -LiteralPath (Join-Path $localLow 'Player.log'))
    'output_log.txt удалён'           = -not (Test-Path -LiteralPath (Join-Path $localLow 'output_log.txt'))
    'Temp\Kefir удалён'               = -not (Test-Path -LiteralPath (Join-Path $local 'Temp\Kefir'))
    'EOS SDK удалён'                  = -not (Test-Path -LiteralPath (Join-Path $local 'EpicOnlineServices'))
    'Epic Games Launcher сохранён'    = (Test-Path -LiteralPath (Join-Path $local 'EpicGamesLauncher'))
    'Общая папка Sentry сохранена'    = (Test-Path -LiteralPath (Join-Path $local 'Sentry'))
    'Unity Analytics сохранён'        = (Test-Path -LiteralPath (Join-Path $local 'Unity\Analytics'))
}

$failures = 0
foreach ($name in $checks.Keys) {
    if ($checks[$name]) {
        "  PASS  $name"
    } else {
        "  FAIL  $name"
        $failures++
    }
}

if ($failures -gt 0) {
    ""
    "--- Вывод скрипта ---"
    $out | ForEach-Object { "  $_" }
}

Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testRegRoot -Recurse -Force -ErrorAction SilentlyContinue

""
if ($failures -gt 0) {
    "Тест не пройден: $failures проверок с ошибкой."
    exit 1
}

"Все проверки пройдены."
exit 0
