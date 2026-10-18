variable "external_port" {
  description = "Puerto HTTP publicado en el equipo que ejecuta Docker."
  type        = number
  default     = 8080

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535 && floor(var.external_port) == var.external_port
    error_message = "Usa un puerto entero entre 1024 y 65535."
  }
}

variable "bind_ip" {
  description = "127.0.0.1 para acceso local; 0.0.0.0 si se accede a una VM desde Windows."
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = contains(["127.0.0.1", "0.0.0.0"], var.bind_ip)
    error_message = "Usa 127.0.0.1 o 0.0.0.0."
  }
}

variable "app_title" {
  description = "Título de la página, enviado como variable de entorno al contenedor."
  type        = string
  default     = "Tareas del equipo"

  validation {
    condition     = length(trimspace(var.app_title)) > 0 && length(var.app_title) <= 80
    error_message = "El título debe tener entre 1 y 80 caracteres."
  }
}
