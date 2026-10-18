# Laboratorio: desplegar Nginx con Terraform

**Duración estimada:** 15–20 minutos, con las herramientas instaladas.

## Objetivo

Crear un servidor web en Docker mediante Terraform, revisar los cambios antes de aplicarlos y eliminar los recursos al terminar.

## Escenario: antes → automatización → resultado

Se necesita publicar una página web de prueba en un servidor Linux. Se utilizará la página de bienvenida incluida en Nginx.

| Antes: proceso manual                                 | Automatización con Terraform                                                            | Resultado                               |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------- | --------------------------------------- |
| Descargar una imagen de Nginx.                        | Declarar un recurso `docker_image`.                                                     | Imagen disponible en Docker.            |
| Crear e iniciar un contenedor y configurar su puerto. | Declarar un recurso `docker_container` y ejecutar `terraform apply`.                    | Página web accesible en el puerto 8090. |
| Revisar qué existe y decidir qué cambiar.             | Ejecutar `terraform plan`, que compara la configuración con los recursos administrados. | Vista previa de los cambios necesarios. |
| Eliminar los recursos creados para la práctica.       | Ejecutar `terraform destroy`.                                                           | Recursos del laboratorio eliminados.    |

Docker ejecuta Nginx. Terraform administra la imagen y el contenedor mediante el proveedor Docker. La máquina Linux debe existir antes de comenzar.

## Requisitos previos

- Una VM Ubuntu
- Terraform CLI `>= 1.5, < 2.0` instalado dentro de Linux.
- Docker Engine activo y accesible sin `sudo` mediante `/var/run/docker.sock`.
- Git, curl y un editor de texto, por ejemplo nano.
- Internet para descargar el proveedor y la imagen de Nginx.
- Puerto 8090 disponible; para el reto se necesitará otro puerto libre.

Todos los comandos de Terraform y Docker se ejecutan en la misma terminal Linux.

Si se utiliza la VM del repositorio, desde PowerShell, en la carpeta que contiene el `Vagrantfile`:

```powershell
vagrant up
vagrant ssh
```

Comprobar que los siguientes comandos funcionan dentro de Linux:

```bash
terraform version
docker info
curl --version
```

## Archivos necesarios

| Archivo               | Función                                                     |
| --------------------- | ----------------------------------------------------------- |
| `versions.tf`         | Versión de Terraform, proveedor Docker y conexión al motor. |
| `main.tf`             | Imagen de Nginx y contenedor web.                           |
| `variables.tf`        | Definición y validación del puerto externo.                 |
| `terraform.tfvars`    | Valor inicial del puerto: 8090.                             |
| `outputs.tf`          | URL local y nombre del contenedor.                          |
| `.terraform.lock.hcl` | Versión y verificaciones del proveedor.                     |

## Instrucciones paso a paso

### 1. Entrar al laboratorio y comprobar el estado inicial

En la VM del repositorio:

```bash
cd /vagrant/laboratorio
```

\*\*A partir de aquí, ejecutar todos los comandos desde `laboratorio/`.

```bash
docker ps -a --filter name=laboratorio-terraform-web
curl --connect-timeout 2 http://127.0.0.1:8090
```

En un entorno nuevo, no debe aparecer el contenedor y curl debe indicar que no pudo conectarse. Este es el **antes**: todavía no existe el servidor web. Si aparece una página, el puerto ya está ocupado; usar otro puerto libre en `terraform.tfvars` y adaptar las direcciones de los pasos siguientes.

### 2. Revisar e inicializar la configuración

Abrir `main.tf` y localizar la imagen, el contenedor, el puerto interno `80` y la referencia `var.external_port`. Abrir `terraform.tfvars` para identificar el valor del puerto externo.

```bash
terraform init
terraform fmt -check
terraform validate
```

`init` instala el proveedor y prepara la carpeta. `validate` debe mostrar `Success! The configuration is valid.`

### 3. Consultar qué se va a crear

```bash
terraform plan
```

Resultado esperado en la primera ejecución:

```text
Plan: 2 to add, 0 to change, 0 to destroy.
```

Identificar los recursos `docker_image.nginx` y `docker_container.web`. El comando muestra una vista previa; todavía no crea el servidor.

### 4. Aplicar la automatización

```bash
terraform apply
```

Revisar el plan y escribir `yes` cuando Terraform solicite confirmación.

Resultado esperado:

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### 5. Comprobar el resultado

```bash
terraform output
docker ps
curl -I http://127.0.0.1:8090
curl http://127.0.0.1:8090
```

El contenedor debe aparecer en ejecución, el encabezado debe incluir `200 OK` y el HTML debe contener `Welcome to nginx!`. Si Nginx aún está iniciando, repetir curl unos segundos después.

Para verlo en un navegador:

- Desde Windows hacia la VM del repositorio: <http://192.168.33.30:8090>.

La URL `127.0.0.1` que muestra Terraform corresponde al equipo Linux donde se ejecuta Docker. El puerto se publica en sus interfaces para permitir también el acceso desde Windows a la VM.

### 6. Comprobar que no hay cambios pendientes

```bash
terraform plan
terraform state list
```

El plan debe mostrar `No changes. Your infrastructure matches the configuration.` y el estado debe listar los dos recursos. Repetir el plan sin modificar la configuración no crea otro contenedor.

## Reto final: cambiar el puerto

Publicar el mismo servidor en el puerto **8091**, sin ejecutar `docker run` ni modificar el puerto interno de Nginx.

1. Identificar en qué archivo se asigna el valor de la variable del puerto externo y modificarlo con un editor.
2. Consultar el plan e identificar qué ocurrirá con el contenedor.
3. Aplicar el cambio mediante Terraform.
4. Comprobar la nueva dirección con curl y en el navegador. El puerto anterior debe dejar de responder si ningún otro servicio lo utiliza.
5. Consultar nuevamente el plan para comprobar que no quedan cambios pendientes.

La modificación del puerto implica reemplazar el contenedor. No es necesario editar todos los archivos ni modificar la demostración del CRUD.

## Evidencia de la actividad

Entregar **dos capturas y una respuesta breve**, antes de eliminar los recursos:

1. Terminal después del reto: contenedor en ejecución con el nuevo puerto, respuesta HTTP `200 OK` de la nueva dirección y plan sin cambios pendientes.
2. Navegador: página `Welcome to nginx!` con la dirección y el nuevo puerto visibles.

Responder **¿Qué acciones manuales sustituyó Terraform y qué cambio detectó al modificar el puerto?**

## Limpieza

Después de guardar las evidencias, desde la misma carpeta `laboratorio/`:

```bash
terraform destroy
```

Revisar el plan y escribir `yes`. Se eliminan el contenedor y la imagen administrados por esta práctica.

```bash
terraform state list
docker ps
```

El estado debe quedar sin recursos y el contenedor ya no debe aparecer.
