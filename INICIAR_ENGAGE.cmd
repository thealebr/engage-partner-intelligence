@echo off
setlocal

rem Inicia o Engage sem alterar permanentemente a politica do Windows.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INICIAR_ENGAGE.ps1" %*

if errorlevel 1 (
    echo.
    echo O Engage nao foi iniciado. Consulte a mensagem acima.
    pause
    exit /b 1
)

endlocal
