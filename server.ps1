$root = Split-Path $PSScriptRoot -Parent
$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
} catch {
    Write-Host "Port $port is in use. Close the program using it, or change port to 8001 in this file." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Multi-project local server (PowerShell)" -ForegroundColor Cyan
Write-Host "  Root: $root" -ForegroundColor Cyan
Write-Host "  Open: http://localhost:$port" -ForegroundColor Cyan
Write-Host "  Close this window to stop the server" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$types = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
}

# Build a simple project list page from subfolders that contain index.html
function Get-IndexPage {
    $items = Get-ChildItem -Path $root -Directory | Sort-Object Name | ForEach-Object {
        $entry = Join-Path $_.FullName 'index.html'
        if (Test-Path $entry -PathType Leaf) {
            "<li><a href='/$($_.Name)/'>$($_.Name)</a></li>"
        }
    }
    $list = ($items -join "`n")
    $html = "<!DOCTYPE html><html lang='zh-CN'><head><meta charset='UTF-8'><title>Projects</title>" +
            "<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 16px}" +
            "li{margin:10px 0;font-size:18px}a{text-decoration:none;color:#1565c0}</style></head>" +
            "<body><h1>Local projects</h1><ul>$list</ul></body></html>"
    return [System.Text.Encoding]::UTF8.GetBytes($html)
}

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $urlPath = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
        $relPath = $urlPath.TrimStart('/') -replace '/', '\'
        $filePath = Join-Path $root $relPath

        # Root: show project list
        if ($urlPath -eq '/' -or [string]::IsNullOrWhiteSpace($relPath)) {
            $bytes = Get-IndexPage
            $ctx.Response.ContentType = 'text/html; charset=utf-8'
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $ctx.Response.OutputStream.Close()
            continue
        }

        # Folder path without trailing file: serve its index.html
        if (Test-Path $filePath -PathType Container) {
            $filePath = Join-Path $filePath 'index.html'
        }

        # Security: block path traversal (../) escaping the root folder
        $fullRoot = (Resolve-Path $root).Path
        if (Test-Path $filePath -PathType Leaf) {
            $fullFile = (Resolve-Path $filePath).Path
            if (-not $fullFile.StartsWith($fullRoot)) {
                $ctx.Response.StatusCode = 403
                $msg = [System.Text.Encoding]::UTF8.GetBytes('403 Forbidden')
                $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
                $ctx.Response.OutputStream.Close()
                continue
            }

            $ext = [System.IO.Path]::GetExtension($filePath)
            if ($types.ContainsKey($ext)) {
                $contentType = $types[$ext]
            } else {
                $contentType = 'application/octet-stream'
            }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ctx.Response.ContentType = $contentType
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found: ' + $urlPath)
            $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $ctx.Response.OutputStream.Close()
    } catch {
        # Single request error (e.g. browser refresh disconnect) is ignored
    }
}
