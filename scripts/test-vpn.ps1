# Run from the Terraform project ROOT in Windows PowerShell 5+ / PowerShell 7+.
# This uses AWS Systems Manager; no SSH keys or public inbound SSH needed.
$ErrorActionPreference = 'Stop'

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw 'Terraform command not found. Install Terraform and run from project root.'
}
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI command not found. Install AWS CLI v2.'
}

$routerId = (terraform output -raw router_instance_id).Trim()
$privateIp = (terraform output -raw cloud_private_ip).Trim()
$vpnId = (terraform output -raw vpn_connection_id).Trim()

Write-Host "Router: $routerId (us-east-1)"
Write-Host "Private web server: $privateIp (eu-north-1)"
Write-Host "VPN: $vpnId"

Write-Host "`nAWS VPN tunnel telemetry:"
aws ec2 describe-vpn-connections --region eu-north-1 `
  --vpn-connection-ids $vpnId `
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]' `
  --output table

$payload = @{
  InstanceIds  = @($routerId)
  DocumentName = 'AWS-RunShellScript'
  Comment      = 'Hybrid VPN lab: test Libreswan and private connectivity'
  Parameters   = @{
    commands = @(
      'sudo ipsec status',
      'sudo ipsec trafficstatus',
      "ping -c 4 $privateIp",
      "curl --max-time 15 -fsS http://$($privateIp):8080"
    )
  }
} | ConvertTo-Json -Depth 10

$tempFile = Join-Path $env:TEMP "hybrid-vpn-test-$PID.json"
try {
 [System.IO.File]::WriteAllText($tempFile, $payload, [System.Text.UTF8Encoding]::new($false))
  $uri = 'file://' + ($tempFile -replace '\\','/')
  $commandId = (aws ssm send-command --region us-east-1 `
    --cli-input-json $uri `
    --query 'Command.CommandId' --output text).Trim()

  if ($LASTEXITCODE -ne 0 -or -not $commandId) {
    throw 'SSM send-command failed. Check that EC2-B is online in Systems Manager.'
  }
  Write-Host "`nSSM command ID: $commandId"

  $status = 'Pending'
  for ($attempt = 0; $attempt -lt 40; $attempt++) {
    Start-Sleep -Seconds 3
    $status = (aws ssm get-command-invocation --region us-east-1 `
      --command-id $commandId --instance-id $routerId `
      --query 'Status' --output text 2>$null)
    if ($status -in @('Success','Failed','Cancelled','TimedOut','Cancelling')) { break }
  }

  Write-Host "`nCommand result: $status"
  aws ssm get-command-invocation --region us-east-1 `
    --command-id $commandId --instance-id $routerId `
    --query '{Status:Status,Output:StandardOutputContent,Errors:StandardErrorContent}' `
    --output json

  if ($status -ne 'Success') {
    Write-Warning 'Review IPsec, routing, VPN tunnel status, and security groups.'
  }
}
finally {
  Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
}
