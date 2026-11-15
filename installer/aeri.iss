#define AppVersion "0.7.0"
[Setup]
AppId={{7C301214-1666-4DC6-A287-8B378329C68F}
AppName=aeri
AppVersion={#AppVersion}
AppPublisher=Lucas
DefaultDirName={autopf}\aeri
UsePreviousAppDir=no
DisableDirPage=yes
DefaultGroupName=aeri
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\dist
OutputBaseFilename=aeri-Setup-{#AppVersion}-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
AppMutex=Local\FanControllerGui
CloseApplications=no
RestartApplications=no
UninstallDisplayIcon={app}\aeri.exe
SetupLogging=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "..\build\package\aeri.exe"; DestDir: "{app}"; DestName: "aeri.exe"; Flags: ignoreversion
Source: "..\build\package\PresentMon-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\package\PresentMon-THIRD-PARTY.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "manage-startup.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\package\fanctl-curves.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall skipifsourcedoesntexist
Source: "..\build\package\fanctl-startup.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall skipifsourcedoesntexist

Source: "..\build\package\WebView2-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\aeri"; Filename: "{app}\aeri.exe"; WorkingDir: "{app}"
Name: "{group}\Desinstalar aeri"; Filename: "{uninstallexe}"

[Code]
function ManageStartup(Mode: String): Boolean;
var
  Code: Integer;
  Args: String;
begin
  Args := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\manage-startup.ps1') + '" -Mode ' + Mode;
  Result := Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Args, '', SW_HIDE, ewWaitUntilTerminated, Code);
  Result := Result and (Code = 0);
end;

procedure MigrateLegacyInstall;
var
  OldDir, NewDir, Name: String;
  I: Integer;
  Files: array[0..1] of String;
begin
  OldDir := ExpandConstant('{autopf}\FanController');
  NewDir := ExpandConstant('{app}');
  if not DirExists(OldDir) then Exit;
  Files[0] := 'fanctl-curves.txt';
  Files[1] := 'fanctl-startup.txt';
  for I := 0 to 1 do
  begin
    Name := Files[I];
    if FileExists(OldDir + '\' + Name) and not FileExists(NewDir + '\' + Name) then
      FileCopy(OldDir + '\' + Name, NewDir + '\' + Name, True);
  end;
  DelTree(OldDir, True, True, True);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    MigrateLegacyInstall;
  if CurStep = ssPostInstall then
    if not ManageStartup('Install') then
      RaiseException('Não foi possível registrar a inicialização automática. Execute o instalador novamente.');
  if CurStep = ssDone then
    if not ManageStartup('Start') then
      MsgBox('Instalado, mas não foi possível iniciar agora. O programa tentará iniciar no próximo login.', mbError, MB_OK);
end;

function InitializeUninstall(): Boolean;
begin
  Result := ManageStartup('Remove');
  if not Result then
    MsgBox('Não foi possível remover a tarefa de inicialização. A desinstalação foi interrompida.', mbError, MB_OK);
end;
