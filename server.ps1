# server.ps1 - Static file server (Windows built-in PowerShell, no install needed)
$root = $PSScriptRoot
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
Write-Host "  Dashboard local server (PowerShell)" -ForegroundColor Cyan
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

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $urlPath = $ctx.Request.Url.AbsolutePath
        if ($urlPath -eq '/') { $urlPath = '/index.html' }
        $relPath = $urlPath.TrimStart('/') -replace '/', '\'
        $filePath = Join-Path $root $relPath

        if (Test-Path $filePath -PathType Leaf) {
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
