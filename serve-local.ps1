param(
    [int]$Port = 8080,
    [string]$Root = $PSScriptRoot
)

$mimeMap = @{
    '.html' = 'text/html; charset=utf-8'
    '.htm'  = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.woff' = 'font/woff'
    '.woff2'= 'font/woff2'
    '.qt'   = 'video/quicktime'
    '.mp4'  = 'video/mp4'
    '.txt'  = 'text/plain; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving '$Root' at http://localhost:$Port/  (Ctrl+C to stop)"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
        if ($localPath -eq '/') { $localPath = '/index.html' }

        $filePath = Join-Path $Root ($localPath.TrimStart('/'))

        if (-not (Test-Path $filePath -PathType Leaf)) {
            $altPath = Join-Path $Root ($localPath.TrimStart('/') + '.html')
            if (Test-Path $altPath -PathType Leaf) {
                $filePath = $altPath
            }
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
            $contentType = $mimeMap[$ext]
            if (-not $contentType) { $contentType = 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $localPath")
            $response.StatusCode = 404
            $response.ContentLength64 = $notFound.Length
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }

        $response.OutputStream.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
