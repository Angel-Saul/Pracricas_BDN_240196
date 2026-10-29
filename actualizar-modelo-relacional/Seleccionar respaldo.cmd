@echo off
setlocal
set "MODEL_TOOL_DIR=%~dp0"
powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $tool=$env:MODEL_TOOL_DIR.TrimEnd('\'); $root=Split-Path -Parent $tool; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Selecciona el respaldo SQL de MySQL'; $d.Filter='Respaldos SQL (*.sql)|*.sql|Todos los archivos (*.*)|*.*'; $d.Multiselect=$false; $d.CheckFileExists=$true; if($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $base=[IO.Path]::GetFileNameWithoutExtension($d.FileName) -replace '[^\p{L}\p{N}._-]','-'; $out=Join-Path $tool (Join-Path 'salidas' ($base+'-'+$stamp)); New-Item -ItemType Directory -Path $out -Force | Out-Null; Push-Location $root; try { & node (Join-Path $tool 'generar.mjs') --input $d.FileName --output-dir $out; if($LASTEXITCODE -ne 0){ exit $LASTEXITCODE } } finally { Pop-Location }; Invoke-Item (Join-Path $out 'modelo-relacional.html') }"
if errorlevel 1 (
  echo.
  echo Ocurrio un error al generar el modelo. Revisa el mensaje anterior.
  pause
  exit /b 1
)
endlocal
