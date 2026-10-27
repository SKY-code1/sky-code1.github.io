<#
.SYNOPSIS
    本地预览作品集：在 http://127.0.0.1:8080 起一个静态服务器。

.DESCRIPTION
    不依赖 Node / Python，只用 .NET 的 HttpListener。
    支持 HEAD、Range（视频可拖动进度条）与自定义 404 页面。
    按 Ctrl+C 或关闭窗口结束。

.PARAMETER Port
    端口，默认 8080。被占用时换一个，例如 -Port 8081。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File preview.ps1
#>
[CmdletBinding()]
param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$mime = @{
    '.html'  = 'text/html; charset=utf-8'
    '.css'   = 'text/css; charset=utf-8'
    '.js'    = 'application/javascript; charset=utf-8'
    '.json'  = 'application/json; charset=utf-8'
    '.svg'   = 'image/svg+xml'
    '.png'   = 'image/png'
    '.jpg'   = 'image/jpeg'
    '.jpeg'  = 'image/jpeg'
    '.webp'  = 'image/webp'
    '.ico'   = 'image/x-icon'
    '.txt'   = 'text/plain; charset=utf-8'
    '.md'    = 'text/plain; charset=utf-8'
    '.woff2' = 'font/woff2'
    '.mp4'   = 'video/mp4'
    '.webm'  = 'video/webm'
    '.pdf'   = 'application/pdf'
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "无法监听 $prefix —— 端口可能被占用，试试 -Port 8081" -ForegroundColor Red
    exit 1
}

Write-Host "作品集预览：$prefix" -ForegroundColor Green
Write-Host "根目录：$root" -ForegroundColor DarkGray
Write-Host "按 Ctrl+C 结束`n" -ForegroundColor DarkGray

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
    } catch {
        break
    }

    $req = $ctx.Request
    $res = $ctx.Response
    $path = $req.Url.AbsolutePath

    try {
        $path = [Uri]::UnescapeDataString($path)
        if ($path -eq '/' -or $path -eq '') { $path = '/index.html' }

        $full = Join-Path $root ($path.TrimStart('/') -replace '/', '\')
        if (Test-Path -LiteralPath $full -PathType Container) {
            $full = Join-Path $full 'index.html'
        }

        $fullResolved = [IO.Path]::GetFullPath($full)
        $inside = $fullResolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)

        if (-not $inside -or -not (Test-Path -LiteralPath $fullResolved -PathType Leaf)) {
            $res.StatusCode = 404
            $notFound = Join-Path $root '404.html'
            if (Test-Path -LiteralPath $notFound) {
                $nb = [IO.File]::ReadAllBytes($notFound)
                $res.ContentType = 'text/html; charset=utf-8'
                $res.ContentLength64 = $nb.Length
                if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($nb, 0, $nb.Length) }
            }
            $res.Close()
            Write-Host "404  $path" -ForegroundColor DarkYellow
            continue
        }

        $bytes = [IO.File]::ReadAllBytes($fullResolved)
        $total = $bytes.Length
        $ext = [IO.Path]::GetExtension($fullResolved).ToLowerInvariant()
        $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $res.Headers.Add('Accept-Ranges', 'bytes')
        $res.Headers.Add('Cache-Control', 'no-cache')

        $range = $req.Headers['Range']
        if ($range -and $range -match 'bytes=(\d*)-(\d*)') {
            $start = if ($matches[1]) { [int]$matches[1] } else { 0 }
            $end = if ($matches[2]) { [int]$matches[2] } else { $total - 1 }

            if ($start -ge $total) {
                $res.StatusCode = 416
                $res.Headers.Add('Content-Range', "bytes */$total")
                $res.Close()
                continue
            }
            if ($end -ge $total) { $end = $total - 1 }
            $len = $end - $start + 1

            $res.StatusCode = 206
            $res.Headers.Add('Content-Range', "bytes $start-$end/$total")
            $res.ContentLength64 = $len
            if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, $start, $len) }
        } else {
            $res.ContentLength64 = $total
            if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, 0, $total) }
        }

        $res.Close()
        Write-Host ("200  {0}" -f $path) -ForegroundColor DarkGray
    } catch {
        try {
            $res.StatusCode = 500
            $res.Close()
        } catch { }
        Write-Host "500  $path  $($_.Exception.Message)" -ForegroundColor Red
    }
}

$listener.Stop()
$listener.Close()
