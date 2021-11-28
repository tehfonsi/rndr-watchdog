$LOCAL = $false
$BASE_URL = "https://rndr-stats.netlify.app/api"
if ($LOCAL){$BASE_URL = "http://localhost:8888/api"}

$WALLETID = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name WALLETID -errorAction SilentlyContinue).WALLETID
$JOBS_COMPLETED = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name JOBS_COMPLETED -errorAction SilentlyContinue).JOBS_COMPLETED
$NODEID = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name NODEID -errorAction SilentlyContinue).NODEID
$THUMBNAILS_SENT = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name THUMBNAILS_SENT -errorAction SilentlyContinue).THUMBNAILS_SENT
$SCORE = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name SCORE -errorAction SilentlyContinue).SCORE
$PREVIEWS_SENT = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name PREVIEWS_SENT -errorAction SilentlyContinue).PREVIEWS_SENT
$JOBS_COMPLETED = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\OTOY -Name JOBS_COMPLETED -errorAction SilentlyContinue).JOBS_COMPLETED

$RNDRClientLogs = "$env:localappdata\OtoyRndrNetwork\rndr_log.txt"
$RNDRClientConfig = "$env:localappdata\OtoyRndrNetwork\rndr-config.ini"
$GPUS = (Select-String -Path $RNDRClientConfig -Pattern "gpu\d_name" -AllMatches) | ForEach-Object { $_.Line.Substring($_.Line.IndexOf('=')+1, $_.Line.length - ($_.Line.IndexOf('=')+1)).Trim() }

$global:LastJobSent = $null

Function Get-Last-Job-Finished {
  $Logs = Get-Content -Tail 50 $RNDRClientLogs
  $Job = @{};
  foreach ($Line in $Logs) {
    if ($Line -match "completed successfully") {
      $Job.End = [Datetime]::ParseExact($Line.Substring(0,19).Trim(),"yyyy-MM-dd HH:mm:ss",$null)
      $Job.Time = $Line.Substring(19) -replace "[^0-9.]" , ''
      $Job.Result = 'Success'
    }
    if ($Line -match "job was canceled") {
      $Job.End = [Datetime]::ParseExact($Line.Substring(0,19).Trim(),"yyyy-MM-dd HH:mm:ss",$null)
      $Job.Time = 0
      $Job.Result = 'Cancel'
    }
    if ($Line -match "job failed") {
      $Job.End = [Datetime]::ParseExact($Line.Substring(0,19).Trim(),"yyyy-MM-dd HH:mm:ss",$null)
      $Job.Time = 0
      $Job.Result = 'Fail'
    }
    if ($Line -match "new render job") {
      $StartDate = [Datetime]::ParseExact($Line.Substring(0,19).Trim(),"yyyy-MM-dd HH:mm:ss",$null)
      $Job.Start = $StartDate
      $Job.Id = $StartDate.Ticks / 10000000
    }
  }
  return $Job
}

Function Send-Job($Job) {
  Write-Host Send Job

  $URL = "$($BASE_URL)/job"
  $Start = $Job.Start.ToUniversalTime().ToString("o")
  $End = $Job.End.ToUniversalTime().ToString("o")
  $Params = @{node_id=$NODEID;start=$Start;end=$End;time=$Job.Time;result=$Job.Result}
  $Result = Invoke-WebRequest -Uri $URL -Method POST -Body ($Params|ConvertTo-Json) -ContentType "application/json"

  $global:LastJobSent = $LastJobFinished
}

Function Check-Job {
  $LastJobFinished = Get-Last-Job-Finished
  if ($null -eq $global:LastJobSent) {
    $global:LastJobSent = $LastJobFinished
  }
  if ($global:LastJobSent.Id -ne $LastJobFinished.Id) {
    Send-Job($LastJobFinished)
  }
}

Function Set-State($CurrentActivity) {
  $URL = "$($BASE_URL)/state"
  $Params = @{node_id=$NODEID;type=$CurrentActivity}
  $Result = Invoke-WebRequest -Uri $URL -Method POST -Body ($Params|ConvertTo-Json) -ContentType "application/json"

  # always check job e.g. when switching from rendering to mining or idle
  Check-Job
}

Function Set-Operator {
  $URL = "$($BASE_URL)/operator"
  $Params = @{eth_address=$WALLETID}
  $Result = Invoke-WebRequest -Uri $URL -Method PUT -Body ($Params|ConvertTo-Json) -ContentType "application/json"
}

Function Set-Node {
  $URL = "$($BASE_URL)/node"
  $Params = @{eth_address=$WALLETID;node_id=$NODEID;score=$SCORE;previews_sent=$PREVIEWS_SENT;jobs_completet=$JOBS_COMPLETED;thumbnails_sent=$THUMBNAILS_SENT;gpus=$GPUS}
  $Result = Invoke-WebRequest -Uri $URL -Method PUT -Body ($Params|ConvertTo-Json) -ContentType "application/json"
}

Function Set-RNDR-Info {
  Set-Operator
  Set-Node
  Check-Job
}