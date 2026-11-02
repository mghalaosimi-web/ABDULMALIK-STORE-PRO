; ملف تثبيت ABDULMALIK ERP لـ Windows (Inno Setup 6).
; البناء: tool\build_release.ps1 (بيبني البرنامج وبيجهز ملفات Windows الناقصة وبيعمل الـ Setup).
#define AppName "ABDULMALIK ERP"
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\builds"
#endif

[Setup]
; المعرّف ده لازم يفضل ثابت عشان التحديثات تتسطب فوق النسخة القديمة
AppId={{C9D1E4B7-5A23-4C9F-9D11-2F6B8A4E7130}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=ABDULMALIK
DefaultDirName={autopf}\ABDULMALIK ERP
DefaultGroupName=ABDULMALIK ERP
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=ABDULMALIK-ERP-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\abdulmalik_erp.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
RestartApplications=no

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
arabic.DesktopIcon=أيقونة على سطح المكتب
arabic.AutoStart=تشغيل ABDULMALIK ERP تلقائياً عند بدء تشغيل Windows (موصى به إذا كان هذا الجهاز خادم المحل)
arabic.LaunchApp=تشغيل ABDULMALIK ERP الآن
english.DesktopIcon=Create a desktop shortcut
english.AutoStart=Start ABDULMALIK ERP automatically with Windows (recommended for the shop server)
english.LaunchApp=Launch ABDULMALIK ERP now

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"
Name: "autostart"; Description: "{cm:AutoStart}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\ABDULMALIK ERP"; Filename: "{app}\abdulmalik_erp.exe"
Name: "{autodesktop}\ABDULMALIK ERP"; Filename: "{app}\abdulmalik_erp.exe"; Tasks: desktopicon
Name: "{commonstartup}\ABDULMALIK ERP"; Filename: "{app}\abdulmalik_erp.exe"; Tasks: autostart

[Run]
; Install the Microsoft Visual C++ x64 runtime before launching the app.
Filename: "{app}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: runhidden waituntilterminated
; الـ Firewall: بنسمح للبرنامج بس (مش بورتات مفتوحة لأي حاجة) عشان الموبايلات تتصل بالسيرفر.
; profile=any لأن شبكة الواي فاي في محلات كتير Windows بيعتبرها "عامة".
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""ABDULMALIK ERP"""; Flags: runhidden waituntilterminated
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""ABDULMALIK ERP"" dir=in action=allow program=""{app}\abdulmalik_erp.exe"" enable=yes profile=any remoteip=localsubnet"; Flags: runhidden waituntilterminated
Filename: "{app}\abdulmalik_erp.exe"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""ABDULMALIK ERP"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveFirewallRule"

; بيانات المحل (في AppData) مش بتتمسح مع إلغاء التثبيت، عشان مايضيعش حاجة بالغلط.
