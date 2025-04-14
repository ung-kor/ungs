resource "aws_security_group" "sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["10.0.0.0/8"]
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

resource "aws_instance" "nonbastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = var.pub_subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "Nonbastion"
  }
}

data "boundary_scope" "project" {
  name     = var.boundary_prj_name
  scope_id = var.boundary_scope_id
}

resource "boundary_host_catalog_static" "server_host" {
  name     = "nonBastion"
  scope_id = data.boundary_scope.project.id
}

resource "boundary_host_static" "server_host" {
  name            = "my_test"
  address         = aws_instance.nonbastion.private_ip
  host_catalog_id = boundary_host_catalog_static.server_host.id
}

resource "boundary_host_set_static" "server_host" {
  name            = "server_host"
  host_catalog_id = boundary_host_catalog_static.server_host.id
  host_ids        = [boundary_host_static.server_host.id]
}

resource "boundary_credential_store_static" "ssh_static_store" {
  name        = "ssh-static-store"
  description = "Static credential store for SSH"
  scope_id    = data.boundary_scope.project.id
}

resource "boundary_credential_ssh_private_key" "ssh_key_library" {
  name                = "ssh-key-library"
  credential_store_id = boundary_credential_store_static.ssh_static_store.id
  description         = "SSH Private Key Credential"
  username            = var.ssh_user
  private_key         = file(var.private_key_path)
}


resource "boundary_target" "server_host" {
  name                     = "server_host"
  type                     = "ssh"
  default_port             = "22"
  scope_id                 = data.boundary_scope.project.id
  session_connection_limit = 1
  host_source_ids = [
    boundary_host_set_static.server_host.id
  ]
  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.ssh_key_library.id
  ]
  egress_worker_filter = "\"true\" in \"/tags/ec2\""
}