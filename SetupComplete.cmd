@echo off
REM Wazuh Agent Post-Clone Configuration - Automated Setup
REM Executed once after Sysprep OOBE

REM Warte auf Netzwerk-Initialisierung
echo Waiting for network initialization...
timeout /t 10 /nobreak > NUL

REM Stelle sicher dass Wazuh Service auf Autostart steht
sc config WazuhSvc start= auto

REM Stoppe Service falls er läuft
net stop WazuhSvc 2>nul

REM Lösche alte Client-Keys und Queue
if exist "C:\Program Files (x86)\ossec-agent\client.keys" (
    del "C:\Program Files (x86)\ossec-agent\client.keys" /F /Q
)
if exist "C:\Program Files (x86)\ossec-agent\queue\rids\" (
    del "C:\Program Files (x86)\ossec-agent\queue\rids\*" /F /Q 2>nul
)

REM Registriere bei Wazuh Manager
echo Registering with Wazuh Manager...
"C:\Program Files (x86)\ossec-agent\agent-auth.exe" -m 192.168.178.43

REM Prüfe ob Registrierung erfolgreich war
if errorlevel 1 (
    echo Registration FAILED! Retrying in 30 seconds...
    timeout /t 30 /nobreak > NUL
    "C:\Program Files (x86)\ossec-agent\agent-auth.exe" -m 192.168.178.43
    
    if errorlevel 1 (
        echo Registration FAILED again! Check Wazuh Manager connectivity.
        echo %date% %time% - Wazuh Agent registration FAILED >> C:\Windows\Temp\setup_complete.log
        exit /b 1
    )
)

REM Starte Wazuh Service
echo Starting Wazuh Service...
net start WazuhSvc

REM Logge erfolgreiche Ausführung
echo %date% %time% - Wazuh Agent configured successfully >> C:\Windows\Temp\setup_complete.log

REM Lösche dieses Script nach erfolgreicher Ausführung
REM Kommentiere die nächste Zeile aus zum Debuggen
del "%~f0"