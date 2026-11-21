output "regions" {
  description = "Lab regions and their roles"
  value = {
    simulated_onpremises = "us-east-1"
    private_cloud        = "eu-north-1"
  }
}

output "onprem_vpc_id" {
  value = aws_vpc.onprem.id
}

output "cloud_vpc_id" {
  value = aws_vpc.cloud.id
}

output "router_instance_id" {
  value = aws_instance.router.id
}

output "router_elastic_ip" {
  value = aws_eip.router.public_ip
}

output "router_private_ip" {
  value = aws_instance.router.private_ip
}

output "cloud_instance_id" {
  value = aws_instance.cloud_server.id
}

output "cloud_private_ip" {
  value = aws_instance.cloud_server.private_ip
}

output "private_http_url" {
  value = "http://${aws_instance.cloud_server.private_ip}:8080"
}

output "vpn_connection_id" {
  value = aws_vpn_connection.s2s.id
}

output "vpn_outside_ips" {
  description = "AWS VPN outside tunnel IPs (not secrets)."
  value = {
    tunnel1 = aws_vpn_connection.s2s.tunnel1_address
    tunnel2 = aws_vpn_connection.s2s.tunnel2_address
  }
}

output "ssm_association_id" {
  value = aws_ssm_association.configure_router.association_id
}
