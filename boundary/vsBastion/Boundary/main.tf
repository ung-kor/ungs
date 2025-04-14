resource "boundary_scope" "org" {
  name                     = "${var.environment}_org"
  scope_id                 = "global"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = "${var.environment}_prj"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_credential_store_static" "ssh" {
  name     = "static_credential_store"
  scope_id = boundary_scope.project.id
}

resource "aws_security_group" "worker_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "worker" {
  ami = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.worker_sg.id]
  subnet_id              = var.pub_subnet_id
  key_name               = var.key_name

  user_data = <<-EOT
#!/bin/bash
apt-get -y update 
apt-get -y install jq unzip 
wget -q "$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/boundary/latest?license_class=enterprise" | jq -r '.builds[] | select(.arch == "amd64" and .os == "linux") | .url')" 
unzip *.zip 
IP_ADDR=$(ip -4 addr show ens5 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

export BOUNDARY_ADDR=${var.boundary_addr}

export BOUNDARY_PASSWD=${var.boundary_admin_password}
./boundary authenticate password -login-name=${var.boundary_admin_id} -password=env://BOUNDARY_PASSWD -format=json | jq .item.attributes.token | tr -d '"' > boundary.token
export BOUNDARY_TOKEN=$(cat boundary.token)
echo $BOUNDARY_TOKEN
./boundary workers create controller-led -scope-id=global -format=json | jq .item.controller_generated_activation_token | tr -d '"' > worker.token
WORK_TOKEN=$(cat worker.token)
echo $WORK_TOKEN

cat <<EOH > /home/ubuntu/worker.hcl
disable_mlock = true
hcp_boundary_cluster_id = "${var.boundary_cluster_id}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr = "$${IP_ADDR}"
  auth_storage_path = "/home/ubuntu/worker1"
  controller_generated_activation_token = "$${WORK_TOKEN}"
  tags {
    ec2 = ["true"]
  }
}
EOH
nohup ./boundary server -config="/home/ubuntu/worker.hcl" > /home/ubuntu/worker.log 2>&1 &
EOT
  tags = {
    Name = "worker"
  }
  lifecycle { create_before_destroy = true }
}

output "pip" {
  value = aws_instance.worker.public_ip
}

output "org_id" {
  value = boundary_scope.org.id
}