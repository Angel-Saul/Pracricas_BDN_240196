@echo off
setlocal
set "MODEL_TOOL_DIR=%~dp0"
echo [respaldo] Iniciando generacion del modelo.
powershell.exe -NoProfile -Command "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Windows.Forms; $tool=$env:MODEL_TOOL_DIR.TrimEnd('\'); $root=Split-Path -Parent $tool; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Selecciona el respaldo SQL de MySQL'; $d.Filter='Respaldos SQL (*.sql)|*.sql|Todos los archivos (*.*)|*.*'; $d.Multiselect=$false; $d.CheckFileExists=$true; if($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ Write-Host ('[respaldo] Archivo seleccionado: '+$d.FileName); $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $base=[IO.Path]::GetFileNameWithoutExtension($d.FileName) -replace '[^\p{L}\p{N}._-]','-'; $out=Join-Path $tool (Join-Path 'salidas' ($base+'-'+$stamp)); New-Item -ItemType Directory -Path $out -Force | Out-Null; Write-Host ('[respaldo] Carpeta de salida preparada: '+$out); Push-Location $root; try { & node (Join-Path $tool 'generar.mjs') --input $d.FileName --output-dir $out; $code=$LASTEXITCODE; if($code -ne 0){ Write-Error ('El generador termino con codigo '+$code); exit $code } } finally { Pop-Location }; $html=Join-Path $out 'modelo-relacional.html'; if(-not (Test-Path -LiteralPath $html)){ throw ('No se genero el HTML esperado: '+$html) }; Write-Host ('[respaldo] Abriendo: '+$html); Invoke-Item $html } else { Write-Host '[respaldo] Seleccion cancelada.' }"
if errorlevel 1 (
  echo [respaldo] ERROR: la generacion fallo. Consulta las lineas anteriores.
  pause
  exit /b 1
)
echo [respaldo] Proceso finalizado.
endlocal
