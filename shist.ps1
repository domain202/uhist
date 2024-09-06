# ================================
# Конфигурация истории PowerShell
# ================================

$LogFile = "$PSScriptRoot\PSHistory.log"
$HistoryFile = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
$HistoryCounterFile = "$PSScriptRoot\HistoryCounter.txt"

# ================================
# Чтение истории из файла PSReadLine
# ================================

function Log-CommandFromHistoryFile {
    if (-not (Test-Path $HistoryFile)) {
        Write-Host "Файл истории не найден."
        return
    }

    # Чтение файла истории
    $historyContent = Get-Content $HistoryFile

    if (-not (Test-Path $HistoryCounterFile)) {
        $HistoryCounter = 0
        $HistoryCounter | Out-File -FilePath $HistoryCounterFile
    } else {
        $HistoryCounter = [int](Get-Content $HistoryCounterFile)
    }

    # Логируем команды
    foreach ($cmd in $historyContent) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $global:HistoryCounter++
        $logEntry = "$global:HistoryCounter | $timestamp | $user | $cmd"
        $logEntry | Out-File -Append -FilePath $LogFile
    }

    # Обновляем счётчик
    $global:HistoryCounter | Out-File -FilePath $HistoryCounterFile -Force
}

# ================================
# Функция для отображения истории в консоли
# ================================

function Show-ConsoleHistory {
    if (-not (Test-Path $LogFile)) {
        Write-Host "Лог-файл не найден."
        return
    }

    $historyLines = Get-Content $LogFile | Select-Object -Last 100

    if ($historyLines.Count -eq 0) {
        Write-Host "История пуста."
        return
    }

    $historyLines | ForEach-Object {
        $fields = $_ -split '\|'
        if ($fields.Length -ge 4) {
            [PSCustomObject]@{
                ID          = $fields[0].Trim()
                Время       = $fields[1].Trim()
                Пользователь = $fields[2].Trim()
                Команда     = $fields[3].Trim()
            }
        }
    } | Format-Table -AutoSize
}

# ================================
# Функция для отображения истории в GUI
# ================================

function Show-GUIHistory {
    if (-not (Test-Path $LogFile)) {
        Write-Host "Лог-файл не найден."
        return
    }

    $history = Get-Content $LogFile | ForEach-Object {
        $fields = $_ -split '\|'
        if ($fields.Length -ge 4) {
            [PSCustomObject]@{
                ID          = [int]$fields[0].Trim()
                Timestamp   = $fields[1].Trim()
                Username    = $fields[2].Trim()
                Command     = $fields[3].Trim()
            }
        }
    }
    
    if ($history.Count -eq 0) {
        Write-Host "История пуста."
        return
    }

    $history | Out-GridView -Title "История команд PowerShell" -PassThru | Out-Null
}

# ================================
# Вызов логирования
# ================================

Log-CommandFromHistoryFile

# ================================
# Обработка аргументов командной строки
# ================================

if ($args.Length -eq 0) {
    Write-Host "Укажите параметр для отображения истории. Используйте '-gui' для GUI или '-console' для консольного вывода."
    exit
}

switch -Wildcard ($args[0]) {
    '-gui' {
        Show-GUIHistory
    }
    '-console' {
        Show-ConsoleHistory
    }
    default {
        Write-Host "Неизвестный параметр. Используйте '-gui' для GUI или '-console' для консольного вывода."
    }
}
