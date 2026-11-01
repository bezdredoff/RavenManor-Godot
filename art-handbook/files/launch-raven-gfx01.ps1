$ErrorActionPreference = "Stop"

$sandboxRoot = "D:\AI\RavenManor-GFX01-20261027"
$sharedRoot = "D:\AI\ComfyUI-Desktop"
$python = Join-Path $sharedRoot ".venv\Scripts\python.exe"
$main = Join-Path $sandboxRoot "core\main.py"
$stdout = Join-Path $sandboxRoot "logs\comfyui.stdout.log"
$stderr = Join-Path $sandboxRoot "logs\comfyui.stderr.log"
$cacheRoot = Join-Path $sandboxRoot "cache"
$serverUrl = "http://127.0.0.1:8189"

# Reuse only this sandbox, and leave other ComfyUI instances alone.
try {
    $existing = Invoke-RestMethod "$serverUrl/system_stats" -TimeoutSec 3
} catch { $existing = $null }
if ($existing) {
    if ($existing.system.argv -contains $main) {
        Write-Output "Raven ComfyUI is already ready: $serverUrl"
        return
    }
    throw "Port 8189 belongs to another server. Stop it or choose another port."
}

$env:HF_HOME = Join-Path $cacheRoot "huggingface"
$env:HUGGINGFACE_HUB_CACHE = Join-Path $env:HF_HOME "hub"
$env:TORCH_HOME = Join-Path $cacheRoot "torch"
$env:XDG_CACHE_HOME = $cacheRoot

New-Item -ItemType Directory -Force -Path $env:HUGGINGFACE_HUB_CACHE, $env:TORCH_HOME | Out-Null

if (-not (Test-Path -LiteralPath $python)) { throw "Python not found: $python" }
if (-not (Test-Path -LiteralPath $main)) { throw "ComfyUI main.py not found: $main" }

$arguments = @(
    "-s", $main,
    "--listen", "127.0.0.1",
    "--port", "8189",
    "--base-directory", $sandboxRoot,
    "--user-directory", (Join-Path $sandboxRoot "user"),
    "--database-url", "sqlite:///D:/AI/RavenManor-GFX01-20261027/user/comfyui.db",
    "--input-directory", (Join-Path $sandboxRoot "input"),
    "--output-directory", (Join-Path $sandboxRoot "output"),
    "--temp-directory", (Join-Path $sandboxRoot "temp"),
    "--extra-model-paths-config", (Join-Path $sandboxRoot "extra_model_paths.yaml"),
    "--disable-auto-launch",
    "--fast-disk",
    "--vram-headroom", "0.5"
)

$process = Start-Process -FilePath $python -ArgumentList $arguments -WorkingDirectory (Join-Path $sandboxRoot "core") -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
Write-Output "Started Raven GFX-01 ComfyUI sandbox: PID=$($process.Id), URL=http://127.0.0.1:8189"
$deadline = (Get-Date).AddMinutes(4)
while ((Get-Date) -lt $deadline) {
    try {
        $ready = Invoke-RestMethod "$serverUrl/system_stats" -TimeoutSec 2
        if ($ready.system.argv -contains $main) {
            Write-Output "Raven ComfyUI is ready: $serverUrl"
            return
        }
    } catch { }
    $process.Refresh()
    if ($process.HasExited) {
        throw "ComfyUI exited during startup. See $stderr"
    }
    Start-Sleep -Seconds 2
}
throw "ComfyUI did not become ready within four minutes. See $stderr"
