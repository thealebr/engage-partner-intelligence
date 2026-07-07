@echo off
setlocal

rem Inicia o Engage sem alterar permanentemente a politica do Windows.
if not exist "%~dp0backend\engage.db" (
    echo Projeto completo nao encontrado nesta pasta.
    if exist "%~dp0INSTALAR_ENGAGE.ps1" (
        echo Iniciando a instalacao e o clone do GitHub...
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_ENGAGE.ps1"
        if errorlevel 1 exit /b 1
        exit /b 0
    )
    echo Execute o arquivo INSTALAR_ENGAGE.cmd para baixar o projeto completo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INICIAR_ENGAGE.ps1" %*

if errorlevel 1 (
    echo.
    echo O Engage nao foi iniciado. Consulte a mensagem acima.
    pause
    exit /b 1
)

endlocal
