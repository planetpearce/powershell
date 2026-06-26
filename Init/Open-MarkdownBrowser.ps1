function Open-MarkdownBrowser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Path = ".\README.md"
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "The specified Markdown file does not exist: $Path"
        return
    }

    $AbsoluteMarkdownPath = (Get-Item $Path).FullName
    Write-Host "🌐 Rendering with Custom CSS in default browser..." -ForegroundColor Cyan

    # 1. Convert the plain markdown text into an HTML fragment string
    $MarkdownObj = Microsoft.PowerShell.Utility\ConvertFrom-Markdown -Path $AbsoluteMarkdownPath
    $HtmlBody = $MarkdownObj.Html

    # 2. Define your custom CSS injected style sheet payload
    $CustomCSS = @"
    <style>
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #e0e0e0;
            background-color: #121212;
        }
        h1, h2, h3 {
            color: #00ffff; /* Your signature Cyan */
            border-bottom: 1px solid #333;
            padding-bottom: 8px;
        }
        h2 { color: #ffff00; } /* Your signature Yellow */
        code {
            font-family: 'Consolas', monospace;
            background-color: #1e1e1e;
            color: #ffff00; /* Yellow code blocks */
            padding: 2px 6px;
            border-radius: 4px;
        }
        pre {
            background-color: #1e1e1e;
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            border: 1px solid #333;
        }
        pre code {
            color: #00ff00; /* Green pre-formatted code block text */
            padding: 0;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #333;
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #1a1a1a;
            color: #00ffff;
        }
    </style>
"@

    # 3. Combine your CSS template with the generated HTML body framework
    $FullHtmlDocument = @"
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>$($MarkdownObj.Title)</title>
        $CustomCSS
    </head>
    <body>
        $HtmlBody
    </body>
    </html>
"@

    # 4. Save the document into a temporary file on your system and launch it via browser
    $TempHtmlFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "vsmview_$(Get-Random).html")
    Set-Content -Path $TempHtmlFile -Value $FullHtmlDocument -Encoding UTF8

    Start-Process $TempHtmlFile
}

if (Get-Alias mdview -ErrorAction SilentlyContinue) { Remove-Item Alias:mdview }
Set-Alias mdview Open-MarkdownBrowser
