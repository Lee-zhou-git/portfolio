param(
    [string]$KnowledgeBase,
    [string]$Output = (Join-Path (Split-Path -Parent $PSScriptRoot) "assets\public-kb-v1.js")
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($KnowledgeBase)) {
    throw "Pass the reviewed chunks.jsonl path with -KnowledgeBase."
}
$chunks = @(Get-Content -LiteralPath $KnowledgeBase -Encoding UTF8 | ForEach-Object {
    if (-not [string]::IsNullOrWhiteSpace($_)) { $_ | ConvertFrom-Json }
})

$invalid = @($chunks | Where-Object {
    $_.visibility -ne "public" -or $_.reviewed -ne $true -or
    [string]::IsNullOrWhiteSpace($_.source_url) -or
    -not ([Uri]$_.source_url).Host.Equals("lee-zhou-git.github.io", [StringComparison]::OrdinalIgnoreCase)
})
if ($invalid.Count -gt 0) {
    throw "Refusing to export invalid or unreviewed knowledge chunks."
}

$payload = $chunks | Select-Object chunk_id, document_id, title, type, content, keywords, source_url, source_section |
    ConvertTo-Json -Compress -Depth 8
$js = "window.PUBLIC_KB_VERSION='1.1.0';window.PUBLIC_KB=$payload;"
$parent = Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $parent | Out-Null
[IO.File]::WriteAllText($Output, $js, [Text.UTF8Encoding]::new($false))
Write-Host "Exported $($chunks.Count) reviewed public chunks to $Output"
