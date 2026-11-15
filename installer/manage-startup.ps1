[CmdletBinding()]
param([ValidateSet('Install','Remove','Verify','Start')][string]$Mode='Install')
$ErrorActionPreference='Stop'
$taskName='aeri - Lucas'
$legacyTaskName='FanController - Lucas'
$executable=Join-Path $PSScriptRoot 'aeri.exe'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Execute como administrador.'
}
function Remove-Task([string]$name) {
    $task=Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    if ($task) { Unregister-ScheduledTask -TaskName $name -Confirm:$false }
}
if ($Mode -eq 'Remove') {
    Remove-Task $taskName
    Remove-Task $legacyTaskName
    exit 0
}
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {throw 'Executavel nao encontrado.'}
if ($Mode -eq 'Install') {
    Remove-Task $legacyTaskName
    $action=New-ScheduledTaskAction -Execute $executable -Argument '--startup' -WorkingDirectory $PSScriptRoot
    $trigger=New-ScheduledTaskTrigger -AtLogOn -User $identity.User.Value
    $trigger.Delay='PT10S'
    $owner=New-ScheduledTaskPrincipal -UserId $identity.User.Value -LogonType Interactive -RunLevel Highest
    $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $owner `
        -Settings $settings -Description 'Inicia aeri na bandeja e aplica o ultimo modo salvo ao entrar no Windows.' -Force | Out-Null
}
$registered=Get-ScheduledTask -TaskName $taskName
if ($registered.Actions.Execute -ne $executable -or $registered.Actions.Arguments -ne '--startup' -or
    $registered.Principal.RunLevel -ne 'Highest' -or $registered.Principal.LogonType -ne 'Interactive' -or
    $registered.Settings.DisallowStartIfOnBatteries -or $registered.Settings.StopIfGoingOnBatteries -or
    $registered.Settings.ExecutionTimeLimit -ne 'PT0S') {throw 'Configuracao da tarefa nao confere.'}
if ($Mode -eq 'Start') {Start-ScheduledTask -TaskName $taskName}
$registered | Select-Object TaskName,State,@{n='Executable';e={$_.Actions.Execute}},@{n='Arguments';e={$_.Actions.Arguments}}
