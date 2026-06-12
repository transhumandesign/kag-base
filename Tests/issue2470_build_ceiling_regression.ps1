Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Regression coverage for issue 2470: ceiling desync build placement.
# This mirrors the placement decision that matters for the bug. A trampoline can
# push the server-side builder position above the map top while the client still
# aims at a valid lower tile; pre-fix server checks accepted that command.

$TileSize = 8.0
$MapWidth = 200.0
$MaxBuildLength = 4.0

function Assert-SourceContains([string] $path, [string] $needle) {
    $content = Get-Content -Raw -Path $path
    if (-not $content.Contains($needle)) {
        throw "Expected '$path' to contain '$needle'"
    }
}

function New-Vec2([double] $x, [double] $y) {
    [pscustomobject]@{ X = $x; Y = $y }
}

function Sub-Vec2($a, $b) {
    New-Vec2 ($a.X - $b.X) ($a.Y - $b.Y)
}

function Add-Vec2($a, $b) {
    New-Vec2 ($a.X + $b.X) ($a.Y + $b.Y)
}

function Scale-Vec2($a, [double] $scale) {
    New-Vec2 ($a.X * $scale) ($a.Y * $scale)
}

function Get-Length($a) {
    [Math]::Sqrt(($a.X * $a.X) + ($a.Y * $a.Y))
}

function Normalize-Vec2($a) {
    $length = Get-Length $a
    if ($length -le 0.0) {
        throw "Cannot normalize a zero vector"
    }
    Scale-Vec2 $a (1.0 / $length)
}

function Get-TileWorldPosition($pos) {
    New-Vec2 ([Math]::Floor($pos.X / $TileSize) * $TileSize) ([Math]::Floor($pos.Y / $TileSize) * $TileSize)
}

function Get-ServerTileAimPos($builderPos, $aimPos) {
    $mouse = Sub-Vec2 $aimPos $builderPos
    $mouseLen = Get-Length $mouse

    if ($mouseLen -gt ($MaxBuildLength * $TileSize)) {
        $p = Add-Vec2 $builderPos (Scale-Vec2 (Normalize-Vec2 $mouse) ($MaxBuildLength * $TileSize))
        return Get-TileWorldPosition $p
    }

    Get-TileWorldPosition $aimPos
}

function Test-WithinBuildMapBounds($pos) {
    $pos.Y -ge (2.0 * $TileSize) -and
    $pos.X -ge (2.0 * $TileSize) -and
    $pos.X -le (($MapWidth - 2.0) * $TileSize)
}

function Test-OldServerBlockCheck($builderPos, $cursorPos) {
    $halfDelta = Scale-Vec2 (Sub-Vec2 $builderPos $cursorPos) 0.5
    if ((Get-Length $halfDelta) -gt 30.0) {
        return $false
    }

    # Target is otherwise valid: supported, non-solid, not collapsing, not a
    # same-tile repair, and just below the ceiling no-build sector.
    $targetCenter = Add-Vec2 $cursorPos (New-Vec2 ($TileSize * 0.5) ($TileSize * 0.5))
    if ($targetCenter.Y -lt (3.0 * $TileSize)) {
        return $false
    }

    $true
}

function Test-FixedServerBlockCheck($builderPos, $cursorPos) {
    $targetCenter = Add-Vec2 $cursorPos (New-Vec2 ($TileSize * 0.5) ($TileSize * 0.5))
    if (-not (Test-WithinBuildMapBounds $builderPos) -or -not (Test-WithinBuildMapBounds $targetCenter)) {
        return $false
    }

    Test-OldServerBlockCheck $builderPos $cursorPos
}

function Test-OldServerBlobCheck($builderPos, $cursorPos) {
    $halfDelta = Scale-Vec2 (Sub-Vec2 $builderPos $cursorPos) 0.5
    if ((Get-Length $halfDelta) -gt 30.0) {
        return $false
    }

    # Target is otherwise valid. This is the cooldown-burning path described in
    # the issue comments for doors/ladders and other snap-to-grid blobs.
    $true
}

function Test-FixedServerBlobCheck($builderPos, $cursorPos) {
    if (-not (Test-WithinBuildMapBounds $builderPos) -or -not (Test-WithinBuildMapBounds $cursorPos)) {
        return $false
    }

    Test-OldServerBlobCheck $builderPos $cursorPos
}

function Assert-True([bool] $condition, [string] $message) {
    if (-not $condition) {
        throw $message
    }
}

function Assert-False([bool] $condition, [string] $message) {
    if ($condition) {
        throw $message
    }
}

function Assert-Vec2($actual, [double] $expectedX, [double] $expectedY, [string] $message) {
    if ([Math]::Abs($actual.X - $expectedX) -gt 0.001 -or [Math]::Abs($actual.Y - $expectedY) -gt 0.001) {
        throw "$message actual=($($actual.X), $($actual.Y)) expected=($expectedX, $expectedY)"
    }
}

$serverBuilderPos = New-Vec2 400.0 -8.0
$clientAimPos = New-Vec2 400.0 64.0
$tileCursorPos = Get-ServerTileAimPos $serverBuilderPos $clientAimPos

Assert-Vec2 $tileCursorPos 400.0 24.0 "server tile aim should jump closer when builder is above map"
Assert-False (Test-WithinBuildMapBounds $serverBuilderPos) "repro builder position should be outside build bounds"
Assert-True (Test-OldServerBlockCheck $serverBuilderPos $tileCursorPos) "pre-fix block placement should reproduce bad server accept"
Assert-False (Test-FixedServerBlockCheck $serverBuilderPos $tileCursorPos) "fixed block placement should reject ceiling-desynced builder"

$blobCursorPos = Add-Vec2 $tileCursorPos (New-Vec2 ($TileSize * 0.5) ($TileSize * 0.5))

Assert-Vec2 $blobCursorPos 404.0 28.0 "blob cursor should use the bottom-of-cursor snap position"
Assert-True (Test-OldServerBlobCheck $serverBuilderPos $blobCursorPos) "pre-fix blob placement should reproduce bad server accept/cooldown path"
Assert-False (Test-FixedServerBlobCheck $serverBuilderPos $blobCursorPos) "fixed blob placement should reject ceiling-desynced builder"

Assert-SourceContains "Entities\Common\Building\PlacementCommon.as" "bool isWithinBuildMapBounds(CMap@ map, Vec2f p)"
Assert-SourceContains "Entities\Common\Building\BlockPlacement.as" "isWithinBuildMapBounds(map, blob.getPosition())"
Assert-SourceContains "Entities\Common\Building\BlobPlacement.as" "isWithinBuildMapBounds(map, blob.getPosition())"
Assert-SourceContains "Entities\Characters\MovementScripts\RunnerMovement.as" "if (blob.isMyPlayer() || isServer())"

Write-Output "issue2470 regression passed"
