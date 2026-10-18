locals {
  # Se incluyen solo los archivos que afectan a la imagen.
  app_files = concat(
    ["Dockerfile", ".dockerignore", "requirements.txt", "app.py"],
    sort(tolist(fileset("${path.module}/../app", "templates/**"))),
    sort(tolist(fileset("${path.module}/../app", "static/**")))
  )
  app_hash = sha256(join("", [
    for file in local.app_files : "${file}:${filesha256("${path.module}/../app/${file}")}"
  ]))
}

# 1. Docker construye la imagen; Terraform solicita y administra la operación.
resource "docker_image" "app" {
  name         = "tareas-terraform:demo"
  keep_locally = true

  build {
    context = abspath("${path.module}/../app")
  }

  triggers = {
    source_hash = local.app_hash
  }
}

# 2. Red explícita del ejemplo.
resource "docker_network" "app" {
  name = "tareas-terraform-net"
}

# 3. La base de datos vive fuera de la capa escribible del contenedor.
resource "docker_volume" "data" {
  name = "tareas-terraform-data"
}

# 4. Las referencias crean las dependencias con imagen, red y volumen.
resource "docker_container" "app" {
  name    = "tareas-terraform-app"
  image   = docker_image.app.image_id
  restart = "unless-stopped"
  wait    = true

  wait_timeout = 90
  env = [
    "APP_TITLE=${var.app_title}",
    "DB_PATH=/data/tasks.db"
  ]

  ports {
    internal = 5000
    external = var.external_port
    ip       = var.bind_ip
  }

  networks_advanced {
    name = docker_network.app.name
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/data"
  }
}
