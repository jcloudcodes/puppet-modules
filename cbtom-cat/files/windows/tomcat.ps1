param(
    [string]$TomcatVersion,
    [string]$NexusUrl,
    [string]$InstallDir,
    [string]$ServiceName
)

$package = "apache-tomcat-$TomcatVersion"
$zipPath = "C:\temp\$package.zip"
$downloadUrl = "$NexusUrl/$package.zip"

if (!(Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

Expand-Archive -Path $zipPath -DestinationPath "C:\" -Force

$expandedDir = "C:\$package"
if (Test-Path $expandedDir) {
    Rename-Item -Path $expandedDir -NewName (Split-Path $InstallDir -Leaf)
}

$serviceBat = Join-Path $InstallDir "bin\service.bat"
if (Test-Path $serviceBat) {
    & $serviceBat install $ServiceName
}
