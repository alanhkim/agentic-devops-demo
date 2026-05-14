# =============================================================================
# post-provision.ps1 — Configure the SRE Agent after azd up (Windows PowerShell)
# PowerShell equivalent of post-provision.sh
# =============================================================================

$ErrorActionPreference = "Continue"
$JQ_DIR = "C:\Users\alankim\AppData\Local\Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe"
$env:PATH = "$JQ_DIR;C:\Users\alankim\AppData\Local\Programs\Azure Dev CLI;C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;$env:PATH"

$ProjectDir = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectDir

# ── Read azd outputs ─────────────────────────────────────────────────────────
$AGENT_ENDPOINT = azd env get-value SRE_AGENT_ENDPOINT 2>$null
$AGENT_NAME = azd env get-value SRE_AGENT_NAME 2>$null
$RESOURCE_GROUP = azd env get-value AZURE_RESOURCE_GROUP 2>$null
$APP_RESOURCE_GROUP = azd env get-value APP_RESOURCE_GROUP 2>$null
$SUBSCRIPTION_ID = az account show --query id -o tsv 2>$null
$GITHUB_REPO = azd env get-value GITHUB_REPO 2>$null
if (-not $GITHUB_REPO) { $GITHUB_REPO = "https://github.com/alanhkim/agentic-devops-demo" }
# Strip URL prefix to get owner/repo format for API calls
$GITHUB_REPO_SHORT = $GITHUB_REPO -replace "^https://github.com/", ""

$AGENT_RESOURCE_ID = "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.App/agents/${AGENT_NAME}"
$API_VERSION = "2025-05-01-preview"

if (-not $AGENT_ENDPOINT -or -not $AGENT_NAME) {
    Write-Output "ERROR: Could not read agent details from azd environment."
    Write-Output "   Run 'azd up' first, then re-run this script."
    exit 1
}

Write-Output ""
Write-Output "============================================="
Write-Output "  SRE Agent - Post-Provision Setup"
Write-Output "============================================="
Write-Output ""
Write-Output "Agent:     $AGENT_ENDPOINT"
Write-Output "SRE RG:    $RESOURCE_GROUP"
Write-Output "App RG:    $APP_RESOURCE_GROUP"
Write-Output "GitHub:    $GITHUB_REPO_SHORT"
Write-Output ""

# ── Helper: Get bearer token ─────────────────────────────────────────────────
function Get-SreToken {
    az account get-access-token --resource https://azuresre.dev --query accessToken -o tsv 2>$null
}

# ── Helper: Convert subagent YAML to API JSON ────────────────────────────────
function Convert-YamlToApiJson {
    param([string]$YamlFile)
    
    $content = Get-Content $YamlFile -Raw
    $lines = Get-Content $YamlFile

    # Extract name
    $name = ($lines | Where-Object { $_ -match "^  name: " } | Select-Object -First 1) -replace "^  name: *", ""
    
    # Extract handoff_description
    $handoff = ($lines | Where-Object { $_ -match "^  handoff_description: " } | Select-Object -First 1) -replace "^  handoff_description: *", ""

    # Extract system_prompt (multi-line block)
    $inPrompt = $false
    $promptLines = @()
    foreach ($line in $lines) {
        if ($line -match "^  system_prompt: \|") { $inPrompt = $true; continue }
        if ($inPrompt -and $line -match "^  [a-z_]+:") { $inPrompt = $false; continue }
        if ($inPrompt) { $promptLines += ($line -replace "^    ", "") }
    }
    $systemPrompt = $promptLines -join "`n"

    # Substitute GITHUB_REPO_PLACEHOLDER
    $systemPrompt = $systemPrompt -replace "GITHUB_REPO_PLACEHOLDER", $GITHUB_REPO_SHORT
    $handoff = $handoff -replace "GITHUB_REPO_PLACEHOLDER", $GITHUB_REPO_SHORT

    # Extract tools list
    $inTools = $false
    $tools = @()
    foreach ($line in $lines) {
        if ($line -match "^  tools:") { $inTools = $true; continue }
        if ($inTools -and $line -match "^  [a-z_]+:") { $inTools = $false; continue }
        if ($inTools -and $line -match "^    - (.+)") { $tools += $Matches[1] }
    }

    # Build JSON using jq
    $toolsJson = ($tools | ForEach-Object { "`"$_`"" }) -join ","
    $body = @{
        name = $name
        type = "ExtendedAgent"
        tags = @()
        owner = ""
        properties = @{
            instructions = $systemPrompt
            handoffDescription = $handoff
            handoffs = @()
            tools = $tools
            mcpTools = @()
            allowParallelToolCalls = $true
            enableSkills = $true
        }
    } | ConvertTo-Json -Depth 5

    return $body
}

# ── Helper: Create subagent ──────────────────────────────────────────────────
function New-SubAgent {
    param([string]$YamlFile, [string]$AgentName)

    $jsonBody = Convert-YamlToApiJson -YamlFile $YamlFile
    if (-not $jsonBody) {
        Write-Output "   Warning: ${AgentName}: YAML conversion failed"
        return
    }

    $token = Get-SreToken
    try {
        $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v2/extendedAgent/agents/${AgentName}" `
            -Method PUT `
            -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $jsonBody `
            -UseBasicParsing -ErrorAction Stop
        Write-Output "   Created: ${AgentName}"
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Output "   Warning: ${AgentName} returned HTTP ${code}"
    }
}

# ── Helper: Create scheduled task ────────────────────────────────────────────
function New-ScheduledTask {
    param([string]$YamlFile)

    $lines = Get-Content $YamlFile
    $content = Get-Content $YamlFile -Raw

    $taskName = ($lines | Where-Object { $_ -match "^  name: " } | Select-Object -First 1) -replace "^  name: *", ""
    $description = ($lines | Where-Object { $_ -match "^  description: " } | Select-Object -First 1) -replace "^  description: *", ""
    $cronExpr = ($lines | Where-Object { $_ -match "^  cronExpression: " } | Select-Object -First 1) -replace "^  cronExpression: *", "" -replace '"', ''
    $agentName = ($lines | Where-Object { $_ -match "^  agent: " } | Select-Object -First 1) -replace "^  agent: *", "" -replace '"', ''

    # Extract multi-line agentPrompt
    $inPrompt = $false
    $promptLines = @()
    foreach ($line in $lines) {
        if ($line -match "^  agentPrompt: \|") { $inPrompt = $true; continue }
        if ($inPrompt -and $line -match "^  [a-z_]+:" -and $line -notmatch "^    ") { $inPrompt = $false; continue }
        if ($inPrompt -and $line -match "^$") { $inPrompt = $false; continue }
        if ($inPrompt) { $promptLines += ($line -replace "^    ", "") }
    }
    $agentPrompt = $promptLines -join "`n"

    if (-not $taskName -or -not $cronExpr -or -not $agentPrompt) {
        Write-Output "   Warning: Could not parse task YAML: $YamlFile"
        return
    }

    $token = Get-SreToken

    # Delete existing task with same name
    try {
        $existing = Invoke-RestMethod -Uri "${AGENT_ENDPOINT}/api/v1/scheduledtasks" `
            -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing -ErrorAction SilentlyContinue
        foreach ($task in $existing) {
            if ($task.name -eq $taskName -and $task.id) {
                Invoke-RestMethod -Uri "${AGENT_ENDPOINT}/api/v1/scheduledtasks/$($task.id)" `
                    -Method DELETE -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
            }
        }
    } catch {}

    $body = @{
        name = $taskName
        description = $description
        cronExpression = $cronExpr
        agentPrompt = $agentPrompt
    }
    if ($agentName) { $body.agent = $agentName }
    $jsonBody = $body | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v1/scheduledtasks" `
            -Method POST `
            -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $jsonBody `
            -UseBasicParsing -ErrorAction Stop
        Write-Output "   Scheduled: ${taskName} (${cronExpr})"
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Output "   Warning: ${taskName} returned HTTP ${code}"
    }
}

# ── Step 1: Upload knowledge base ────────────────────────────────────────────
Write-Output "Step 1/5: Uploading knowledge base..."
$token = Get-SreToken

$kbFiles = Get-ChildItem "./knowledge-base/*.md"
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = @()
foreach ($f in $kbFiles) {
    $fileContent = [System.IO.File]::ReadAllBytes($f.FullName)
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"files`"; filename=`"$($f.Name)`""
    $bodyLines += "Content-Type: text/plain"
    $bodyLines += ""
    $bodyLines += [System.Text.Encoding]::UTF8.GetString($fileContent)
}
$bodyLines += "--$boundary"
$bodyLines += "Content-Disposition: form-data; name=`"triggerIndexing`""
$bodyLines += ""
$bodyLines += "true"
$bodyLines += "--$boundary--"
$multipartBody = $bodyLines -join $LF

try {
    $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v1/AgentMemory/upload" `
        -Method POST `
        -Headers @{ "Authorization" = "Bearer $token" } `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $multipartBody `
        -UseBasicParsing -ErrorAction Stop
    $kbNames = ($kbFiles | ForEach-Object { $_.Name }) -join " "
    Write-Output "   Uploaded: $kbNames"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Output "   Warning: Upload returned HTTP $code"
}
Write-Output ""

# ── Step 2: Create subagents ─────────────────────────────────────────────────
Write-Output "Step 2/5: Creating subagents..."
New-SubAgent -YamlFile "sre-config/agents/incident-handler.yaml" -AgentName "incident-handler"
New-SubAgent -YamlFile "sre-config/agents/code-analyzer.yaml" -AgentName "code-analyzer"
Write-Output ""

# ── Step 3: Create scheduled tasks ──────────────────────────────────────────
Write-Output "Step 3/5: Creating scheduled tasks..."
foreach ($f in Get-ChildItem "./sre-config/tasks/*.yaml") {
    New-ScheduledTask -YamlFile $f.FullName
}
Write-Output ""

# ── Step 4: Enable Azure Monitor + create response plan ─────────────────────
Write-Output "Step 4/5: Enabling Azure Monitor incident platform..."

$patchBody = '{"properties":{"incidentManagementConfiguration":{"type":"AzMonitor","connectionName":"azmonitor"},"experimentalSettings":{"EnableWorkspaceTools":true,"EnableDevOpsTools":true,"EnablePythonTools":true}}}'
try {
    az rest --method PATCH `
        --url "https://management.azure.com${AGENT_RESOURCE_ID}?api-version=${API_VERSION}" `
        --body $patchBody `
        --output none 2>&1 | Out-Null
    Write-Output "   Azure Monitor enabled + DevOps & Python tools enabled"
} catch {
    Write-Output "   Warning: Could not enable Azure Monitor"
}

Write-Output "   Waiting for Azure Monitor to initialize (30s)..."
Start-Sleep -Seconds 30

# Delete existing filters
$token = Get-SreToken
try {
    Invoke-RestMethod -Uri "${AGENT_ENDPOINT}/api/v1/incidentPlayground/filters/three-rivers-http-errors" `
        -Method DELETE -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
} catch {}

# Create response plan with retry
$filterCreated = $false
for ($attempt = 1; $attempt -le 5; $attempt++) {
    $token = Get-SreToken
    $filterBody = @{
        id = "three-rivers-http-errors"
        name = "Three Rivers Bank HTTP Errors"
        priorities = @("Sev0","Sev1","Sev2","Sev3","Sev4")
        titleContains = ""
        handlingAgent = "incident-handler"
        agentMode = "autonomous"
        maxAttempts = 3
    } | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v1/incidentPlayground/filters/three-rivers-http-errors" `
            -Method PUT `
            -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $filterBody `
            -UseBasicParsing -ErrorAction Stop
        Write-Output "   Response plan -> incident-handler"
        $filterCreated = $true
        break
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 409) {
            Write-Output "   Response plan -> incident-handler (already exists)"
            $filterCreated = $true
            break
        }
        Write-Output "   Attempt ${attempt}/5: HTTP ${code}, retrying in 15s..."
        Start-Sleep -Seconds 15
    }
}

if (-not $filterCreated) {
    Write-Output "   Warning: Response plan failed after 5 attempts"
}

# Delete default quickstart handler
$token = Get-SreToken
try {
    Invoke-RestMethod -Uri "${AGENT_ENDPOINT}/api/v1/incidentPlayground/filters/quickstart_response_plan" `
        -Method DELETE -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
} catch {}

Write-Output ""

# ── Step 5: GitHub OAuth connector + knowledge source ────────────────────────
Write-Output "Step 5/5: GitHub integration..."

$token = Get-SreToken
$connectorBody = '{"name":"github","type":"AgentConnector","properties":{"dataConnectorType":"GitHubOAuth","dataSource":"github-oauth"}}'
try {
    $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v2/extendedAgent/connectors/github" `
        -Method PUT `
        -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
        -Body $connectorBody `
        -UseBasicParsing -ErrorAction Stop
    Write-Output "   GitHub OAuth connector (data plane)"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Output "   Warning: GitHub connector returned HTTP $code"
}

# Also create via ARM
az rest --method PUT `
    --url "https://management.azure.com${AGENT_RESOURCE_ID}/DataConnectors/github?api-version=${API_VERSION}" `
    --body '{"properties":{"dataConnectorType":"GitHubOAuth","dataSource":"github-oauth"}}' `
    -o none 2>&1 | Out-Null
Write-Output "   GitHub OAuth connector (ARM)"

# Get OAuth URL
$token = Get-SreToken
try {
    $configResponse = Invoke-RestMethod -Uri "${AGENT_ENDPOINT}/api/v1/github/config" `
        -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing -ErrorAction SilentlyContinue
    $oauthUrl = if ($configResponse.oAuthUrl) { $configResponse.oAuthUrl } elseif ($configResponse.OAuthUrl) { $configResponse.OAuthUrl } else { "" }
} catch { $oauthUrl = "" }

if ($oauthUrl) {
    Write-Output ""
    Write-Output "  ========================================================"
    Write-Output "    Sign in to GitHub to authorize the SRE Agent:"
    Write-Output "    $oauthUrl"
    Write-Output "    Open this URL in your browser and click 'Authorize'"
    Write-Output "  ========================================================"
    Write-Output ""
    Read-Host "   Press Enter after you have authorized in the browser..."
}

# Add code repo
Write-Output "   Adding ${GITHUB_REPO_SHORT} as knowledge source..."
$token = Get-SreToken
$repoName = ($GITHUB_REPO_SHORT -split "/")[-1]
$repoBody = @{
    name = $repoName
    type = "CodeRepo"
    properties = @{
        url = "https://github.com/${GITHUB_REPO_SHORT}"
        authConnectorName = "github"
    }
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-WebRequest -Uri "${AGENT_ENDPOINT}/api/v2/repos/${repoName}" `
        -Method PUT `
        -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
        -Body $repoBody `
        -UseBasicParsing -ErrorAction Stop
    Write-Output "   Code repo: ${GITHUB_REPO_SHORT}"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Output "   Warning: Code repo returned HTTP $code (authorize GitHub OAuth first, then re-run)"
}

Write-Output ""
Write-Output "============================================="
Write-Output "  SRE Agent Setup Complete!"
Write-Output "============================================="
Write-Output ""
Write-Output "  Agent Portal:  https://sre.azure.com"
Write-Output "  Agent API:     $AGENT_ENDPOINT"
Write-Output "  App RG:        $APP_RESOURCE_GROUP"
Write-Output "  GitHub Repo:   $GITHUB_REPO_SHORT"
Write-Output ""
Write-Output "  Next steps:"
Write-Output "  -- Open https://sre.azure.com and verify green checkmarks"
Write-Output "  -- Ask the agent: 'List all container apps in my resource group'"
Write-Output ""
Write-Output "============================================="
