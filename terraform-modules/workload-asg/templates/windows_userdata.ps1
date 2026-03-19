<powershell>
################################################################################
# workload-asg Windows Server 2022 userdata
# Runs under EC2Launch v2 — executes once on first boot
################################################################################

# IMDSv2 — fetch token then metadata
$Token = Invoke-RestMethod -Method PUT `
  -Uri "http://169.254.169.254/latest/api/token" `
  -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "300"}

$Headers     = @{"X-aws-ec2-metadata-token" = $Token}
$InstanceId  = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-id"                    -Headers $Headers
$Hostname    = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/hostname"                       -Headers $Headers
$PrivateIp   = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/local-ipv4"                    -Headers $Headers
$InstType    = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-type"                  -Headers $Headers
$Az          = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/placement/availability-zone"    -Headers $Headers

################################################################################
# Install IIS
################################################################################
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

################################################################################
# Write homepage
################################################################################
$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>workload-asg demo</title>
  <style>
    body { font-family: monospace; background: #1a1a2e; color: #e0e0e0; padding: 2rem; }
    h1   { color: #00d4ff; }
    table { border-collapse: collapse; margin-top: 1rem; }
    td, th { border: 1px solid #444; padding: 0.5rem 1rem; text-align: left; }
    th { background: #16213e; color: #00d4ff; }
    tr:nth-child(even) { background: #0f3460; }
  </style>
</head>
<body>
  <h1>workload-asg — Windows Server 2022</h1>
  <table>
    <tr><th>Field</th><th>Value</th></tr>
    <tr><td>Instance ID</td><td>$InstanceId</td></tr>
    <tr><td>Hostname</td><td>$Hostname</td></tr>
    <tr><td>Private IP</td><td>$PrivateIp</td></tr>
    <tr><td>Instance Type</td><td>$InstType</td></tr>
    <tr><td>Availability Zone</td><td>$Az</td></tr>
  </table>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $Html -Encoding UTF8

################################################################################
# Ensure IIS is running and set to auto-start
################################################################################
Set-Service -Name W3SVC -StartupType Automatic
Start-Service -Name W3SVC
</powershell>
