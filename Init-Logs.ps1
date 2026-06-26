# =====================================================================
# Automatic DevOps Logging Framework
# =====================================================================

# 1. Establish logging directories inside your Dev Drive workspace
$GlobalLogDir = "D:\PowerShell\.logs"
if (-not (Test-Path $GlobalLogDir)) {
    New-Item -ItemType Directory -Path $GlobalLogDir -Force | Out-Null
}

# 2. Start an automatic session text transcript
$DateStamp      = Get-Date -Format "yyyy-MM-dd"
$TranscriptFile = Join-Path $GlobalLogDir "ConsoleSession_$DateStamp.log"

# Only start transcription if it isn't already running in this thread
$ErrorActionPreference = "SilentlyContinue"
Start-Transcript -Path $TranscriptFile -Append -NoClobber | Out-Null
$ErrorActionPreference = "Continue"

Write-Host "👨‍🚀 Log Transcripts Initialized" -ForegroundColor Cyan

# 3. Create a structured function to log custom script executions
function Write-DevOpsLog {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptName,
        [Parameter(Mandatory=$true)][string]$Status, # e.g., Success, Failed
        [string]$Message = ""
    )
    
    $LogPayload = [ordered]@{
        Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        User       = $env:USERNAME
        Computer   = $env:COMPUTERNAME
        Script     = $ScriptName
        Status     = $Status
        Details    = $Message
        PSVersion  = $PSVersionTable.PSVersion.ToString()
    }
    
    # Convert to a tight, single-line JSON string and append to audit file
    $JsonLogFile = Join-Path $GlobalLogDir "DevOpsAudit.json"
    ($LogPayload | ConvertTo-Json -Compress) | Out-File -FilePath $JsonLogFile -Append -Encoding utf8
}
