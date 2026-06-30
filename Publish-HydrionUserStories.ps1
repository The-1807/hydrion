[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Repository = 'vebbaybi/hydrion',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectOwner = 'vebbaybi',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName = 'Hydrion App',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StatusOptionName = 'Product Backlog',

    [Parameter()]
    [string]$MarkdownPath,

    [Parameter()]
    [ValidateRange(1000, 10000)]
    [int]$MutationDelayMilliseconds = 1300,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DefaultProjectColumn = 'Product Backlog',

    [Parameter()]
    [string[]]$AllowedProjectColumns = @('Ice Box', 'Product Backlog'),

    [Parameter()]
    [string[]]$AllowedStorySizes = @('XS', 'S', 'M', 'L', 'XL'),

    [Parameter()]
    [string[]]$StorySizeProjectFieldNames = @('Story Size', 'Size', 'Estimate', 'Story Points', 'Points'),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BackupDirectory = '.hydrion-backups',

    [Parameter()]
    [switch]$SkipProjectRankSync,

    [Parameter()]
    [switch]$AllowExistingNumberedItems,

    [Parameter()]
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$ExpectedStoryCount = 51
$IssueLabel = 'user-story'
$IssueLabelColor = '5319E7'
$IssueLabelDescription = 'Hydrion product user story'
$DefaultLabelColor = 'C5DEF5'
$DefaultLabelDescription = 'Hydrion user-story metadata'
$ScriptVersion = '2.0.1-secret-safe-story-sync'
$ForbiddenStoryPatterns = @(
    'Story Quality Checklist',
    'INVEST Check',
    'Definition of Ready',
    'Definition of Done',
    'Acceptance Criteria Coverage',
    'Repository Evidence',
    'No additional product assumption is made beyond the repository evidence',
    'Keep the behavior offline-tolerant and honest about local-first limits',
    'Keep user-visible behavior responsive',
    'Do not expose secrets or disabled integrations in a misleading way',
    'Remaining end-to-end user behavior is implemented, verified, and ready for release',
    'ready to pull or maintain',
    'all acceptance criteria are checked',
    'the story has no open gaps',
    'generic CI',
    'generic testing',
    'Post-MVP Post-MVP'
)
$SecretLikePatterns = @(
    @{
        Name = 'Google API key'
        Pattern = 'AIza[0-9A-Za-z_-]{35}'
        Group = 0
        RequireSecretLikeValue = $false
    },
    @{
        Name = 'OpenAI API key'
        Pattern = 'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}'
        Group = 0
        RequireSecretLikeValue = $false
    },
    @{
        Name = 'Anthropic API key'
        Pattern = 'sk-ant-[A-Za-z0-9_-]{32,}'
        Group = 0
        RequireSecretLikeValue = $false
    },
    @{
        Name = 'Private key block'
        Pattern = '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----'
        Group = 0
        RequireSecretLikeValue = $false
    },
    @{
        Name = 'Authorization bearer token'
        Pattern = '(?i)\bAuthorization\s*[:=]\s*Bearer\s+([A-Za-z0-9._~+/\-]+=*)'
        Group = 1
        RequireSecretLikeValue = $true
    },
    @{
        Name = 'Provider API key header'
        Pattern = '(?i)\bx-goog-api-key\s*[:=]\s*[''"]?([^''"\s,;}]+)'
        Group = 1
        RequireSecretLikeValue = $true
    },
    @{
        Name = 'Credential assignment'
        Pattern = '(?i)\b(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|password|secret)\s*[:=]\s*[''"]?([^''"\s,;}]+)'
        Group = 1
        RequireSecretLikeValue = $true
    },
    @{
        Name = 'Credential URL'
        Pattern = '://[^/\s:@]+:([^@\s/]+)@'
        Group = 1
        RequireSecretLikeValue = $false
    },
    @{
        Name = 'Credential query parameter'
        Pattern = '(?i)[?&](?:api_key|key|token|access_token|client_secret)=([^&#\s]+)'
        Group = 1
        RequireSecretLikeValue = $true
    }
)

function Test-DocumentedSecretPlaceholder {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    $normalized = $Value.Trim().Trim('"', "'")

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }

    if (Test-KnownSecretFormat -Value $normalized) {
        return $false
    }

    $upper = $normalized.ToUpperInvariant()

    return (
        ($upper -match '^(YOUR|EXAMPLE|SAMPLE|PLACEHOLDER)[A-Z0-9_.:-]*$') -or
        ($upper -match '^\$\{?[A-Z][A-Z0-9_]*(API_KEY|TOKEN|SECRET|PASSWORD|CREDENTIALS?|ORG_ID)\}?$') -or
        ($upper -match '^\$ENV:[A-Z][A-Z0-9_]*$') -or
        ($upper.Contains('TEST-KEY')) -or
        ($upper.Contains('TEST_KEY')) -or
        ($upper -in @('REPLACE_ME', 'NOT_A_REAL_KEY', 'TEST_PLACEHOLDER_NOT_A_REAL_KEY', '<YOUR_API_KEY>', '<API_KEY>', '...'))
    )
}

function Test-KnownSecretFormat {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    return (
        ($Value -match 'AIza[0-9A-Za-z_-]{35}') -or
        ($Value -match 'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}') -or
        ($Value -match 'sk-ant-[A-Za-z0-9_-]{32,}') -or
        ($Value -match '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----')
    )
}

function Test-SecretLikeValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    $normalized = $Value.Trim().Trim('"', "'")

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }

    if (Test-DocumentedSecretPlaceholder -Value $normalized) {
        return $false
    }

    if (Test-KnownSecretFormat -Value $normalized) {
        return $true
    }

    if ($normalized.Length -lt 16) {
        return $false
    }

    if ($normalized -match '^[A-Za-z_][A-Za-z0-9_.]*(?:\([^)]*\))?$') {
        return $false
    }

    if ($normalized -match '^[A-Za-z_][A-Za-z0-9_.]*\($') {
        return $false
    }

    $hasLetter = $normalized -match '[A-Za-z]'
    $hasDigit = $normalized -match '\d'
    $hasTokenSeparator = $normalized -match '[._~+/\-=]'

    return ($hasLetter -and ($hasDigit -or $hasTokenSeparator))
}

function Assert-NoSecretLikeContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Context
    )

    foreach ($secretPattern in $SecretLikePatterns) {
        foreach ($match in [regex]::Matches($Text, $secretPattern.Pattern)) {
            $value = $match.Value

            if (($secretPattern.Group -gt 0) -and ($match.Groups.Count -gt $secretPattern.Group)) {
                $value = $match.Groups[$secretPattern.Group].Value
            }

            if (Test-DocumentedSecretPlaceholder -Value $value) {
                continue
            }

            if (($secretPattern.RequireSecretLikeValue) -and (-not (Test-SecretLikeValue -Value $value))) {
                continue
            }

            throw "Refusing to send secret-looking content to GitHub: $($secretPattern.Name) in $Context."
        }
    }
}

function Assert-HydrionGithubMutationSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Story,
        [Parameter(Mandatory)][string]$Action
    )

    Assert-NoSecretLikeContent -Text $Story.IssueTitle -Context "$Action title for $($Story.Id)"
    Assert-NoSecretLikeContent -Text $Story.Body -Context "$Action body for $($Story.Id)"
    Assert-NoSecretLikeContent -Text (@($Story.Labels) -join ', ') -Context "$Action labels for $($Story.Id)"

    if (-not [string]::IsNullOrWhiteSpace($Story.Milestone)) {
        Assert-NoSecretLikeContent -Text $Story.Milestone -Context "$Action milestone for $($Story.Id)"
    }

    Assert-NoSecretLikeContent -Text $Story.ProjectColumn -Context "$Action project column for $($Story.Id)"
    Assert-NoSecretLikeContent -Text $Story.StorySize -Context "$Action story size for $($Story.Id)"
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Text)
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Text)
    Write-Host $Text -ForegroundColor Gray
}

function Invoke-Gh {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter()]
        [switch]$AllowFailure
    )

    $previousErrorActionPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        $rawOutput = @(& gh @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $text = (($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()

    if (($exitCode -ne 0) -and (-not $AllowFailure)) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            $text = 'GitHub CLI returned no error text.'
        }

        throw "gh $($Arguments -join ' ') failed with exit code $exitCode.`n$text"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $text
    }
}

function Invoke-GhJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $result = Invoke-Gh -Arguments $Arguments

    if ([string]::IsNullOrWhiteSpace($result.Output)) {
        return $null
    }

    try {
        return ($result.Output | ConvertFrom-Json)
    }
    catch {
        throw "GitHub CLI returned invalid JSON for: gh $($Arguments -join ' ')`n$($result.Output)"
    }
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Invoke-GhGraphQL {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)][hashtable]$Variables
    )

    $tempPath = [System.IO.Path]::GetTempFileName()

    try {
        $payload = [ordered]@{
            query     = $Query
            variables = $Variables
        } | ConvertTo-Json -Depth 30

        Write-Utf8NoBom -Path $tempPath -Content $payload

        $response = Invoke-GhJson -Arguments @(
            'api',
            'graphql',
            '--input',
            $tempPath
        )

        if (($null -ne $response) -and ($response.PSObject.Properties.Match('errors').Count -gt 0)) {
            $messages = @($response.errors | ForEach-Object { $_.message }) -join '; '
            throw "GitHub GraphQL error: $messages"
        }

        return $response
    }
    finally {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

function Test-IsRateLimitError {
    param([Parameter(Mandatory)][string]$Message)

    return ($Message -match '(?i)rate limit|secondary rate|HTTP 403|HTTP 429|abuse detection')
}

function Invoke-MutationWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$Operation,
        [Parameter(Mandatory)][string]$Description
    )

    $maximumAttempts = 5

    for ($attempt = 1; $attempt -le $maximumAttempts; $attempt++) {
        try {
            $result = & $Operation
            Start-Sleep -Milliseconds $MutationDelayMilliseconds
            return $result
        }
        catch {
            $message = $_.Exception.Message

            if ((Test-IsRateLimitError -Message $message) -and ($attempt -lt $maximumAttempts)) {
                $delaySeconds = [Math]::Min(120, 15 * [Math]::Pow(2, ($attempt - 1)))
                Write-Warning "$Description was rate-limited. Retrying in $delaySeconds seconds. Attempt $attempt of $maximumAttempts."
                Start-Sleep -Seconds ([int]$delaySeconds)
                continue
            }

            throw
        }
    }

    throw "$Description failed after $maximumAttempts attempts."
}

function Resolve-MarkdownPath {
    param([string]$RequestedPath)

    $baseDirectory = $null

    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $baseDirectory = $PSScriptRoot
    }
    else {
        $baseDirectory = (Get-Location).Path
    }

    if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
        $RequestedPath = Join-Path -Path $baseDirectory -ChildPath 'Hydrion_UserStories.md'
    }

    if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
        throw "User-story source file was not found: $RequestedPath"
    }

    return (Resolve-Path -LiteralPath $RequestedPath).Path
}

function Get-MarkdownMetadataValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$Name
    )

    $pattern = '(?m)^\*\*{0}:\*\*\s*(.+?)\s*$' -f [regex]::Escape($Name)
    $match = [regex]::Match($Body, $pattern)

    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Get-UniqueStrings {
    [CmdletBinding()]
    param([Parameter()][AllowEmptyCollection()][string[]]$Values = @())

    $result = New-Object System.Collections.Generic.List[string]
    $seen = @{}

    foreach ($value in $Values) {
        $normalized = $value.Trim()

        if ([string]::IsNullOrWhiteSpace($normalized)) {
            continue
        }

        $key = $normalized.ToLowerInvariant()

        if ($seen.ContainsKey($key)) {
            continue
        }

        $seen[$key] = $true
        $result.Add($normalized)
    }

    return @($result)
}

function Convert-MarkdownLabelList {
    [CmdletBinding()]
    param(
        [Parameter()][AllowNull()][string]$Value,
        [Parameter(Mandatory)][string]$StoryId
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    $labels = @(
        $Value.Replace('`', '') -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    foreach ($label in $labels) {
        if ($label.Length -gt 50) {
            throw "$StoryId label '$label' is longer than GitHub's 50-character label-name limit."
        }

        if ($label -match "[`r`n]") {
            throw "$StoryId label '$label' contains a line break."
        }
    }

    return Get-UniqueStrings -Values $labels
}

function Get-StorySize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$StoryId
    )

    $sizeText = Get-MarkdownMetadataValue -Body $Body -Name 'T-shirt Size'

    if ([string]::IsNullOrWhiteSpace($sizeText)) {
        throw "$StoryId is missing required metadata field 'T-shirt Size'."
    }

    $sizeText = $sizeText.Replace('`', '').Trim().ToUpperInvariant()

    if ($sizeText -match '^\d+$') {
        throw "$StoryId uses numeric story size '$sizeText'. Use XS, S, M, L, or XL."
    }

    $allowed = @($AllowedStorySizes | ForEach-Object { $_.ToUpperInvariant() })

    if (-not ($allowed -contains $sizeText)) {
        throw "$StoryId T-shirt size '$sizeText' is not allowed. Allowed sizes: $(@($AllowedStorySizes) -join ', ')."
    }

    return $sizeText
}

function Get-StoryLabels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$StoryId
    )

    $labels = @(
        Convert-MarkdownLabelList `
            -Value (Get-MarkdownMetadataValue -Body $Body -Name 'Labels') `
            -StoryId $StoryId
    )

    if (-not (@($labels) | Where-Object { [string]::Equals($_, $IssueLabel, [System.StringComparison]::OrdinalIgnoreCase) })) {
        $labels = @($IssueLabel) + @($labels)
    }

    $sizeLabel = 'size:{0}' -f ((Get-StorySize -Body $Body -StoryId $StoryId).ToLowerInvariant())

    if (-not (@($labels) | Where-Object { [string]::Equals($_, $sizeLabel, [System.StringComparison]::OrdinalIgnoreCase) })) {
        $labels += $sizeLabel
    }

    return Get-UniqueStrings -Values $labels
}

function Get-StoryMilestone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$StoryId
    )

    $milestone = Get-MarkdownMetadataValue -Body $Body -Name 'Milestone'

    if ([string]::IsNullOrWhiteSpace($milestone)) {
        return $null
    }

    $milestone = $milestone.Replace('`', '').Trim()

    if ($milestone.Length -gt 100) {
        throw "$StoryId milestone '$milestone' is longer than GitHub's 100-character milestone-title limit."
    }

    if ($milestone -match "[`r`n]") {
        throw "$StoryId milestone '$milestone' contains a line break."
    }

    return $milestone
}

function Get-StoryProjectColumn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$StoryId
    )

    $column = Get-MarkdownMetadataValue -Body $Body -Name 'Project Column'

    if ([string]::IsNullOrWhiteSpace($column)) {
        $column = $DefaultProjectColumn
    }

    $column = $column.Replace('`', '').Trim()
    $matchingColumns = @(
        @($AllowedProjectColumns) | Where-Object {
            [string]::Equals($_, $column, [System.StringComparison]::OrdinalIgnoreCase)
        }
    )

    if ($matchingColumns.Count -ne 1) {
        throw "$StoryId project column '$column' is not allowed. Allowed columns: $(@($AllowedProjectColumns) -join ', ')."
    }

    return $matchingColumns[0]
}

function Get-StoryBusinessRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$StoryId,
        [Parameter(Mandatory)][int]$FallbackRank
    )

    $rankText = Get-MarkdownMetadataValue -Body $Body -Name 'Business Rank'

    if ([string]::IsNullOrWhiteSpace($rankText)) {
        return $FallbackRank
    }

    $rankText = $rankText.Replace('`', '').Trim()
    $rank = 0

    if (-not [int]::TryParse($rankText, [ref]$rank)) {
        throw "$StoryId business rank '$rankText' is not an integer."
    }

    if ($rank -lt 1) {
        throw "$StoryId business rank must be greater than zero."
    }

    return $rank
}

function Get-HydrionStories {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $content = [System.IO.File]::ReadAllText($Path)
    $content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    Assert-NoSecretLikeContent -Text $content -Context "user-story source '$Path'"

    $pattern = '(?ms)^###\s+(HYD-US-(\d{3})):\s+([^\n]+)\n(.*?)(?=^###\s+HYD-US-\d{3}:|\z)'
    $matches = [regex]::Matches($content, $pattern)

    if ($matches.Count -eq 0) {
        throw "No Hydrion user stories were found. Expected headings such as '### HYD-US-001: Story title'."
    }

    $stories = New-Object System.Collections.Generic.List[object]
    $seenIds = @{}

    foreach ($match in $matches) {
        $id = $match.Groups[1].Value.Trim()
        $sequence = [int]$match.Groups[2].Value
        $shortTitle = $match.Groups[3].Value.Trim()
        $body = $match.Groups[4].Value.Trim()
        $labels = $null
        $milestone = $null
        $storySize = 0
        $projectColumn = $null
        $businessRank = 0

        if ($seenIds.ContainsKey($id)) {
            throw "Duplicate user-story ID found in Markdown: $id"
        }

        if ([string]::IsNullOrWhiteSpace($shortTitle)) {
            throw "Story $id has an empty title."
        }

        if ([string]::IsNullOrWhiteSpace($body)) {
            throw "Story $id has an empty issue body."
        }

        $labels = @(Get-StoryLabels -Body $body -StoryId $id)
        $milestone = Get-StoryMilestone -Body $body -StoryId $id
        $storySize = Get-StorySize -Body $body -StoryId $id
        $projectColumn = Get-StoryProjectColumn -Body $body -StoryId $id
        $businessRank = Get-StoryBusinessRank -Body $body -StoryId $id -FallbackRank $sequence

        if ($labels.Count -eq 0) {
            throw "Story $id has no GitHub labels."
        }

        $issueTitle = "$id`: $shortTitle"

        if ($issueTitle.Length -gt 256) {
            throw "Story $id produces a GitHub issue title longer than 256 characters."
        }

        if ($body.Length -gt 65000) {
            throw "Story $id produces a GitHub issue body longer than the supported safe limit."
        }

        Assert-NoSecretLikeContent -Text $issueTitle -Context "$id issue title"
        Assert-NoSecretLikeContent -Text $body -Context "$id issue body"
        Assert-NoSecretLikeContent -Text (@($labels) -join ', ') -Context "$id labels"

        if (-not [string]::IsNullOrWhiteSpace($milestone)) {
            Assert-NoSecretLikeContent -Text $milestone -Context "$id milestone"
        }

        Assert-NoSecretLikeContent -Text $projectColumn -Context "$id project column"
        Assert-NoSecretLikeContent -Text $storySize -Context "$id story size"

        $seenIds[$id] = $true

        $stories.Add([pscustomobject]@{
            Id         = $id
            Sequence   = $sequence
            ShortTitle = $shortTitle
            IssueTitle = $issueTitle
            Body       = $body
            Labels     = $labels
            Milestone  = $milestone
            StorySize  = $storySize
            ProjectColumn = $projectColumn
            BusinessRank = $businessRank
        })
    }

    $orderedStories = @($stories | Sort-Object Sequence)

    if ($orderedStories.Count -ne $ExpectedStoryCount) {
        throw "Expected $ExpectedStoryCount stories, but parsed $($orderedStories.Count)."
    }

    for ($index = 1; $index -le $ExpectedStoryCount; $index++) {
        $expectedId = 'HYD-US-{0:D3}' -f $index
        $actualId = $orderedStories[$index - 1].Id

        if ($actualId -ne $expectedId) {
            throw "Story sequence is invalid. Expected $expectedId at position $index, but found $actualId."
        }
    }

    $duplicateRanks = @(
        $orderedStories |
            Group-Object ProjectColumn, BusinessRank |
            Where-Object { $_.Count -gt 1 }
    )

    if ($duplicateRanks.Count -gt 0) {
        $details = @(
            $duplicateRanks | ForEach-Object {
                $storyIds = @($_.Group | ForEach-Object { $_.Id }) -join ', '
                "$($_.Name): $storyIds"
            }
        ) -join [Environment]::NewLine

        throw "Duplicate business ranks were found within a project column:`n$details"
    }

    return $orderedStories
}

function Get-MarkdownSectionContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$SectionName
    )

    $pattern = '(?ms)^##\s+{0}\s*\n(.*?)(?=^##\s+|\z)' -f [regex]::Escape($SectionName)
    $match = [regex]::Match($Body, $pattern)

    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Get-MarkdownCheckboxItems {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SectionContent)

    return @(
        [regex]::Matches($SectionContent, '(?m)^-\s+\[(?<state>[ xX])\]\s+(?<text>.+?)\s*$') |
            ForEach-Object {
                [pscustomobject]@{
                    State = $_.Groups['state'].Value
                    Text  = $_.Groups['text'].Value.Trim()
                }
            }
    )
}

function Get-MarkdownWordCount {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Text)

    return ([regex]::Matches($Text, '\b[\w''-]+\b')).Count
}

function Test-HydrionStorySource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Stories
    )

    $content = [System.IO.File]::ReadAllText($Path)
    $content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($pattern in $ForbiddenStoryPatterns) {
        if ($content -match [regex]::Escape($pattern)) {
            $errors.Add("Forbidden story text remains: $pattern")
        }
    }

    if ($content -match '(?m)^\*\*Story Size:\*\*\s*(1|2|3|5|8|13)\b') {
        $errors.Add('Numeric story size metadata remains.')
    }

    if ($content -match '(?m)^-\s+\[[xX]\]\s+') {
        $errors.Add('Checked backlog checkbox remains.')
    }

    if ($content -match '\.\.') {
        $errors.Add('Double periods remain.')
    }

    $sectionSignatures = New-Object System.Collections.Generic.List[string]
    $acceptanceCounts = New-Object System.Collections.Generic.List[int]
    $paragraphsByText = @{}
    $acceptanceListsByText = @{}
    $subtaskListsByText = @{}
    $sizeWordLimits = @{
        XS = 450
        S  = 650
        M  = 900
        L  = 1250
        XL = 1600
    }

    foreach ($story in $Stories) {
        foreach ($metadataName in @('Story ID', 'Title', 'Epic', 'Story Type', 'Priority', 'Release Scope', 'T-shirt Size', 'Project Column', 'Business Rank', 'Labels')) {
            if ([string]::IsNullOrWhiteSpace((Get-MarkdownMetadataValue -Body $story.Body -Name $metadataName))) {
                $errors.Add("$($story.Id) is missing required metadata field '$metadataName'.")
            }
        }

        $metadataStoryId = Get-MarkdownMetadataValue -Body $story.Body -Name 'Story ID'
        if (-not [string]::Equals($metadataStoryId, $story.Id, [System.StringComparison]::OrdinalIgnoreCase)) {
            $errors.Add("$($story.Id) metadata Story ID does not match its heading.")
        }

        $requiredLabelPatterns = @(
            '^user-story$',
            '^type:',
            '^epic:',
            '^priority:p[0-4]$',
            '^scope:',
            '^size:(xs|s|m|l|xl)$',
            '^status:(product-backlog|ice-box)$'
        )

        foreach ($labelPattern in $requiredLabelPatterns) {
            if (-not (@($story.Labels) | Where-Object { $_ -match $labelPattern })) {
                $errors.Add("$($story.Id) is missing required label matching '$labelPattern'.")
            }
        }

        foreach ($requiredSection in @('User Story', 'Business Value', 'Acceptance Criteria')) {
            if ([string]::IsNullOrWhiteSpace((Get-MarkdownSectionContent -Body $story.Body -SectionName $requiredSection))) {
                $errors.Add("$($story.Id) is missing required section '$requiredSection'.")
            }
        }

        $sectionNames = @(
            [regex]::Matches($story.Body, '(?m)^##\s+(.+?)\s*$') |
                ForEach-Object { $_.Groups[1].Value.Trim() }
        )
        $sectionSignatures.Add(($sectionNames -join '|'))

        $acceptanceSection = Get-MarkdownSectionContent -Body $story.Body -SectionName 'Acceptance Criteria'
        $acceptanceItems = @()

        if (-not [string]::IsNullOrWhiteSpace($acceptanceSection)) {
            $acceptanceItems = @(Get-MarkdownCheckboxItems -SectionContent $acceptanceSection)
        }

        if ($acceptanceItems.Count -eq 0) {
            $errors.Add("$($story.Id) has no acceptance-criteria checkboxes.")
        }

        $acceptanceCounts.Add($acceptanceItems.Count)

        foreach ($item in $acceptanceItems) {
            if ($item.State -match '[xX]') {
                $errors.Add("$($story.Id) has a checked acceptance criterion.")
            }

            if ($item.Text -match '^(It works correctly|The user sees appropriate feedback|No hydration log is created\.|Remaining .+ implemented|Add tests|Update documentation|Ensure quality)$') {
                $errors.Add("$($story.Id) has vague or lifecycle acceptance criterion: $($item.Text)")
            }

            if ((Get-MarkdownWordCount -Text $item.Text) -lt 6) {
                $errors.Add("$($story.Id) has an acceptance criterion that is too vague: $($item.Text)")
            }
        }

        $acceptanceKey = (($acceptanceItems | ForEach-Object { $_.Text.ToLowerInvariant() }) -join "`n").Trim()
        if (-not [string]::IsNullOrWhiteSpace($acceptanceKey)) {
            if (-not $acceptanceListsByText.ContainsKey($acceptanceKey)) {
                $acceptanceListsByText[$acceptanceKey] = New-Object System.Collections.Generic.List[string]
            }
            $acceptanceListsByText[$acceptanceKey].Add($story.Id)
        }

        $subtaskSection = Get-MarkdownSectionContent -Body $story.Body -SectionName 'Sub-tasks'
        if (-not [string]::IsNullOrWhiteSpace($subtaskSection)) {
            $subtasks = @(Get-MarkdownCheckboxItems -SectionContent $subtaskSection)
            $subtaskKey = (($subtasks | ForEach-Object { $_.Text.ToLowerInvariant() }) -join "`n").Trim()
            if (-not [string]::IsNullOrWhiteSpace($subtaskKey)) {
                if (-not $subtaskListsByText.ContainsKey($subtaskKey)) {
                    $subtaskListsByText[$subtaskKey] = New-Object System.Collections.Generic.List[string]
                }
                $subtaskListsByText[$subtaskKey].Add($story.Id)
            }
        }

        $storyParagraphs = @($story.Body -split "`n\s*`n")
        foreach ($paragraph in $storyParagraphs) {
            $normalized = ($paragraph -replace '(?m)^#+\s+', '' -replace '`', '' -replace '\s+', ' ').Trim()

            if ([string]::IsNullOrWhiteSpace($normalized)) {
                continue
            }

            if ($normalized -match '^\*\*(Story ID|Title|Epic|Story Type|Priority|Release Scope|T-shirt Size|Project Column|Business Rank|Labels|Milestone):\*\*') {
                continue
            }

            if ((Get-MarkdownWordCount -Text $normalized) -le 12) {
                continue
            }

            $key = $normalized.ToLowerInvariant()
            if (-not $paragraphsByText.ContainsKey($key)) {
                $paragraphsByText[$key] = New-Object System.Collections.Generic.List[string]
            }
            $paragraphsByText[$key].Add($story.Id)
        }

        $wordCount = Get-MarkdownWordCount -Text $story.Body
        $limit = $sizeWordLimits[$story.StorySize]
        if (($null -ne $limit) -and ($wordCount -gt $limit)) {
            $errors.Add("$($story.Id) has $wordCount words, which is too large for size $($story.StorySize).")
        }

        if (($story.StorySize -eq 'XL') -and (-not (@($story.Labels) | Where-Object { [string]::Equals($_, 'needs-decomposition', [System.StringComparison]::OrdinalIgnoreCase) }))) {
            $errors.Add("$($story.Id) is XL but missing the needs-decomposition label.")
        }
    }

    foreach ($entry in $paragraphsByText.GetEnumerator()) {
        $storyIds = @($entry.Value | Select-Object -Unique)
        if ($storyIds.Count -ge 3) {
            $errors.Add("Repeated paragraph longer than 12 words appears in $($storyIds.Count) stories: $($storyIds -join ', ')")
        }
    }

    foreach ($entry in $acceptanceListsByText.GetEnumerator()) {
        $storyIds = @($entry.Value | Select-Object -Unique)
        if ($storyIds.Count -gt 1) {
            $errors.Add("Identical acceptance-criteria list appears in: $($storyIds -join ', ')")
        }
    }

    foreach ($entry in $subtaskListsByText.GetEnumerator()) {
        $storyIds = @($entry.Value | Select-Object -Unique)
        if ($storyIds.Count -gt 1) {
            $errors.Add("Identical sub-task list appears in: $($storyIds -join ', ')")
        }
    }

    if ((@($acceptanceCounts | Select-Object -Unique)).Count -le 1) {
        $errors.Add('All stories have the same acceptance-criteria count.')
    }

    if ((@($sectionSignatures | Select-Object -Unique)).Count -le 1) {
        $errors.Add('All stories have the same section structure.')
    }

    if ($errors.Count -gt 0) {
        throw "User-story source validation failed:`n - $($errors -join "`n - ")"
    }
}

function Get-ExactUserProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Name
    )

    $query = @'
query($login: String!) {
  user(login: $login) {
    projectsV2(first: 100) {
      nodes {
        id
        number
        title
        closed
      }
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $query -Variables @{
        login = $Owner
    }

    if (($null -eq $response.data) -or ($null -eq $response.data.user)) {
        throw "GitHub could not resolve '$Owner' as a personal user account."
    }

    $projects = @($response.data.user.projectsV2.nodes)
    $matches = @(
        $projects | Where-Object {
            (-not $_.closed) -and
            ([string]::Equals($_.title, $Name, [System.StringComparison]::OrdinalIgnoreCase))
        }
    )

    if ($matches.Count -eq 0) {
        $available = @($projects | Where-Object { -not $_.closed } | ForEach-Object { "'$($_.title)' (#$($_.number))" })

        if ($available.Count -eq 0) {
            $availableText = 'No open personal projects were found.'
        }
        else {
            $availableText = 'Available projects: ' + ($available -join ', ')
        }

        throw "Project '$Name' was not found under personal account '$Owner'. $availableText"
    }

    if ($matches.Count -gt 1) {
        throw "More than one open project named '$Name' exists under '$Owner'. Rename the duplicate before running this import."
    }

    return $matches[0]
}

function Get-ProjectStatusConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string[]]$RequiredOptionNames
    )

    $query = @'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 100) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $query -Variables @{
        projectId = $ProjectId
    }

    $fields = @($response.data.node.fields.nodes)
    $statusField = @(
        $fields | Where-Object {
            ($null -ne $_) -and
            ($_.PSObject.Properties.Match('name').Count -gt 0) -and
            ($null -ne $_.name) -and
            ($_.name -eq 'Status')
        }
    )

    if ($statusField.Count -ne 1) {
        throw "The project must contain exactly one single-select field named 'Status'."
    }

    $statusOptions = @($statusField[0].options)
    $optionByName = @{}

    foreach ($option in $statusOptions) {
        $key = $option.name.ToLowerInvariant()

        if ($optionByName.ContainsKey($key)) {
            throw "More than one Status option named '$($option.name)' exists."
        }

        $optionByName[$key] = $option
    }

    foreach ($requiredOptionName in (Get-UniqueStrings -Values $RequiredOptionNames)) {
        if (-not $optionByName.ContainsKey($requiredOptionName.ToLowerInvariant())) {
            $availableOptions = @($statusOptions | ForEach-Object { $_.name }) -join ', '
            throw "Status option '$requiredOptionName' does not exist. Available Status options: $availableOptions"
        }
    }

    return [pscustomobject]@{
        FieldId = $statusField[0].id
        OptionsByName = $optionByName
    }
}

function Get-ProjectSizeFieldConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string[]]$FieldNames
    )

    $query = @'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 100) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $query -Variables @{
        projectId = $ProjectId
    }

    $fields = @($response.data.node.fields.nodes)

    foreach ($fieldName in @($FieldNames)) {
        $matches = @(
            $fields | Where-Object {
                ($null -ne $_) -and
                ($_.PSObject.Properties.Match('name').Count -gt 0) -and
                ($null -ne $_.name) -and
                [string]::Equals($_.name, $fieldName, [System.StringComparison]::OrdinalIgnoreCase)
            }
        )

        if ($matches.Count -eq 0) {
            continue
        }

        if ($matches.Count -gt 1) {
            Write-Warning "More than one project field named '$fieldName' exists. Story size project-field sync will be skipped."
            return $null
        }

        $field = $matches[0]
        $dataType = $null

        if (($field.PSObject.Properties.Match('dataType').Count -gt 0) -and ($null -ne $field.dataType)) {
            $dataType = $field.dataType.ToString()
        }
        elseif ($field.PSObject.Properties.Match('options').Count -gt 0) {
            $dataType = 'SINGLE_SELECT'
        }
        else {
            Write-Warning "Project field '$($field.name)' type could not be determined. Story size labels will still be applied."
            return $null
        }

        if ($dataType -notin @('NUMBER', 'TEXT', 'SINGLE_SELECT')) {
            Write-Warning "Project field '$($field.name)' has unsupported type '$dataType'. Story size labels will still be applied."
            return $null
        }

        return [pscustomobject]@{
            Id       = $field.id
            Name     = $field.name
            DataType = $dataType
            Options  = @($field.options)
        }
    }

    return $null
}

function Get-ProjectIssueItems {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectId)

    $query = @'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              id
              number
              title
              url
              repository {
                nameWithOwner
              }
            }
          }
          fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name
            }
          }
        }
      }
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $query -Variables @{
        projectId = $ProjectId
    }

    if ($null -eq $response.data.node) {
        throw "The GitHub project could not be read."
    }

    return @($response.data.node.items.nodes)
}

function Add-IssueToProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$IssueNodeId
    )

    $mutation = @'
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(
    input: {
      projectId: $projectId
      contentId: $contentId
    }
  ) {
    item {
      id
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        contentId = $IssueNodeId
    }

    return $response.data.addProjectV2ItemById.item
}

function Set-ProjectItemStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ProjectItemId,
        [Parameter(Mandatory)][string]$StatusFieldId,
        [Parameter(Mandatory)][string]$StatusOptionId
    )

    $mutation = @'
mutation(
  $projectId: ID!,
  $itemId: ID!,
  $fieldId: ID!,
  $optionId: String!
) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        singleSelectOptionId: $optionId
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'@

    $response = Invoke-GhGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        itemId = $ProjectItemId
        fieldId = $StatusFieldId
        optionId = $StatusOptionId
    }

    return $response.data.updateProjectV2ItemFieldValue.projectV2Item
}

function Set-ProjectItemPosition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ProjectItemId,
        [Parameter()][AllowNull()][object]$AfterProjectItemId
    )

    $mutation = @'
mutation(
  $projectId: ID!,
  $itemId: ID!,
  $afterId: ID
) {
  updateProjectV2ItemPosition(
    input: {
      projectId: $projectId
      itemId: $itemId
      afterId: $afterId
    }
  ) {
    clientMutationId
  }
}
'@

    $resolvedAfterProjectItemId = if ([string]::IsNullOrWhiteSpace([string]$AfterProjectItemId)) {
        $null
    }
    else {
        [string]$AfterProjectItemId
    }

    Invoke-GhGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        itemId = $ProjectItemId
        afterId = $resolvedAfterProjectItemId
    } | Out-Null
}

function Set-ProjectItemStorySize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ProjectItemId,
        [Parameter(Mandatory)][object]$SizeField,
        [Parameter(Mandatory)][string]$StorySize
    )

    $normalizedStorySize = $StorySize.Trim().ToUpperInvariant()

    if ($SizeField.DataType -eq 'NUMBER') {
        $numberValue = switch ($normalizedStorySize) {
            'XS' { 1 }
            'S' { 2 }
            'M' { 3 }
            'L' { 5 }
            'XL' { 8 }
            default { $null }
        }

        if ($null -eq $numberValue) {
            Write-Warning "Project field '$($SizeField.Name)' is numeric and cannot represent story size '$StorySize'. Size labels will still be applied."
            return $false
        }

        $mutation = @'
mutation(
  $projectId: ID!,
  $itemId: ID!,
  $fieldId: ID!,
  $number: Float!
) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        number: $number
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'@

        Invoke-GhGraphQL -Query $mutation -Variables @{
            projectId = $ProjectId
            itemId = $ProjectItemId
            fieldId = $SizeField.Id
            number = [double]$numberValue
        } | Out-Null

        return $true
    }

    if ($SizeField.DataType -eq 'TEXT') {
        $mutation = @'
mutation(
  $projectId: ID!,
  $itemId: ID!,
  $fieldId: ID!,
  $text: String!
) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        text: $text
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'@

        Invoke-GhGraphQL -Query $mutation -Variables @{
            projectId = $ProjectId
            itemId = $ProjectItemId
            fieldId = $SizeField.Id
            text = $normalizedStorySize
        } | Out-Null

        return $true
    }

    if ($SizeField.DataType -eq 'SINGLE_SELECT') {
        $acceptedOptionNames = @(
            $normalizedStorySize,
            ('size:{0}' -f $normalizedStorySize.ToLowerInvariant()),
            ('Size {0}' -f $normalizedStorySize),
            ('T-shirt {0}' -f $normalizedStorySize)
        )

        $matchingOption = @(
            @($SizeField.Options) | Where-Object {
                $optionName = $_.name
                @($acceptedOptionNames) | Where-Object {
                    [string]::Equals($optionName, $_, [System.StringComparison]::OrdinalIgnoreCase)
                }
            } | Select-Object -First 1
        )

        if ($matchingOption.Count -ne 1) {
            Write-Warning "Project field '$($SizeField.Name)' has no option for story size '$StorySize'. Size labels will still be applied."
            return $false
        }

        Set-ProjectItemStatus `
            -ProjectId $ProjectId `
            -ProjectItemId $ProjectItemId `
            -StatusFieldId $SizeField.Id `
            -StatusOptionId $matchingOption[0].id | Out-Null

        return $true
    }

    return $false
}

function Get-ExistingIssues {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)

    $response = Invoke-GhJson -Arguments @(
        'issue',
        'list',
        '--repo',
        $Repo,
        '--state',
        'all',
        '--limit',
        '1000',
        '--json',
        'id,number,title,url,labels,milestone'
    )

    if ($null -eq $response) {
        return @()
    }

    return @($response)
}

function Get-ExistingPullRequests {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)

    $response = Invoke-GhJson -Arguments @(
        'pr',
        'list',
        '--repo',
        $Repo,
        '--state',
        'all',
        '--limit',
        '1000',
        '--json',
        'number,title,url'
    )

    if ($null -eq $response) {
        return @()
    }

    return @($response)
}

function Export-HydrionIssueBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][object[]]$ProjectItems,
        [Parameter(Mandatory)][string]$Directory
    )

    $backupRoot = $Directory

    if (-not [System.IO.Path]::IsPathRooted($backupRoot)) {
        $baseDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $PSScriptRoot
        }
        else {
            (Get-Location).Path
        }

        $backupRoot = Join-Path -Path $baseDirectory -ChildPath $backupRoot
    }

    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    $projectStatusByIssueId = @{}

    foreach ($item in @($ProjectItems)) {
        if (($null -ne $item.content) -and ($null -ne $item.content.id)) {
            $status = $null
            if (($item.PSObject.Properties.Match('fieldValueByName').Count -gt 0) -and ($null -ne $item.fieldValueByName)) {
                $status = $item.fieldValueByName.name
            }
            $projectStatusByIssueId[$item.content.id] = $status
        }
    }

    $issues = Invoke-GhJson -Arguments @(
        'issue',
        'list',
        '--repo',
        $Repo,
        '--state',
        'all',
        '--limit',
        '1000',
        '--json',
        'id,number,title,state,url,body,labels,milestone'
    )

    $storyIssues = @(
        @($issues) |
            Where-Object { $_.title -match '^HYD-US-\d{3}:' } |
            Sort-Object number |
            ForEach-Object {
                [pscustomobject]@{
                    number = $_.number
                    id = if ($_.title -match '^(HYD-US-\d{3}):') { $Matches[1] } else { $null }
                    title = $_.title
                    state = $_.state
                    body = $_.body
                    labels = @($_.labels | ForEach-Object { $_.name })
                    milestone = if ($null -ne $_.milestone) { $_.milestone.title } else { $null }
                    project = [pscustomobject]@{
                        title = $ProjectName
                        status = if ($projectStatusByIssueId.ContainsKey($_.id)) { $projectStatusByIssueId[$_.id] } else { $null }
                    }
                    url = $_.url
                }
            }
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path -Path $backupRoot -ChildPath "hydrion-user-stories-$timestamp.json"
    $payload = [pscustomobject]@{
        exportedAt = (Get-Date).ToUniversalTime().ToString('o')
        repository = $Repo
        project = $ProjectName
        issueCount = $storyIssues.Count
        issues = $storyIssues
    }

    Write-Utf8NoBom -Path $path -Content ($payload | ConvertTo-Json -Depth 50)
    return $path
}

function Get-HydrionLabelDefinition {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)

    $lowerName = $Name.ToLowerInvariant()

    if ([string]::Equals($Name, $IssueLabel, [System.StringComparison]::OrdinalIgnoreCase)) {
        return [pscustomobject]@{
            Color       = $IssueLabelColor
            Description = $IssueLabelDescription
        }
    }

    $color = $DefaultLabelColor
    $description = $DefaultLabelDescription

    switch -Regex ($lowerName) {
        '^type:' {
            $color = '5319E7'
            $description = 'Hydrion story type'
            break
        }
        '^priority:p0$' {
            $color = 'B60205'
            $description = 'Highest Hydrion priority'
            break
        }
        '^priority:p1$' {
            $color = 'D93F0B'
            $description = 'High Hydrion priority'
            break
        }
        '^priority:p2$' {
            $color = 'FBCA04'
            $description = 'Medium Hydrion priority'
            break
        }
        '^priority:p3$' {
            $color = 'C5DEF5'
            $description = 'Future Hydrion priority'
            break
        }
        '^priority:p4$' {
            $color = 'D4C5F9'
            $description = 'Speculative Hydrion priority'
            break
        }
        '^status:product-backlog$' {
            $color = '1D76DB'
            $description = 'Hydrion project status: Product Backlog'
            break
        }
        '^status:ice-box$' {
            $color = 'BFDADC'
            $description = 'Hydrion project status: Ice Box'
            break
        }
        '^status:implemented$' {
            $color = '0E8A16'
            $description = 'Implemented in the repository'
            break
        }
        '^status:partial$' {
            $color = 'FBCA04'
            $description = 'Partially implemented or partially verified'
            break
        }
        '^status:gated$' {
            $color = 'BFDADC'
            $description = 'Capability-gated pending adapter, provider, or release decision'
            break
        }
        '^status:planned$' {
            $color = '1D76DB'
            $description = 'Planned but not implemented'
            break
        }
        '^status:post-mvp$' {
            $color = '6F42C1'
            $description = 'Post-MVP scope'
            break
        }
        '^scope:mvp$' {
            $color = '0052CC'
            $description = 'MVP release scope'
            break
        }
        '^scope:supporting$' {
            $color = '0E8A16'
            $description = 'Supporting MVP capability'
            break
        }
        '^scope:post-mvp$' {
            $color = '6F42C1'
            $description = 'Post-MVP release scope'
            break
        }
        '^size:' {
            $color = 'D4C5F9'
            $description = 'Hydrion T-shirt size estimate'
            break
        }
        '^epic:' {
            $color = '0E8A16'
            $description = 'Hydrion story epic'
            break
        }
        '^needs-decomposition$' {
            $color = 'B60205'
            $description = 'Epic-sized story that must be split before sprint execution'
            break
        }
        '^area:' {
            $color = 'BFD4F2'
            $description = 'Hydrion product or engineering area'
            break
        }
    }

    return [pscustomobject]@{
        Color       = $color
        Description = $description
    }
}

function Ensure-HydrionLabels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter()][AllowEmptyCollection()][string[]]$Names = @()
    )

    $labels = Invoke-GhJson -Arguments @(
        'label',
        'list',
        '--repo',
        $Repo,
        '--limit',
        '1000',
        '--json',
        'name'
    )

    $existingNames = @{}

    foreach ($label in @($labels)) {
        if ($null -ne $label.name) {
            $existingNames[$label.name.ToLowerInvariant()] = $true
        }
    }

    foreach ($name in (Get-UniqueStrings -Values $Names)) {
        Assert-NoSecretLikeContent -Text $name -Context "label '$name'"

        $key = $name.ToLowerInvariant()

        if ($existingNames.ContainsKey($key)) {
            continue
        }

        $definition = Get-HydrionLabelDefinition -Name $name

        Invoke-MutationWithRetry -Description "Create '$name' label" -Operation {
            Invoke-Gh -Arguments @(
                'label',
                'create',
                $name,
                '--repo',
                $Repo,
                '--color',
                $definition.Color,
                '--description',
                $definition.Description
            ) | Out-Null
        } | Out-Null

        $existingNames[$key] = $true
    }
}

function Get-RepositoryMilestones {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)

    $response = Invoke-GhJson -Arguments @(
        'api',
        "repos/$Repo/milestones?state=all&per_page=100"
    )

    if ($null -eq $response) {
        return @()
    }

    return @($response)
}

function Ensure-HydrionMilestones {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter()][AllowEmptyCollection()][string[]]$Names = @()
    )

    $milestones = Get-RepositoryMilestones -Repo $Repo
    $milestoneMap = @{}

    foreach ($milestone in @($milestones)) {
        if ($null -ne $milestone.title) {
            $milestoneMap[$milestone.title.ToLowerInvariant()] = $milestone
        }
    }

    foreach ($name in (Get-UniqueStrings -Values $Names)) {
        Assert-NoSecretLikeContent -Text $name -Context "milestone '$name'"

        $key = $name.ToLowerInvariant()

        if ($milestoneMap.ContainsKey($key)) {
            $existingMilestone = $milestoneMap[$key]

            if ([string]::Equals($existingMilestone.state, 'closed', [System.StringComparison]::OrdinalIgnoreCase)) {
                $reopened = Invoke-MutationWithRetry -Description "Reopen '$name' milestone" -Operation {
                    Invoke-GhJson -Arguments @(
                        'api',
                        '--method',
                        'PATCH',
                        "repos/$Repo/milestones/$($existingMilestone.number)",
                        '-f',
                        'state=open'
                    )
                }

                $milestoneMap[$key] = $reopened
            }

            continue
        }

        $createdMilestone = Invoke-MutationWithRetry -Description "Create '$name' milestone" -Operation {
            Invoke-GhJson -Arguments @(
                'api',
                '--method',
                'POST',
                "repos/$Repo/milestones",
                '-f',
                "title=$name",
                '-f',
                'state=open'
            )
        }

        $milestoneMap[$key] = $createdMilestone
    }

    return $milestoneMap
}

function New-UserStoryIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][object]$Story
    )

    Assert-HydrionGithubMutationSafe -Story $Story -Action 'create issue'
    $tempBodyPath = [System.IO.Path]::GetTempFileName()

    try {
        Write-Utf8NoBom -Path $tempBodyPath -Content $Story.Body

        $result = Invoke-MutationWithRetry -Description "Create issue for $($Story.Id)" -Operation {
            $arguments = @(
                'issue',
                'create',
                '--repo',
                $Repo,
                '--title',
                $Story.IssueTitle,
                '--body-file',
                $tempBodyPath
            )

            foreach ($label in @($Story.Labels)) {
                $arguments += @('--label', $label)
            }

            if (-not [string]::IsNullOrWhiteSpace($Story.Milestone)) {
                $arguments += @('--milestone', $Story.Milestone)
            }

            Invoke-Gh -Arguments $arguments
        }

        $url = $result.Output.Trim()

        if ($url -notmatch '/issues/(\d+)(?:\?.*)?$') {
            throw "Could not extract the new issue number from GitHub CLI output: $url"
        }

        $issueNumber = [int]$Matches[1]

        $issue = Invoke-GhJson -Arguments @(
            'issue',
            'view',
            $issueNumber.ToString(),
            '--repo',
            $Repo,
            '--json',
            'id,number,title,url,body,labels,milestone'
        )

        return $issue
    }
    finally {
        Remove-Item -LiteralPath $tempBodyPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-IssueLabelNames {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Issue)

    if (
        (-not ($Issue.PSObject.Properties.Match('labels').Count -gt 0)) -or
        ($null -eq $Issue.labels)
    ) {
        return @()
    }

    return @(
        @($Issue.labels) |
            Where-Object { $null -ne $_.name } |
            ForEach-Object { $_.name.ToString() }
    )
}

function Get-IssueMilestoneTitle {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Issue)

    if (
        ($Issue.PSObject.Properties.Match('milestone').Count -gt 0) -and
        ($null -ne $Issue.milestone) -and
        ($null -ne $Issue.milestone.title)
    ) {
        return $Issue.milestone.title.ToString()
    }

    return $null
}

function Test-HydrionManagedLabel {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)

    if ([string]::Equals($Name, $IssueLabel, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return ($Name -match '^(type|priority|scope|status|area|size|epic):') -or
        [string]::Equals($Name, 'needs-decomposition', [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-IssueBody {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Issue)

    if ($Issue.PSObject.Properties.Match('body').Count -gt 0) {
        return [string]$Issue.body
    }

    return $null
}

function Get-GitHubIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][int]$Number
    )

    return Invoke-GhJson -Arguments @(
        'issue',
        'view',
        $Number.ToString(),
        '--repo',
        $Repo,
        '--json',
        'id,number,title,url,body,labels,milestone'
    )
}

function Sync-UserStoryIssueContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][object]$Story,
        [Parameter(Mandatory)][object]$Issue
    )

    if (-not ($Issue.PSObject.Properties.Match('body').Count -gt 0)) {
        $Issue = Get-GitHubIssue -Repo $Repo -Number ([int]$Issue.number)
    }

    Assert-HydrionGithubMutationSafe -Story $Story -Action 'sync issue content'
    $currentBody = (Get-IssueBody -Issue $Issue)

    if (
        ($Issue.title -eq $Story.IssueTitle) -and
        ($currentBody -eq $Story.Body)
    ) {
        return [pscustomobject]@{
            Issue = $Issue
            Updated = $false
        }
    }

    $tempBodyPath = [System.IO.Path]::GetTempFileName()

    try {
        Write-Utf8NoBom -Path $tempBodyPath -Content $Story.Body

        Invoke-MutationWithRetry -Description "Update issue content for $($Story.Id)" -Operation {
            Invoke-Gh -Arguments @(
                'issue',
                'edit',
                $Issue.number.ToString(),
                '--repo',
                $Repo,
                '--title',
                $Story.IssueTitle,
                '--body-file',
                $tempBodyPath
            ) | Out-Null
        } | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $tempBodyPath -Force -ErrorAction SilentlyContinue
    }

    return [pscustomobject]@{
        Issue = (Get-GitHubIssue -Repo $Repo -Number ([int]$Issue.number))
        Updated = $true
    }
}

function Sync-UserStoryIssueMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][object]$Story,
        [Parameter(Mandatory)][object]$Issue
    )

    $existingLabels = @{}
    $desiredLabels = @{}

    foreach ($label in (Get-IssueLabelNames -Issue $Issue)) {
        $existingLabels[$label.ToLowerInvariant()] = $true
    }

    foreach ($label in @($Story.Labels)) {
        $desiredLabels[$label.ToLowerInvariant()] = $true
    }

    $missingLabels = @(
        @($Story.Labels) | Where-Object {
            -not $existingLabels.ContainsKey($_.ToLowerInvariant())
        }
    )

    $labelsToRemove = @(
        Get-IssueLabelNames -Issue $Issue |
            Where-Object {
                (Test-HydrionManagedLabel -Name $_) -and
                (-not $desiredLabels.ContainsKey($_.ToLowerInvariant()))
            }
    )

    $currentMilestone = Get-IssueMilestoneTitle -Issue $Issue
    $shouldSetMilestone = (
        (-not [string]::IsNullOrWhiteSpace($Story.Milestone)) -and
        (-not [string]::Equals($currentMilestone, $Story.Milestone, [System.StringComparison]::OrdinalIgnoreCase))
    )
    $shouldRemoveMilestone = (
        [string]::IsNullOrWhiteSpace($Story.Milestone) -and
        (-not [string]::IsNullOrWhiteSpace($currentMilestone))
    )

    Assert-HydrionGithubMutationSafe -Story $Story -Action 'sync issue metadata'

    if (($missingLabels.Count -eq 0) -and ($labelsToRemove.Count -eq 0) -and (-not $shouldSetMilestone) -and (-not $shouldRemoveMilestone)) {
        return $Issue
    }

    Invoke-MutationWithRetry -Description "Sync metadata for $($Story.Id)" -Operation {
        $arguments = @(
            'issue',
            'edit',
            $Issue.number.ToString(),
            '--repo',
            $Repo
        )

        foreach ($label in $missingLabels) {
            $arguments += @('--add-label', $label)
        }

        foreach ($label in $labelsToRemove) {
            $arguments += @('--remove-label', $label)
        }

        if ($shouldSetMilestone) {
            $arguments += @('--milestone', $Story.Milestone)
        }
        elseif ($shouldRemoveMilestone) {
            $arguments += @('--remove-milestone')
        }

        Invoke-Gh -Arguments $arguments | Out-Null
    } | Out-Null

    return Invoke-GhJson -Arguments @(
        'issue',
        'view',
        $Issue.number.ToString(),
        '--repo',
        $Repo,
        '--json',
        'id,number,title,url,body,labels,milestone'
    )
}

Write-Section 'Preflight'

if (
    ($PSBoundParameters.ContainsKey('StatusOptionName')) -and
    (-not $PSBoundParameters.ContainsKey('DefaultProjectColumn'))
) {
    $DefaultProjectColumn = $StatusOptionName
}

$MarkdownPath = Resolve-MarkdownPath -RequestedPath $MarkdownPath
$stories = Get-HydrionStories -Path $MarkdownPath
Test-HydrionStorySource -Path $MarkdownPath -Stories $stories

if ($ValidateOnly) {
    Write-Host "Hydrion user-story source validation passed for $($stories.Count) stories." -ForegroundColor Green
    return
}

if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is not installed or is not available on PATH.'
}

$authCheck = Invoke-Gh -Arguments @('auth', 'status', '-h', 'github.com') -AllowFailure

if ($authCheck.ExitCode -ne 0) {
    throw @"
GitHub CLI authentication is invalid.

Run:
  gh auth logout -h github.com -u $ProjectOwner
  gh auth login -h github.com
  gh auth refresh -h github.com -s repo -s project
"@
}

$authenticatedLogin = (Invoke-Gh -Arguments @('api', 'user', '--jq', '.login')).Output.Trim()

if (-not [string]::Equals($authenticatedLogin, $ProjectOwner, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "GitHub CLI is authenticated as '$authenticatedLogin', but this import expects '$ProjectOwner'."
}

$repoInfo = Invoke-GhJson -Arguments @(
    'repo',
    'view',
    $Repository,
    '--json',
    'nameWithOwner,isPrivate,defaultBranchRef'
)

if ($null -eq $repoInfo) {
    throw "Repository '$Repository' could not be resolved."
}

Write-Info "Script:      $ScriptVersion"
Write-Info "Repository:  $($repoInfo.nameWithOwner)"
Write-Info "Visibility:  $(if ($repoInfo.isPrivate) { 'Private' } else { 'Public' })"
Write-Info "Markdown:    $MarkdownPath"
Write-Info "Stories:     $($stories.Count)"
Write-Info "Project:     $ProjectOwner / $ProjectName"
Write-Info "Columns:     $(@($AllowedProjectColumns) -join ', ')"

Write-Section 'Resolve GitHub project'

$project = Get-ExactUserProject -Owner $ProjectOwner -Name $ProjectName
$statusConfiguration = Get-ProjectStatusConfiguration -ProjectId $project.id -RequiredOptionNames $AllowedProjectColumns
$sizeFieldConfiguration = Get-ProjectSizeFieldConfiguration -ProjectId $project.id -FieldNames $StorySizeProjectFieldNames

Write-Info "Project number:  $($project.number)"
Write-Info "Project ID:      $($project.id)"
Write-Info "Status field ID: $($statusConfiguration.FieldId)"
Write-Info "Status options:  $(@($AllowedProjectColumns) -join ', ')"

if ($null -eq $sizeFieldConfiguration) {
    Write-Info 'Story size field: not found; using size labels for project visualization.'
}
else {
    Write-Info "Story size field: $($sizeFieldConfiguration.Name) ($($sizeFieldConfiguration.DataType))"
}

Write-Section 'Validate repository numbering'

$existingIssues = @(Get-ExistingIssues -Repo $Repository)
$existingPullRequests = @(Get-ExistingPullRequests -Repo $Repository)

$storyIssueMap = @{}
$nonStoryIssues = New-Object System.Collections.Generic.List[object]

foreach ($issue in $existingIssues) {
    if ($issue.title -match '^(HYD-US-\d{3}):') {
        $storyId = $Matches[1]

        if ($storyIssueMap.ContainsKey($storyId)) {
            throw "Duplicate GitHub issues already exist for $storyId."
        }

        $storyIssueMap[$storyId] = $issue
    }
    else {
        $nonStoryIssues.Add($issue)
    }
}

if ((-not $AllowExistingNumberedItems) -and (($nonStoryIssues.Count -gt 0) -or ($existingPullRequests.Count -gt 0))) {
    $details = New-Object System.Collections.Generic.List[string]

    foreach ($issue in $nonStoryIssues) {
        $details.Add("Issue #$($issue.number): $($issue.title)")
    }

    foreach ($pullRequest in $existingPullRequests) {
        $details.Add("Pull request #$($pullRequest.number): $($pullRequest.title)")
    }

    throw @"
The repository contains numbered items that are not Hydrion user stories.
Creating the stories now would prevent HYD-US-001 through HYD-US-051 from mapping cleanly to issues #1 through #51.

$($details -join [Environment]::NewLine)

Delete those items or rerun with -AllowExistingNumberedItems if number alignment is no longer required.
"@
}

foreach ($story in $stories) {
    if ($storyIssueMap.ContainsKey($story.Id)) {
        $existingIssue = $storyIssueMap[$story.Id]

        if ((-not $AllowExistingNumberedItems) -and ([int]$existingIssue.number -ne $story.Sequence)) {
            throw "$($story.Id) is issue #$($existingIssue.number), but clean numbering requires issue #$($story.Sequence)."
        }
    }
}

Write-Info "Existing Hydrion story issues: $($storyIssueMap.Count)"
Write-Info "Existing pull requests:        $($existingPullRequests.Count)"
Write-Info "Existing non-story issues:     $($nonStoryIssues.Count)"

Write-Section 'Prepare labels, milestones, and project-item map'

$requiredLabelNames = Get-UniqueStrings -Values @(
    $stories | ForEach-Object { @($_.Labels) }
)

$requiredMilestoneNames = Get-UniqueStrings -Values @(
    $stories |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.Milestone) } |
        ForEach-Object { $_.Milestone }
)

Ensure-HydrionLabels -Repo $Repository -Names $requiredLabelNames
$milestoneMap = Ensure-HydrionMilestones -Repo $Repository -Names $requiredMilestoneNames

$projectItems = @(Get-ProjectIssueItems -ProjectId $project.id)
$projectItemMap = @{}

$backupPath = Export-HydrionIssueBackup `
    -Repo $Repository `
    -ProjectName $ProjectName `
    -ProjectItems $projectItems `
    -Directory $BackupDirectory

foreach ($item in $projectItems) {
    if (($null -ne $item.content) -and ($null -ne $item.content.id)) {
        $projectItemMap[$item.content.id] = $item
    }
}

Write-Info "Prepared labels:              $($requiredLabelNames.Count)"
Write-Info "Prepared milestones:          $($requiredMilestoneNames.Count)"
Write-Info "Existing project issue items: $($projectItemMap.Count)"
Write-Info "Issue backup:                 $backupPath"

Write-Section 'Publish user stories'

$createdCount = 0
$reusedCount = 0
$projectAddedCount = 0
$statusUpdatedCount = 0
$statusAlreadyCorrectCount = 0
$contentUpdatedCount = 0
$contentAlreadyCorrectCount = 0
$metadataUpdatedCount = 0
$metadataAlreadyCorrectCount = 0
$sizeFieldSyncedCount = 0
$sizeFieldSkippedCount = 0
$storyProjectItemMap = @{}

foreach ($story in $stories) {
    Write-Host ("[{0:D2}/{1:D2}] {2}" -f $story.Sequence, $ExpectedStoryCount, $story.IssueTitle) -ForegroundColor White

    $issue = $null

    if ($storyIssueMap.ContainsKey($story.Id)) {
        $issue = $storyIssueMap[$story.Id]
        $reusedCount++
        Write-Info "  Reusing issue #$($issue.number)."
    }
    else {
        $issue = New-UserStoryIssue -Repo $Repository -Story $story
        $createdCount++

        if ((-not $AllowExistingNumberedItems) -and ([int]$issue.number -ne $story.Sequence)) {
            throw @"
Number alignment failed immediately after creating $($story.Id).
Expected issue #$($story.Sequence), but GitHub created issue #$($issue.number).
The script stopped before creating the next story.
"@
        }

        $storyIssueMap[$story.Id] = $issue
        Write-Info "  Created issue #$($issue.number)."
    }

    $contentSync = Sync-UserStoryIssueContent -Repo $Repository -Story $story -Issue $issue
    $issue = $contentSync.Issue

    if ($contentSync.Updated) {
        $contentUpdatedCount++
        $storyIssueMap[$story.Id] = $issue
        Write-Info '  Issue title/body synced.'
    }
    else {
        $contentAlreadyCorrectCount++
        Write-Info '  Issue title/body already match.'
    }

    $metadataBefore = @(
        ((Get-IssueLabelNames -Issue $issue) | Sort-Object) -join ','
        Get-IssueMilestoneTitle -Issue $issue
    ) -join '|'

    $issue = Sync-UserStoryIssueMetadata -Repo $Repository -Story $story -Issue $issue

    $metadataAfter = @(
        ((Get-IssueLabelNames -Issue $issue) | Sort-Object) -join ','
        Get-IssueMilestoneTitle -Issue $issue
    ) -join '|'

    if ($metadataBefore -eq $metadataAfter) {
        $metadataAlreadyCorrectCount++
        Write-Info '  Labels and milestone already match.'
    }
    else {
        $metadataUpdatedCount++
        $storyIssueMap[$story.Id] = $issue
        Write-Info '  Labels and milestone synced.'
    }

    $projectItem = $null

    if ($projectItemMap.ContainsKey($issue.id)) {
        $projectItem = $projectItemMap[$issue.id]
        Write-Info '  Issue already belongs to the project.'
    }
    else {
        $projectItem = Invoke-MutationWithRetry -Description "Add $($story.Id) to project" -Operation {
            Add-IssueToProject -ProjectId $project.id -IssueNodeId $issue.id
        }

        $projectAddedCount++
        $projectItemMap[$issue.id] = $projectItem
        Write-Info '  Added issue to the project.'
    }

    $storyProjectItemMap[$story.Id] = $projectItem
    $currentStatusName = $null
    $targetStatusName = $story.ProjectColumn
    $targetStatusOption = $statusConfiguration.OptionsByName[$targetStatusName.ToLowerInvariant()]

    if (
        ($projectItem.PSObject.Properties.Match('fieldValueByName').Count -gt 0) -and
        ($null -ne $projectItem.fieldValueByName)
    ) {
        $currentStatusName = $projectItem.fieldValueByName.name
    }

    if ([string]::Equals($currentStatusName, $targetStatusName, [System.StringComparison]::OrdinalIgnoreCase)) {
        $statusAlreadyCorrectCount++
        Write-Info "  Status already set to '$targetStatusName'."
    }
    else {
        Invoke-MutationWithRetry -Description "Set $($story.Id) status" -Operation {
            Set-ProjectItemStatus `
                -ProjectId $project.id `
                -ProjectItemId $projectItem.id `
                -StatusFieldId $statusConfiguration.FieldId `
                -StatusOptionId $targetStatusOption.id | Out-Null
        } | Out-Null

        $statusUpdatedCount++
        Write-Info "  Status set to '$targetStatusName'."
    }

    if ($null -eq $sizeFieldConfiguration) {
        $sizeFieldSkippedCount++
    }
    else {
        $sizeSynced = Invoke-MutationWithRetry -Description "Set $($story.Id) story size" -Operation {
            Set-ProjectItemStorySize `
                -ProjectId $project.id `
                -ProjectItemId $projectItem.id `
                -SizeField $sizeFieldConfiguration `
                -StorySize $story.StorySize
        }

        if ($sizeSynced) {
            $sizeFieldSyncedCount++
            Write-Info "  Story size set to '$($story.StorySize)'."
        }
        else {
            $sizeFieldSkippedCount++
            Write-Info "  Story size field skipped; size label remains applied."
        }
    }
}

Write-Section 'Rank project cards'

$rankedCardCount = 0

if ($SkipProjectRankSync) {
    Write-Info 'Project card ranking skipped by request.'
}
else {
    foreach ($columnName in @($AllowedProjectColumns)) {
        $orderedColumnStories = @(
            $stories |
                Where-Object { [string]::Equals($_.ProjectColumn, $columnName, [System.StringComparison]::OrdinalIgnoreCase) } |
                Sort-Object BusinessRank, Sequence
        )

        $afterProjectItemId = $null

        foreach ($story in $orderedColumnStories) {
            if (-not $storyProjectItemMap.ContainsKey($story.Id)) {
                throw "Cannot rank $($story.Id) because its project item was not recorded."
            }

            $projectItem = $storyProjectItemMap[$story.Id]

            Invoke-MutationWithRetry -Description "Rank $($story.Id) in $columnName" -Operation {
                Set-ProjectItemPosition `
                    -ProjectId $project.id `
                    -ProjectItemId $projectItem.id `
                    -AfterProjectItemId $afterProjectItemId
            } | Out-Null

            $rankedCardCount++
            $afterProjectItemId = $projectItem.id
        }

        Write-Info ("  {0}: ranked {1} card(s)." -f $columnName, $orderedColumnStories.Count)
    }
}

Write-Section 'Verify final state'

$finalIssues = @(Get-ExistingIssues -Repo $Repository)
$finalIssueMap = @{}

foreach ($issue in $finalIssues) {
    if ($issue.title -match '^(HYD-US-\d{3}):') {
        $finalIssueMap[$Matches[1]] = $issue
    }
}

$verificationErrors = New-Object System.Collections.Generic.List[string]

foreach ($story in $stories) {
    if (-not $finalIssueMap.ContainsKey($story.Id)) {
        $verificationErrors.Add("Missing GitHub issue for $($story.Id).")
        continue
    }

    $issue = $finalIssueMap[$story.Id]
    $issue = Get-GitHubIssue -Repo $Repository -Number ([int]$issue.number)

    if ((-not $AllowExistingNumberedItems) -and ([int]$issue.number -ne $story.Sequence)) {
        $verificationErrors.Add("$($story.Id) is issue #$($issue.number), expected #$($story.Sequence).")
    }

    if ($issue.title -ne $story.IssueTitle) {
        $verificationErrors.Add("$($story.Id) title does not match the Markdown heading.")
    }

    if ((Get-IssueBody -Issue $issue) -ne $story.Body) {
        $verificationErrors.Add("$($story.Id) issue body does not match the Markdown story body.")
    }

    $issueLabels = @{}

    foreach ($label in (Get-IssueLabelNames -Issue $issue)) {
        $issueLabels[$label.ToLowerInvariant()] = $true
    }

    foreach ($requiredLabel in @($story.Labels)) {
        if (-not $issueLabels.ContainsKey($requiredLabel.ToLowerInvariant())) {
            $verificationErrors.Add("$($story.Id) is missing label '$requiredLabel'.")
        }
    }

    foreach ($label in (Get-IssueLabelNames -Issue $issue)) {
        if ((Test-HydrionManagedLabel -Name $label) -and (-not (@($story.Labels) | Where-Object { [string]::Equals($_, $label, [System.StringComparison]::OrdinalIgnoreCase) }))) {
            $verificationErrors.Add("$($story.Id) still has stale managed label '$label'.")
        }
    }

    $actualMilestone = Get-IssueMilestoneTitle -Issue $issue

    if (
        (-not [string]::IsNullOrWhiteSpace($story.Milestone)) -and
        (-not [string]::Equals($actualMilestone, $story.Milestone, [System.StringComparison]::OrdinalIgnoreCase))
    ) {
        $verificationErrors.Add("$($story.Id) milestone is '$actualMilestone', expected '$($story.Milestone)'.")
    }
    elseif ([string]::IsNullOrWhiteSpace($story.Milestone) -and (-not [string]::IsNullOrWhiteSpace($actualMilestone))) {
        $verificationErrors.Add("$($story.Id) milestone is '$actualMilestone', expected no milestone.")
    }
}

$finalProjectItems = @(Get-ProjectIssueItems -ProjectId $project.id)
$verifiedProjectStoryIds = @{}

foreach ($item in $finalProjectItems) {
    if (
        ($null -ne $item.content) -and
        ($item.content.repository.nameWithOwner -eq $Repository) -and
        ($item.content.title -match '^(HYD-US-\d{3}):')
    ) {
        $storyId = $Matches[1]
        $verifiedProjectStoryIds[$storyId] = $true

        $statusName = $null

        if ($null -ne $item.fieldValueByName) {
            $statusName = $item.fieldValueByName.name
        }

        $expectedStory = @($stories | Where-Object { $_.Id -eq $storyId } | Select-Object -First 1)

        if ($expectedStory.Count -eq 1) {
            $expectedColumn = $expectedStory[0].ProjectColumn

            if (-not [string]::Equals($statusName, $expectedColumn, [System.StringComparison]::OrdinalIgnoreCase)) {
                $verificationErrors.Add("$storyId is in project Status '$statusName', expected '$expectedColumn'.")
            }
        }
    }
}

foreach ($story in $stories) {
    if (-not $verifiedProjectStoryIds.ContainsKey($story.Id)) {
        $verificationErrors.Add("$($story.Id) is missing from project '$ProjectName'.")
    }
}

if ($verificationErrors.Count -gt 0) {
    throw "Verification failed:`n - $($verificationErrors -join "`n - ")"
}

Write-Host ''
Write-Host 'Hydrion user-story publication completed successfully.' -ForegroundColor Green
Write-Host "Created issues:                 $createdCount"
Write-Host "Reused issues:                  $reusedCount"
Write-Host "Issue title/body updated:       $contentUpdatedCount"
Write-Host "Issue title/body already set:   $contentAlreadyCorrectCount"
Write-Host "Added to project:               $projectAddedCount"
Write-Host "Labels/milestones updated:      $metadataUpdatedCount"
Write-Host "Labels/milestones already set:  $metadataAlreadyCorrectCount"
Write-Host "Status values updated:          $statusUpdatedCount"
Write-Host "Status values already correct:  $statusAlreadyCorrectCount"
Write-Host "Story size field synced:        $sizeFieldSyncedCount"
Write-Host "Story size field skipped:       $sizeFieldSkippedCount"
Write-Host "Project cards ranked:           $rankedCardCount"
Write-Host "Verified stories:               $ExpectedStoryCount"
Write-Host "Backup file:                    $backupPath"

if (-not $AllowExistingNumberedItems) {
    Write-Host 'Verified numbering:             HYD-US-001 = #1 through HYD-US-051 = #51'
}
