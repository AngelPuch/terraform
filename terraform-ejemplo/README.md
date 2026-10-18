# CRUD de tareas con Terraform

## Requisitos

- Windows con Vagrant y VirtualBox instalados.
- Virtualización habilitada.
- 2 GB de RAM disponibles para la máquina virtual y espacio libre para Ubuntu y las imágenes Docker.
- Conexión a internet durante el aprovisionamiento y el primer despliegue.
- Puertos 8080 y 8081 disponibles en Windows.
- Dirección IP `192.168.33.30` disponible para la máquina virtual.
- Navegador web o Postman.

El aprovisionamiento instala Docker y Terraform en Ubuntu. Terraform requiere una versión `>= 1.5, < 2.0`.

## Ejecución

### 1. Iniciar la máquina virtual

Desde PowerShell, en la carpeta que contiene el `Vagrantfile`:

```powershell
cd C:\dev\terraform-crud-tareas
vagrant up
vagrant ssh
```

### 2. Preparar el despliegue

Dentro de la máquina virtual:

```bash
cd /vagrant/terraform-ejemplo/infra
docker info
terraform version
terraform init
terraform fmt
terraform validate
terraform plan -out=crear.tfplan
```

### 3. Crear la infraestructura

```bash
terraform apply crear.tfplan
terraform output
docker ps
curl http://127.0.0.1:8080/health
```

Respuesta esperada:

```json
{ "status": "ok" }
```

### 4. Acceder desde Windows

- Aplicación: <http://192.168.33.30:8080>.
- API de tareas: <http://192.168.33.30:8080/api/tasks>.

### 5. Verificar el estado

Desde `/vagrant/infra`:

```bash
terraform plan
```

Sin modificaciones pendientes, el resultado esperado es `No changes. Your infrastructure matches the configuration.`

## Cambiar el puerto

Modificar `external_port` en `infra/terraform.tfvars`, conservando los demás valores:

```hcl
external_port = 8081
```

Dentro de la máquina virtual, desde `/vagrant/infra`:

```bash
terraform plan -out=cambiar-puerto.tfplan
terraform apply cambiar-puerto.tfplan
docker ps --filter name=tareas-terraform-app
curl http://127.0.0.1:8081/health
```

Acceder desde Windows mediante <http://192.168.33.30:8081> o <http://localhost:8081>. Los datos se conservan en el volumen Docker durante el reemplazo del contenedor.

## Cambiar el título

Modificar `app_title` en `infra/terraform.tfvars`, conservando los demás valores:

```hcl
app_title = "Pendientes del grupo"
```

Desde `/vagrant/infra`:

```bash
terraform plan -out=cambiar-titulo.tfplan
terraform apply cambiar-titulo.tfplan
```

Recargar la aplicación para visualizar el cambio.

## Detener y reiniciar la máquina virtual

Salir de la sesión SSH:

```bash
exit
```

Desde PowerShell, en la carpeta del proyecto:

```powershell
vagrant halt
```

Para iniciar nuevamente:

```powershell
vagrant up
vagrant ssh
```

## Eliminar la infraestructura

Este procedimiento elimina el contenedor, la red y el volumen, incluidos los datos de las tareas.

Dentro de la máquina virtual, desde `/vagrant/infra`:

```bash
terraform plan -destroy -out=limpiar.tfplan
terraform apply limpiar.tfplan
```

La imagen permanece en Docker por la configuración `keep_locally = true`. Para eliminarla:

```bash
docker image rm tareas-terraform:demo
```
