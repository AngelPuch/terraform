output "url_local" {
  description = "Dirección para consultar Nginx desde el mismo equipo Linux."
  value       = "http://127.0.0.1:${var.external_port}"
}

output "container_name" {
  description = "Nombre del contenedor creado por Terraform."
  value       = docker_container.web.name
}
