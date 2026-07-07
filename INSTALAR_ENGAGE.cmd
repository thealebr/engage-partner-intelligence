@echo off
setlocal

rem ENGAGE PARTNER INTELLIGENCE
rem Libera a execucao somente para este instalador.
rem Nao modifica permanentemente a politica de seguranca do Windows.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_ENGAGE.ps1" %*

if errorlevel 1 (
    echo.
    echo A instalacao nao foi concluida. Consulte a mensagem acima.
    pause
    exit /b 1
)

endlocal
