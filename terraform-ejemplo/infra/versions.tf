terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Terraform y Docker deben ejecutarse en el mismo entorno Linux/WSL/VM.
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
