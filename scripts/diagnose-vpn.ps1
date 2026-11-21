# Run from project root after terraform apply.
$ErrorActionPreference = 'Stop'
$routerId = (terraform output -raw router_instance_id).Trim()
$vpnId = (terraform output -raw vpn_connection_id).Trim()
$assocId = (terraform output -raw ssm_association_id).Trim()

Write-Host "AWS VPN in eu-north-1 ($vpnId):"
aws ec2 describe-vpn-connections --region eu-north-1 `
  --vpn-connection-ids $vpnId `
  --query 'VpnConnections[0].VgwTelemetry' --output table

Write-Host "`nSSM association ($assocId) in us-east-1:"
aws ssm describe-association --region us-east-1 `
  --association-id $assocId `
  --query 'AssociationDescription.{Name:Name,Status:Overview.Status,LastExecutionDate:LastExecutionDate}' `
  --output json

Write-Host "`nRouter instance ($routerId) in SSM Fleet Manager:"
aws ssm describe-instance-information --region us-east-1 `
  --filters "Key=InstanceIds,Values=$routerId" `
  --query 'InstanceInformationList[*].{InstanceId:InstanceId,PingStatus:PingStatus,Platform:PlatformName}' `
  --output table

Write-Host "`nFor Linux logs, start an SSM session or run a shell command using Systems Manager:"
Write-Host 'sudo journalctl -u ipsec -n 100 --no-pager'
