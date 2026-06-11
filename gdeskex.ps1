<#
.SYNOPSIS
    GDeskEx – Gerencia aplicativos Android no Windows via WSA (ou WSABuilds).
.DESCRIPTION
    Fornece comandos para instalar, executar, listar e remover APKs, além de gerenciar o subsistema Android.
.AUTHOR
    Seu Nome
#>

# ========== FUNÇÕES AUXILIARES ==========
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-WSAInstalled {
    $package = Get-AppxPackage -Name "*WindowsSubsystemForAndroid*" -ErrorAction SilentlyContinue
    return ($null -ne $package)
}

function Test-WSARunning {
    $proc = Get-Process -Name "WsaClient" -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

function Start-WSA {
    Write-ColorOutput "Iniciando WSA..." "Cyan"
    Start-Process "shell:AppsFolder\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
    Start-Sleep -Seconds 8
}

function Test-DeveloperMode {
    $tcpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 58526 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    return ($tcpTest.TcpTestSucceeded -eq $true)
}

function Ensure-ADB {
    $adbPaths = @(
        "$env:ProgramFiles\WSA\adb.exe",
        "$env:LocalAppData\Android\Sdk\platform-tools\adb.exe",
        (Get-Command adb -ErrorAction SilentlyContinue).Source
    )
    foreach ($path in $adbPaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    Write-ColorOutput "ADB não encontrado. Verifique se o WSA está instalado corretamente." "Red"
    exit 1
}

function Wait-Device {
    param([string]$AdbPath, [int]$TimeoutSeconds = 30)
    Write-ColorOutput "Aguardando dispositivo Android (WSA)..." "Cyan"
    for ($i=0; $i -lt $TimeoutSeconds; $i++) {
        $devices = & $AdbPath devices | Select-String -Pattern "device$" -NotMatch -SimpleMatch
        if ($devices -match "List of devices attached\s+(\S+)\s+device") {
            Write-ColorOutput "Dispositivo conectado." "Green"
            return $true
        }
        Start-Sleep -Seconds 1
    }
    Write-ColorOutput "Timeout: dispositivo não conectado. Verifique se o WSA está rodando e o modo desenvolvedor ativado." "Red"
    return $false
}

function Ensure-WSAEnvironment {
    if (-not (Test-WSAInstalled)) {
        Write-ColorOutput "WSA não encontrado. Execute 'gdeskex wsa-install' primeiro." "Red"
        exit 1
    }
    if (-not (Test-WSARunning)) {
        Start-WSA
        Start-Sleep -Seconds 3
        if (-not (Test-WSARunning)) {
            Write-ColorOutput "Não foi possível iniciar o WSA. Inicie manualmente." "Red"
            exit 1
        }
    }
    if (-not (Test-DeveloperMode)) {
        Write-ColorOutput "Modo desenvolvedor do WSA não está ativado." "Red"
        Write-ColorOutput "Abra as configurações do WSA, ative o 'Modo desenvolvedor' e clique em 'Gerenciar arquivos'." "Yellow"
        Start-Process "ms-settings:developers?subsystem=android"
        Read-Host "Pressione Enter após ativar o modo desenvolvedor"
        if (-not (Test-DeveloperMode)) {
            Write-ColorOutput "Modo desenvolvedor ainda não detectado. Abortando." "Red"
            exit 1
        }
    }
}

# ========== FUNÇÕES PRINCIPAIS ==========
function Install-AndroidApp {
    param([Parameter(Mandatory)] [string]$ApkPath)
    if (-not (Test-Path $ApkPath)) {
        Write-ColorOutput "Arquivo $ApkPath não encontrado." "Red"
        return
    }
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }
    Write-ColorOutput "Instalando $ApkPath ..." "Cyan"
    & $AdbPath install $ApkPath
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Instalação concluída." "Green"
    } else {
        Write-ColorOutput "Falha na instalação." "Red"
    }
}

function Run-AndroidApp {
    param([Parameter(Mandatory)] [string]$Package)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }
    $resolve = & $AdbPath shell cmd package resolve-activity --user 0 $Package
    if (-not $resolve) {
        Write-ColorOutput "Pacote '$Package' não encontrado ou não possui activity principal." "Red"
        return
    }
    $activity = ($resolve -split '\s+')[-1].Trim()
    Write-ColorOutput "Executando $Package / $activity ..." "Cyan"
    & $AdbPath shell am start -n $activity
}

function List-AndroidApps {
    param([switch]$UserOnly)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }
    $cmd = "pm list packages"
    if ($UserOnly) { $cmd += " -3" }
    $packages = & $AdbPath shell $cmd
    $packages -replace "^package:","" | Sort-Object
}

function Remove-AndroidApp {
    param([Parameter(Mandatory)] [string]$Package)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }
    Write-ColorOutput "Desinstalando $Package ..." "Yellow"
    & $AdbPath uninstall $Package
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "App desinstalado." "Green"
    } else {
        Write-ColorOutput "Falha na desinstalação (pacote pode não existir)." "Red"
    }
}

function New-AndroidShortcut {
    param([Parameter(Mandatory)] [string]$Package, [string]$Name)
    if (-not $Name) { $Name = $Package -replace "\.[^.]*$","" }
    $shortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), "$Name.lnk")
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptContent = @"
`$package = "$Package"
& "$scriptPath" run `$package
"@
    $ps1Path = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), "$Name.ps1")
    $scriptContent | Out-File -FilePath $ps1Path -Encoding utf8
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ps1Path`""
    $shortcut.WorkingDirectory = [Environment]::GetFolderPath('Desktop')
    $shortcut.Save()
    Write-ColorOutput "Atalho criado em: $shortcutPath" "Green"
}

function Get-AndroidAppFromRepo {
    param([Parameter(Mandatory)] [string]$AppId)
    $repoUrl = "https://raw.githubusercontent.com/seuusuario/gdeskex-repo/main/repo.json"
    Write-ColorOutput "Buscando app '$AppId' no repositório..." "Cyan"
    try {
        $repoJson = Invoke-RestMethod -Uri $repoUrl -ErrorAction Stop
        $app = $repoJson.apps | Where-Object { $_.id -eq $AppId }
        if (-not $app) {
            Write-ColorOutput "App '$AppId' não encontrado no repositório." "Red"
            return
        }
        $apkUrl = $app.apk_url
        $package = $app.package
        $tempApk = Join-Path $env:TEMP "$AppId.apk"
        Write-ColorOutput "Baixando APK de $apkUrl ..." "Cyan"
        Invoke-WebRequest -Uri $apkUrl -OutFile $tempApk -ErrorAction Stop
        Install-AndroidApp -ApkPath $tempApk
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "App instalado com sucesso. Pacote: $package" "Green"
        }
        Remove-Item $tempApk -Force
    } catch {
        Write-ColorOutput "Falha ao acessar repositório: $_" "Red"
    }
}

# ========== FUNÇÕES DE GERENCIAMENTO DO WSA ==========
function Install-WSABuilds {
    Write-ColorOutput "Iniciando instalação do WSABuilds..." "Cyan"
    $wsaUrl = "https://github.com/MustardChef/WSABuilds/releases/download/Windows_10_2407.40000.4.0_v2/WSA_2407.40000.4.0_x64_Release-Nightly-with-Magisk-28.1.0-Module.7z"
    $tempDir = Join-Path $env:TEMP "WSABuilds"
    $sevenZipUrl = "https://www.7-zip.org/a/7zr.exe"
    $sevenZipPath = Join-Path $tempDir "7zr.exe"
    $archivePath = Join-Path $tempDir "WSA.7z"
    $extractPath = Join-Path $tempDir "Extracted"
    
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
    if (-not (Test-Path $sevenZipPath)) {
        Write-ColorOutput "Baixando 7-Zip..." "Cyan"
        Invoke-WebRequest -Uri $sevenZipUrl -OutFile $sevenZipPath -ErrorAction Stop
    }
    Write-ColorOutput "Baixando WSABuilds (pode levar alguns minutos)..." "Cyan"
    Invoke-WebRequest -Uri $wsaUrl -OutFile $archivePath -ErrorAction Stop
    Write-ColorOutput "Extraindo arquivos..." "Cyan"
    if (-not (Test-Path $extractPath)) { New-Item -ItemType Directory -Path $extractPath -Force | Out-Null }
    & $sevenZipPath x $archivePath -o$extractPath -y | Out-Null
    $runBat = Get-ChildItem -Path $extractPath -Recurse -Filter "Run.bat" | Select-Object -First 1
    if ($runBat) {
        Write-ColorOutput "Executando instalador do WSABuilds..." "Cyan"
        Start-Process -FilePath $runBat.FullName -Wait -NoNewWindow
        Write-ColorOutput "Instalação concluída. Reinicie o computador para finalizar." "Green"
    } else {
        Write-ColorOutput "Instalador não encontrado dentro do pacote." "Red"
    }
}

function Set-WSAMemoryLimit {
    param([Parameter(Mandatory)] [int]$MemoryMB)
    if (-not (Test-WSAInstalled)) {
        Write-ColorOutput "WSA não instalado. Execute 'gdeskex wsa-install' primeiro." "Red"
        return
    }
    Write-ColorOutput "Definindo limite de memória para $MemoryMB MB..." "Cyan"
    wsl --shutdown 2>$null
    WsaClient /shutdown 2>$null
    Start-Sleep -Seconds 2
    $configPath = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalState\wsa_settings.xml"
    if (Test-Path $configPath) {
        $content = Get-Content $configPath -Raw
        if ($content -match 'MemoryLimit') {
            $newContent = $content -replace '(MemoryLimit>)\d+(</MemoryLimit>)', "`$1$MemoryMB`$2"
            Set-Content -Path $configPath -Value $newContent -Force
        } else {
            $newContent = $content -replace '(</Settings>)', "  <MemoryLimit>$MemoryMB</MemoryLimit>`n</Settings>"
            Set-Content -Path $configPath -Value $newContent -Force
        }
    } else {
        Write-ColorOutput "Arquivo de configuração do WSA não encontrado." "Red"
        return
    }
    Start-Process "shell:AppsFolder\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
    Write-ColorOutput "Limite de memória aplicado. WSA reiniciado." "Green"
}

function Set-WSADeviceSpoof {
    param([Parameter(Mandatory)] [string]$Model)
    if (-not (Test-WSAInstalled)) {
        Write-ColorOutput "WSA não instalado." "Red"
        return
    }
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }
    Write-ColorOutput "Aplicando spoof de dispositivo para $Model..." "Cyan"
    $props = @{
        "Pixel4a" = "sunfish"
        "Pixel5"  = "redfin"
        "Pixel6"  = "oriole"
    }
    $modelCode = if ($props.ContainsKey($Model)) { $props[$Model] } else { $Model }
    & $AdbPath shell "setprop ro.product.model $modelCode"
    & $AdbPath shell "setprop ro.product.manufacturer Google"
    if ($Model -eq "Pixel4a") {
        & $AdbPath shell "setprop ro.config.low_ram true"
    }
    Write-ColorOutput "Spoof aplicado. Reinicie o WSA para efeitos completos (use 'gdeskex wsa-restart')." "Yellow"
}

function Restart-WSA {
    Write-ColorOutput "Reiniciando WSA..." "Cyan"
    wsl --shutdown 2>$null
    WsaClient /shutdown 2>$null
    Start-Sleep -Seconds 3
    Start-Process "shell:AppsFolder\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
    Write-ColorOutput "WSA reiniciado." "Green"
}

function Optimize-WSAForLowRAM {
    Write-ColorOutput "Aplicando otimizações para baixa RAM (4GB)..." "Cyan"
    Set-WSAMemoryLimit -MemoryMB 1536
    Set-WSADeviceSpoof -Model "Pixel4a"
    Write-ColorOutput "Otimizações aplicadas. O WSA será reiniciado." "Green"
    Restart-WSA
}

function Show-WSAStatus {
    Write-ColorOutput "=== Status do WSA ===" "Cyan"
    if (Test-WSAInstalled) {
        Write-ColorOutput "Instalado: SIM" "Green"
        if (Test-WSARunning) {
            Write-ColorOutput "Em execução: SIM" "Green"
            $AdbPath = Ensure-ADB
            if (Test-DeveloperMode) {
                Write-ColorOutput "Modo desenvolvedor: ATIVADO" "Green"
                $configPath = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalState\wsa_settings.xml"
                if (Test-Path $configPath) {
                    $content = Get-Content $configPath -Raw
                    if ($content -match 'MemoryLimit>(\d+)</MemoryLimit') {
                        Write-ColorOutput "Limite de memória: $($matches[1]) MB" "Green"
                    }
                }
                $deviceModel = & $AdbPath shell getprop ro.product.model 2>$null
                if ($deviceModel) {
                    Write-ColorOutput "Modelo do dispositivo: $deviceModel" "Green"
                }
            } else {
                Write-ColorOutput "Modo desenvolvedor: DESATIVADO" "Red"
            }
        } else {
            Write-ColorOutput "Em execução: NÃO" "Red"
        }
    } else {
        Write-ColorOutput "Instalado: NÃO" "Red"
    }
}

# ========== PONTO DE ENTRADA ==========
$cmd = $args[0]
switch ($cmd) {
    "install" { Install-AndroidApp -ApkPath $args[1] }
    "run" { Run-AndroidApp -Package $args[1] }
    "list" { List-AndroidApps @{ UserOnly = $false } }
    "list-user" { List-AndroidApps -UserOnly }
    "remove" { Remove-AndroidApp -Package $args[1] }
    "shortcut" { New-AndroidShortcut -Package $args[1] -Name $args[2] }
    "get" { Get-AndroidAppFromRepo -AppId $args[1] }
    "wsa-install" { Install-WSABuilds }
    "wsa-memory" { if ($args[1]) { Set-WSAMemoryLimit -MemoryMB ([int]$args[1]) } else { Write-ColorOutput "Uso: gdeskex wsa-memory [MB]" "Yellow" } }
    "wsa-spoof" { if ($args[1]) { Set-WSADeviceSpoof -Model $args[1] } else { Write-ColorOutput "Uso: gdeskex wsa-spoof [Pixel4a|Pixel5|Pixel6]" "Yellow" } }
    "wsa-restart" { Restart-WSA }
    "wsa-optimize" { Optimize-WSAForLowRAM }
    "wsa-status" { Show-WSAStatus }
    default {
        Write-ColorOutput @"
GDeskEx - Gerenciador de apps Android via WSA

Comandos existentes:
  install [caminho.apk]        Instala um APK local
  run [pacote]                 Executa um app instalado (ex: com.exemplo.app)
  list                         Lista todos os pacotes instalados
  list-user                    Lista apenas apps de usuário
  remove [pacote]              Desinstala um app
  shortcut [pacote] [nome]     Cria atalho na área de trabalho
  get [app-id]                 Baixa e instala app do repositório online

Novos comandos WSA:
  wsa-install                  Baixa e instala o WSABuilds (Windows 10/11)
  wsa-memory [MB]              Define o limite de memória do WSA (ex: 1536)
  wsa-spoof [modelo]           Altera identificação do dispositivo (Pixel4a, Pixel5, Pixel6)
  wsa-restart                  Reinicia o WSA
  wsa-optimize                 Aplica otimizações automáticas para 4GB de RAM
  wsa-status                   Mostra status do WSA (instalado, memória, modelo)

Exemplos:
  .\gdeskex.ps1 install C:\Downloads\telegram.apk
  .\gdeskex.ps1 run org.telegram.messenger
  .\gdeskex.ps1 shortcut org.telegram.messenger Telegram
  .\gdeskex.ps1 get among-us
  .\gdeskex.ps1 wsa-optimize
  .\gdeskex.ps1 wsa-status
"@
    }
}