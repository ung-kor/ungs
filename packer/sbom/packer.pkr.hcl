packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  default = "ap-northeast-2"
}

source "amazon-ebs" "ubuntu-nginx" {
  region                  = var.region
  instance_type           = "t2.micro"
  ssh_username            = "ubuntu"
  ami_name                = "ubuntu-nginx-{{timestamp}}"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu-nginx"
  ]

  hcp_packer_registry {
    bucket_name = "apne2-nomad-server-ubuntu"
    description = <<EOT
Some nice description about the image being published to HCP Packer Registry.
    EOT
    bucket_labels = {
      "owner"   = "ung"
      "os"      = "Ubuntu"
      "nomad"   = "server"
      "version" = "1.0"
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx curl",
      "sudo curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin",
      "sudo syft dir:/ -o cyclonedx-json > /tmp/sbom_cyclonedx.json"
    ]
  }

  provisioner "hcp-sbom" {
    source      = "/tmp/sbom_cyclonedx.json"
    destination = "./sbom/sbom_cyclonedx.json"
    sbom_name   = "sbom-cyclonedx"
  }
}