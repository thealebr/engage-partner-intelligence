$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = 'C:\Users\TheAle\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (-not (Test-Path $python)) { $python = 'python' }
function Port-Open($port) { return [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) }
if (-not (Port-Open 8767)) { Start-Process -FilePath $python -ArgumentList '.\backend\server.py' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput "$root\backend\server-8767.log" -RedirectStandardError "$root\backend\server-8767.err" }
if (-not (Port-Open 8765)) { Start-Process -FilePath $python -ArgumentList '-m','http.server','8765','--directory','FTNT-Engage' -WorkingDirectory $root -WindowStyle Hidden }
Write-Host 'Engage Beta disponível em http://127.0.0.1:8765/' -ForegroundColor Green
