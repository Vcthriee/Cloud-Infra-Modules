
# ============================================
# DATA SOURCE - LATEST AMAZON LINUX 2023 AMI
# Automatically finds newest official image
# ============================================

data "aws_ami" "amazon_linux_2023" {
  # Get most recent version
  most_recent = true
  
  # Only official Amazon images
  owners = ["amazon"]

  # Filter: Name matches pattern
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  # Filter: Hardware virtual machine (modern)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# This data source outputs:
# - id: AMI ID (e.g., ami-0123456789abcdef0)
# - name: AMI name
# Used in launch template to get latest security patches