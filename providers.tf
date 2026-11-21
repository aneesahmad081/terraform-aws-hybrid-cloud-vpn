# On-premises SIMULATION: an EC2 VPN appliance in us-east-1.
provider "aws" {
  alias  = "onprem"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Lab       = "Hybrid-Site-to-Site-VPN"
    }
  }
}

# Cloud side: a private EC2 and managed AWS VPN gateway in eu-north-1.
provider "aws" {
  alias  = "cloud"
  region = "eu-north-1"

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Lab       = "Hybrid-Site-to-Site-VPN"
    }
  }
}
