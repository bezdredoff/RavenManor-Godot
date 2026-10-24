param(
	[Parameter(Mandatory = $true)][string]$GodotPath,
	[string]$OutputPath = "build/web/index.html"
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$absoluteOutput = [System.IO.Path]::GetFullPath((Join-Path $projectPath $OutputPath))
$outputDirectory = Split-Path -Parent $absoluteOutput
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$stdoutPath = [System.IO.Path]::GetTempFileName()
$stderrPath = [System.IO.Path]::GetTempFileName()
try {
	$arguments = @('--headless', '--path', $projectPath, '--export-release', 'GitHub Pages Web', $absoluteOutput)
	$escapedArguments = $arguments | ForEach-Object {
		if ($_ -match '[\s"]') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
	}
	$process = Start-Process -FilePath $GodotPath -ArgumentList ($escapedArguments -join ' ') -Wait -PassThru -NoNewWindow `
		-RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
	$stdout = Get-Content -LiteralPath $stdoutPath -Raw
	$stderr = Get-Content -LiteralPath $stderrPath -Raw
	if ($process.ExitCode -ne 0 -or $stderr -match 'SCRIPT ERROR:|ERROR:') {
		throw "Web export failed.`n$stdout`n$stderr"
	}
	foreach ($required in @('index.html', 'index.js', 'index.wasm', 'index.pck')) {
		if (-not (Test-Path -LiteralPath (Join-Path $outputDirectory $required) -PathType Leaf)) {
			throw "Web export is missing $required.`n$stdout`n$stderr"
		}
	}
	Write-Output "Raven Manor Web export passed: $absoluteOutput"
}
finally {
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
}
