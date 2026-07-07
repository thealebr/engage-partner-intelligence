@echo off
setlocal

rem ENGAGE PARTNER INTELLIGENCE
rem Este iniciador libera a execução somente para o instalador atual.
rem Não modifica permanentemente a política de segurança do Windows.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_ENGAGE.ps1" %*

if errorlevel 1 (
    echo.
    echo A instalacao nao foi concluida. Consulte a mensagem acima.
    pause
    exit /b 1
)

endlocal
