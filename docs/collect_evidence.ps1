param(
    [Parameter(Mandatory = $true)][string]$GodotPath,
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'verification\latest')
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
$gameRoot = Join-Path $ProjectRoot 'game'
if (-not (Test-Path -LiteralPath (Join-Path $gameRoot 'project.godot'))) {
    throw 'ProjectRoot must contain game/project.godot'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$engineVersion = (& $GodotPath --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Godot version' }
$maps = @()
$transitions = @()
$totalNpcs = 0
$totalWalkers = 0
$mapIdsText = Get-Content -LiteralPath (Join-Path $gameRoot 'scripts\route_map.gd') -Raw
$mapIdsLine = [regex]::Match($mapIdsText, 'const MAP_IDS := \[(.*?)\]').Groups[1].Value
$mapIds = @([regex]::Matches($mapIdsLine, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
if ($mapIds.Count -eq 0) { throw 'Cannot find active MAP_IDS' }
foreach ($mapId in $mapIds) {
    $map = Get-Content -LiteralPath (Join-Path $gameRoot "maps\$mapId.json") -Raw | ConvertFrom-Json
    $npcCount = @($map.npcs).Count
    $walkerCount = @($map.npcs | Where-Object { $_.path -and $_.path.Count -gt 0 }).Count
    $totalNpcs += $npcCount
    $totalWalkers += $walkerCount
    $maps += [ordered]@{
        id = $mapId
        title = $map.title
        size = @($map.size)
        npc_count = $npcCount
        walkers = $walkerCount
        exits = @($map.exits).Count
    }
    foreach ($exit in $map.exits) {
        $transitions += [ordered]@{
            from = $mapId
            to = $exit.to
            rect = @($exit.rect)
            spawn = @($exit.spawn)
            label = $exit.label
            contextual_return = [bool]$exit.contextual_return
        }
    }
}
$tiles = Get-Content -LiteralPath (Join-Path $gameRoot 'maps\tiles.json') -Raw | ConvertFrom-Json
$characters = Get-Content -LiteralPath (Join-Path $gameRoot 'maps\characters.json') -Raw | ConvertFrom-Json
$anim = Get-Content -LiteralPath (Join-Path $gameRoot 'maps\anim.json') -Raw | ConvertFrom-Json
$hashes = @()
foreach ($area in @('scripts','scenes','maps','assets')) {
    foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $gameRoot $area) -Recurse -File | Where-Object { $_.Extension -in @('.gd','.tscn','.json','.png') } | Sort-Object FullName)) {
        $hashes += [ordered]@{path = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\','/'); sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
    }
}
foreach ($relative in @('game\project.godot','game\tileset.tres')) {
    $hashes += [ordered]@{path = $relative.Replace('\','/'); sha256 = (Get-FileHash -LiteralPath (Join-Path $ProjectRoot $relative) -Algorithm SHA256).Hash}
}
$tests = @(
    @{name='check_day_quests'; expected='^PASS day:'},
    @{name='check_people_update'; expected='^PASS update:'},
    @{name='check_route'; expected='^PASS route:'},
    @{name='check_arch_atm'; expected='ARCH / ATM FAILURES: 0'},
    @{name='check_doorway_visuals'; expected='VISUAL STRUCTURE FAILURES: 0'},
    @{name='check_rooms'; expected='ROOM FAILURES: 0'},
    @{name='check_corridor'; expected='CORRIDOR FAILURES: 0'},
    @{name='check_fixes'; expected='REGRESSIONS: 0'},
    @{name='check_stair_return'; expected='STAIR RETURN FAILURES: 0'}
)
$results = @()
foreach ($test in $tests) {
    $outputPath = Join-Path $OutputDirectory ($test.name + '.log')
    $engineLog = Join-Path $OutputDirectory ($test.name + '.engine.log')
    & $GodotPath --headless --path $gameRoot --script "res://tools/$($test.name).gd" --quit-after 600 --log-file $engineLog *> $outputPath
    $testExitCode = $LASTEXITCODE
    $log = Get-Content -LiteralPath $outputPath -Raw
    $summary = @(Get-Content -LiteralPath $outputPath | Where-Object { $_ -match $test.expected })
    $passed = $testExitCode -eq 0 -and $summary.Count -gt 0 -and $log -notmatch '(?m)^SCRIPT ERROR:|^ERROR:'
    $results += [ordered]@{name=$test.name; exit_code=$testExitCode; passed=$passed; summary=($summary -join '; '); log=($test.name+'.log')}
    Write-Output "$($test.name): $passed | $($summary -join '; ')"
}
$snapshot = [ordered]@{
    captured_at = (Get-Date -Format o)
    project_root = $ProjectRoot
    engine_version = $engineVersion
    verification_mode = 'Godot headless script checks; visual screenshots are documented separately'
    map_count = $maps.Count
    transition_zone_count = $transitions.Count
    npc_placement_count = $totalNpcs
    npc_walking_placement_count = $totalWalkers
    character_sheet_count = @($characters.people).Count
    tile_catalog_entry_count = @($tiles.tiles).Count
    tile_static_entry_count = @($tiles.tiles | Where-Object { -not $_.source -or $_.source -eq 0 }).Count
    animation_loop_count = @($anim.loops).Count
    animation_strip_count = @($anim.strips).Count
    maps = $maps
    transitions = $transitions
    tests = $results
    runtime_files_sha256 = $hashes
}
$snapshot | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'snapshot.json') -Encoding utf8
if (@($results | Where-Object { -not $_.passed }).Count -gt 0) { throw 'Some checks failed; see snapshot.json and logs' }
Write-Output "Saved: $(Join-Path $OutputDirectory 'snapshot.json')"
