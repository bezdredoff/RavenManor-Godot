param(
	[Parameter(Mandatory = $true)][string]$GodotPath,
	[Parameter(Mandatory = $true)][string]$OutputPath,
	[switch]$Unlocked,
	[switch]$Locked
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$absoluteOutput = [System.IO.Path]::GetFullPath($OutputPath)
if (-not $absoluteOutput.EndsWith('.png', [System.StringComparison]::OrdinalIgnoreCase)) {
	throw 'OutputPath must be a PNG file.'
}
$arguments = @('--path', $projectPath, '--resolution', '390x844', 'res://scenes/raven/manor_greybox.tscn', '--', "capture=$absoluteOutput")
if ($Unlocked) { $arguments += 'unlock=true' }
if ($Locked) { $arguments += 'locked=true' }
$stdoutPath = [System.IO.Path]::GetTempFileName()
$stderrPath = [System.IO.Path]::GetTempFileName()
try {
	$process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow `
		-RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
	$stdout = Get-Content -LiteralPath $stdoutPath -Raw
	$stderr = Get-Content -LiteralPath $stderrPath -Raw
	if ($process.ExitCode -ne 0 -or $stderr -match 'SCRIPT ERROR:|ERROR:') {
		throw "Greybox capture failed.`n$stdout`n$stderr"
	}
	if (-not (Test-Path -LiteralPath $absoluteOutput -PathType Leaf)) {
		throw "Greybox did not create $absoluteOutput.`n$stdout`n$stderr"
	}
	Write-Output $stdout
}
finally {
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
}
