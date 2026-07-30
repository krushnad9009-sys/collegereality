$ErrorActionPreference = "Stop"
$lcov = Join-Path $PSScriptRoot "..\coverage\lcov.info"
if (-not (Test-Path $lcov)) { throw "Missing coverage/lcov.info. Run flutter test --coverage first." }

$include = '[\\/](utils|models|services|cache|constants|repositories)[\\/]'
# Exclude Firebase/network orchestration services and thin repository passthroughs.
$exclude = @(
  'firebase_options\.dart$',
  'firestore_',
  '_firestore_service\.dart$',
  'local_notification_service\.dart$',
  'review_storage_service\.dart$',
  'profile_storage_service\.dart$',
  'phone_auth_service\.dart$',
  'google_auth_helper\.dart$',
  'admin_analytics_service\.dart$',
  'college_community_feed_service\.dart$',
  'ai_assistant_service\.dart$',
  'college_seed_service\.dart$',
  'college_discussion_service\.dart$',
  'moderation_service\.dart$',
  'firebase_messaging_service\.dart$',
  'admin_user_moderation_service\.dart$',
  'notification_bridge_service\.dart$',
  'display_name_service\.dart$',
  '[\\/]repositories[\\/]'
)

function ShouldExclude([string]$sf) {
  foreach ($p in $exclude) { if ($sf -match $p) { return $true } }
  return $false
}

$lf = 0; $lh = 0
$curSf = $null; $curLf = 0; $curLh = 0
Get-Content $lcov | ForEach-Object {
  if ($_ -like 'SF:*') { $curSf = $_.Substring(3); $curLf = 0; $curLh = 0 }
  elseif ($_ -like 'LF:*') { $curLf = [int]$_.Substring(3) }
  elseif ($_ -like 'LH:*') { $curLh = [int]$_.Substring(3) }
  elseif ($_ -eq 'end_of_record') {
    if ($curSf -and ($curSf -match $include) -and -not (ShouldExclude $curSf)) {
      $lf += $curLf; $lh += $curLh
    }
    $curSf = $null
  }
}

$pct = if ($lf -gt 0) { [math]::Round(100.0 * $lh / $lf, 2) } else { 0 }
Write-Host "Domain line coverage: $lh / $lf ($pct%)"
if ($pct -lt 80) {
  Write-Host "FAIL: coverage $pct% is below 80%"
  exit 1
}
Write-Host "PASS: coverage $pct% meets 80% threshold"
exit 0