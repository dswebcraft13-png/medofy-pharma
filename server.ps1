$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Output "Server running at http://localhost:$port/"
$baseDir = $PSScriptRoot

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $rawPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($rawPath)) { $rawPath = 'index.html' }
        $fullPath = [System.IO.Path]::Combine($baseDir, $rawPath)

        if ([System.IO.File]::Exists($fullPath)) {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            $contentType = switch ($ext) {
                '.html' { 'text/html; charset=utf-8' }
                '.css'  { 'text/css; charset=utf-8' }
                '.js'   { 'application/javascript; charset=utf-8' }
                '.png'  { 'image/png' }
                '.jpg'  { 'image/jpeg' }
                '.jpeg' { 'image/jpeg' }
                '.svg'  { 'image/svg+xml' }
                '.mp4'  { 'video/mp4' }
                '.webp' { 'image/webp' }
                Default { 'application/octet-stream' }
            }
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("File not found")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # ignore transient client disconnects
    }
}

