output "local_url" {
  description = "URL desde el equipo Linux/WSL/VM que ejecuta Docker. Desde Windows hacia una VM, usa su IP."
  value       = "http://127.0.0.1:${var.external_port}"
}

output "container_name" {
  value = docker_container.app.name
}

output "volume_name" {
  value = docker_volume.data.name
}
