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
}