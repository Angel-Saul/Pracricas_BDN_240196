$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

$projectRoot = Split-Path -Parent $PSScriptRoot
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = 'Selecciona el respaldo SQL de MySQL'
$dialog.Filter = 'Respaldos SQL (*.sql)|*.sql|Todos los archivos (*.*)|*.*'
$dialog.Multiselect = $false
$dialog.CheckFileExists = $true

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
  Write-Host 'No se seleccionó ningún respaldo.'
  exit 0
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$base = [System.IO.Path]::GetFileNameWithoutExtension($dialog.FileName) -replace '[^\p{L}\p{N}._-]', '-'
$outputDir = Join-Path $PSScriptRoot (Join-Path 'salidas' "$base-$stamp")
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

Push-Location $projectRoot
try {
  & node (Join-Path $PSScriptRoot 'generar.mjs') --input $dialog.FileName --output-dir $outputDir
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}

Invoke-Item (Join-Path $outputDir 'modelo-relacional.html')
