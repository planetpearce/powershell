<#
.PARAMETER Alias
    mdview
.PARAMETER Description
    Renders a Markdown file with custom CSS styling in the default browser. Defaults to README.md in the current directory.
#>
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
        /* ── Planet Pearce Theme ─────────────────────────────────────────────
           Cyan  (#00ffff) = PLANET PEARCE  — primary / top-tier
           Magenta (#ff44ff) = VIOLETTA     — secondary / accent
           ─────────────────────────────────────────────────────────────────── */
        :root {
            --cyan:    #00ffff;
            --magenta: #ff44ff;
            --dim:     #888888;
            --bg:      #0d0d0d;
            --bg2:     #141414;
            --bg3:     #1c1c1c;
            --border:  #2a2a2a;
            --text:    #d0d0d0;
        }

        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
            line-height: 1.7;
            max-width: 860px;
            margin: 48px auto;
            padding: 0 24px;
            color: var(--text);
            background-color: var(--bg);
        }

        /* H1 = Cyan  (PLANET PEARCE tier) */
        h1 {
            color: var(--cyan);
            border-bottom: 1px solid var(--cyan);
            padding-bottom: 8px;
            letter-spacing: 0.03em;
        }

        /* H2 = Magenta  (VIOLETTA tier) */
        h2 {
            color: var(--magenta);
            border-bottom: 1px solid var(--border);
            padding-bottom: 6px;
        }

        /* H3 = soft cyan */
        h3 { color: #66ddee; }

        /* H4+ = dim */
        h4, h5, h6 { color: var(--dim); }

        a { color: var(--cyan); text-decoration: none; }
        a:hover { text-decoration: underline; color: var(--magenta); }

        hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 32px 0;
        }

        blockquote {
            border-left: 3px solid var(--magenta);
            margin: 16px 0;
            padding: 4px 16px;
            color: var(--dim);
            background-color: var(--bg2);
        }

        /* Inline code — magenta accent */
        code {
            font-family: 'Cascadia Code', 'Consolas', monospace;
            background-color: var(--bg3);
            color: var(--magenta);
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 0.9em;
        }

        /* Code blocks — cyan terminal text */
        pre {
            background-color: var(--bg2);
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            border: 1px solid var(--border);
        }
        pre code {
            color: var(--cyan);
            background: none;
            padding: 0;
            font-size: 0.88em;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 24px 0;
        }
        th {
            background-color: var(--bg3);
            color: var(--cyan);
            border: 1px solid var(--border);
            padding: 10px 14px;
            text-align: left;
            letter-spacing: 0.04em;
        }
        td {
            border: 1px solid var(--border);
            padding: 9px 14px;
        }
        tr:nth-child(even) { background-color: var(--bg2); }
        tr:hover { background-color: var(--bg3); }

        /* Keyboard / badge spans */
        kbd {
            background-color: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 4px;
            padding: 2px 6px;
            font-size: 0.85em;
            color: var(--cyan);
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
