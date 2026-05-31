param(
    [string]$TomcatVersion,
    [string]$TomcatUrl,
    [string]$InstallDir,
    [string]$ServiceName,
    [string]$JavaHome
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$package = "apache-tomcat-$TomcatVersion"
$zipPath = "C:\temp\$package-windows-x64.zip"

if (!(Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

Invoke-WebRequest -Uri $TomcatUrl -OutFile $zipPath

if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

Expand-Archive -Path $zipPath -DestinationPath "C:\" -Force

$expandedDir = Get-ChildItem -Path "C:\" -Directory | Where-Object { $_.Name -like "$package*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($expandedDir) {
    Rename-Item -Path $expandedDir.FullName -NewName (Split-Path $InstallDir -Leaf)
}

$serviceBat = Join-Path $InstallDir "bin\service.bat"
if (Test-Path $serviceBat) {
    $env:CATALINA_HOME = $InstallDir
    $env:CATALINA_BASE = $InstallDir
    $env:JRE_HOME      = $JavaHome
    $env:JAVA_HOME     = $JavaHome

    Push-Location (Join-Path $InstallDir 'bin')
    try {
        & .\service.bat install $ServiceName
        if ($LASTEXITCODE -ne 0) {
            throw "Tomcat service install failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    throw "Tomcat service installer not found at $serviceBat"
}

if (-not (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    throw "Tomcat service '$ServiceName' was not created successfully"
}
