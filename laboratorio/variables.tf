variable "external_port" {
  description = "Puerto publicado en el equipo Linux que ejecuta Docker."
  type        = number

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535 && floor(var.external_port) == var.external_port
    error_message = "El puerto debe ser un entero entre 1024 y 65535."
  }
}
