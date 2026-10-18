# Terraform solicita a Docker la descarga de una imagen de Nginx.
resource "docker_image" "nginx" {
  name         = "nginx:1.28.0-alpine"
  keep_locally = false
}

# La referencia a image_id establece la dependencia con la imagen.
resource "docker_container" "web" {
  name  = "laboratorio-terraform-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
    ip       = "0.0.0.0"
  }
}
