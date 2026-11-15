[CmdletBinding()]
param(
    [switch]$Ci,
    [string]$InnoCompiler
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'build-gui.ps1') -OutputDirectory 'build/package'
if (Test-Path (Join-Path $root 'build/fanctl-curves.txt')) {
    Copy-Item -LiteralPath (Join-Path $root 'build/fanctl-curves.txt') -Destination (Join-Path $root 'build/package/fanctl-curves.txt')
} elseif (-not $Ci) {throw 'Salve as curvas na interface antes de empacotar.'}
Set-Content -LiteralPath (Join-Path $root 'build/package/fanctl-startup.txt') -Encoding ascii -Value "FANCTL_STARTUP 1`n1 30 30 0"
$compiler=$InnoCompiler
if (-not $compiler) {$compiler=Join-Path $root '.tools/inno/ISCC.exe'}
if (-not (Test-Path $compiler)) {throw "Compilador Inno Setup nao encontrado em $compiler."}
& $compiler (Join-Path $root 'installer/FanController.iss')
if ($LASTEXITCODE -ne 0) {throw 'Compilacao do instalador falhou.'}
Get-ChildItem (Join-Path $root 'dist/aeri-Setup-*.exe') | Select-Object FullName,Length
