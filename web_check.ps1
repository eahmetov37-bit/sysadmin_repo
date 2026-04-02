param(
    [string]$url
)

# Путь к файлу логов
$LogFile = "/var/log/web_checks/script.log"

# Массивы для хранения времени ответа и размера ответа
$script:TimeResults = @()
$script:SizeResults = @()

# Функция вычисления среднего времени ответа
function CalcTime {
    if ($script:TimeResults.Count -eq 0) {
        $message = "Нет данных для расчета среднего времени ответа."
        Write-Host $message
        Add-Content -Path $LogFile -Value $message
        return
    }

    $averageTime = ($script:TimeResults | Measure-Object -Average).Average
    $averageTime = [math]::Round($averageTime, 2)

    $message = "Среднее время ответа сайта: $averageTime мс"
    Write-Host $message
    Add-Content -Path $LogFile -Value $message
}

# Функция вычисления среднего размера ответа
function CalcWeight {
    if ($script:SizeResults.Count -eq 0) {
        $message = "Нет данных для расчета среднего размера ответа."
        Write-Host $message
        Add-Content -Path $LogFile -Value $message
        return
    }

    $averageSize = ($script:SizeResults | Measure-Object -Average).Average
    $averageSize = [math]::Round($averageSize, 2)

    $message = "Средний размер ответа сайта: $averageSize байт"
    Write-Host $message
    Add-Content -Path $LogFile -Value $message
}

# Основная функция
function WebRequest {
    # Проверка наличия параметра
    if ([string]::IsNullOrWhiteSpace($url)) {
        $message = "Ошибка: адрес сайта не передан."
        Write-Host $message
        Add-Content -Path $LogFile -Value $message
        return
    }

    # Убираем возможный завершающий слэш
    $cleanUrl = $url.TrimEnd('/')

    # Проверяем, не указана ли схема в параметре
    if ($cleanUrl -match '^https?://') {
        $baseDomain = $cleanUrl -replace '^https?://', ''
    }
    else {
        $baseDomain = $cleanUrl
    }

    $ports = @(80, 443)

    foreach ($port in $ports) {
        for ($i = 1; $i -le 3; $i++) {

            if ($port -eq 80) {
                $targetUrl = "http://$baseDomain"
            }
            else {
                $targetUrl = "https://$baseDomain"
            }

            try {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

                $response = Invoke-WebRequest -Uri $targetUrl -Method Get -TimeoutSec 15 -ErrorAction Stop
                $commandStatus = $?

                $stopwatch.Stop()
                $responseTime = $stopwatch.ElapsedMilliseconds

                # Размер ответа
                $responseSize = 0
                if ($null -ne $response.Content) {
                    $responseSize = ([System.Text.Encoding]::UTF8.GetBytes($response.Content)).Length
                }

                # Проверка успешности последней команды
                if (-not $commandStatus) {
                    $message = "Ошибка: команда Invoke-WebRequest завершилась неуспешно. Порт $port, итерация $i."
                    Write-Host $message
                    Add-Content -Path $LogFile -Value $message
                    return
                }

                # Проверка кода ответа
                if ($response.StatusCode -ne 200) {
                    $message = "Ошибка: сайт недоступен. Порт $port, итерация $i, код ответа $($response.StatusCode), описание $($response.StatusDescription)."
                    Write-Host $message
                    Add-Content -Path $LogFile -Value $message
                    return
                }

                # Сохраняем данные для последующих вычислений
                $script:TimeResults += $responseTime
                $script:SizeResults += $responseSize

                $message = "Успех: порт $port, итерация $i, код ответа $($response.StatusCode), описание $($response.StatusDescription), время $responseTime мс, размер $responseSize байт."
                Write-Host $message
                Add-Content -Path $LogFile -Value $message
            }
            catch {
                $message = "Ошибка: сайт недоступен. Порт $port, итерация $i."
                Write-Host $message
                Add-Content -Path $LogFile -Value $message
                return
            }
        }
    }

    CalcTime
    CalcWeight
}

WebRequest