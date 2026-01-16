
# Sesión 2: Automatización de CI/CD con GitHub y AWS CodePipeline

**Nota:**
Para este taller usaremos la cuenta de AWS provista por el equipo DMC, se separán usuarios por cada región de AWS para no superar los limites de cuotas de servicios de AWS
Tener en cuenta que todos usarán la misma cuenta de AWS, cada alumno debe usar su apellido como prefijo para evitar colisiones de nombres.

**Prefijo del alumno (apellido en minúsculas):**  
`APELLIDO = <tu_apellido_en_minusculas>`

**Ejemplo:**  
`APELLIDO = perez`

**Regla de aplicación:**  
Donde el documento diga un nombre fijo como `devops-dmc-ec2`, el alumno debe crear/usar `APELLIDO-devops-dmc-ec2` (ej.: `perez-devops-dmc-ec2`). 

### Configuraciones Previas:

Agregar el archivo: `buildspec.yml` al repositorio creado en la sesión 1 (en la branch `main`)

```yaml
version: 0.2

phases:
  build:
    commands:
      - echo "No se necesita compilación para archivos estáticos."

artifacts:
  files:
    - "**/*"

```

---

### 
# 🚀 Configuración de Conexión entre AWS y GitHub

Sigue estos pasos para establecer la conexión necesaria para tu pipeline de CI/CD.

> ⚠️ **Nota:** Antes de empezar, inicia sesión en GitHub

### Paso 1: Ir a Connections
1. En la consola de AWS, busca: **Developer Tools** → **Connections**.
2. Haz clic en el botón **Create connection**.

### Paso 2: Seleccionar proveedor
1. En **Select a provider**, elige **GitHub**.
2. En **Connection name**, escribe siguiendo este formato:
   `APELLIDO-connection-github`

   > `perez-connection-github`

3. Haz clic en **Connect to GitHub**.

### Paso 3: Autorizar AWS en GitHub
1. GitHub mostrará la pantalla: **AWS Connector for GitHub**.
2. Haz clic en **Authorize AWS Connector for GitHub**.

### Paso 4: Instalar el conector en GitHub
1. Selecciona tu **cuenta personal** de GitHub.
2. Elige la opción **Only select repositories**.
3. Haz clic en **Select repositories** y busca el repositorio del taller.
4. Haz clic en **Install & Authorize**.

*✔ Esto permite que AWS acceda de forma segura solo al repositorio seleccionado.*

### Paso 5: Finalizar la conexión en AWS
1. Regresarás automáticamente a la consola de AWS.
2. Verifica que:
   * El **Connection name** sea el correcto.
   * El campo **App Installation** tenga un ID generado (se llena solo).
3. Haz clic en **Connect**.

### Paso 6: Verificación final
1. Dirígete nuevamente a **Developer Tools** → **Connections**.
2. Verifica que el estado de tu nueva conexión aparezca como:  
   🟢 **Available**

---


### Despliegue de Infraestructura necesaria para este taller: (VPC - SUBNETS PUBLICAS - EC2):

**Recursos a crear:**
*   VPC con 2 subredes públicas y un endpoint S3.
*   Internet Gateway y tabla de ruteo pública.
*   Security Group `devops-dmc-sg` con reglas SSH y HTTP.
*   IAM Role
*   Instancia EC2 `devops-dmc-ec2` con UserData para instalar Apache.

**Security Group:** `APELLIDO-devops-dmc-sg`  
**Instancia EC2:** `APELLIDO-devops-dmc-ec2`

**En la consola de AWS, busca Cloudformation:**
1. En el panel derecho, selecciona **Create Stack** → **With new resources(standard)**.
2. Elegir **Choose an existing template** y **Upload a template file** y subir el archivo `stack.yml`.
3. Seleccionar check box: *I acknowledge that AWS CloudFormation might create IAM resources with custom names.*
4. El resto de configuraciones deben quedar por defecto.

**Stack name:** `APELLIDO-devops-dmc-stack` (ej.: `perez-devops-dmc-stack`)  
**(si aplica en tu template modificado) Parámetro:** `StudentPrefix = <tu_apellido_en_minusculas>`

En la consola de AWS, busca **EC2**, y selecciona la instancia ec2 que acaba de crearse con el nombre: `devops-dmc-ec2`. Busca la columna: **Public IPv4 DNS**, y accede a la url para verificar la aplicación.

`APELLIDO-devops-dmc-ec2`

---

### Objetivo
Construir un pipeline automatizado que compile, pruebe y despliegue la aplicación en la instancia EC2 creada en la Sesión 1, cada vez que haya un cambio en el repositorio de GitHub.

---

### 1. Rol IAM para CodeDeploy
1. En la consola de AWS, busca **IAM**.
2. En el panel izquierdo, selecciona **Roles** → **Create role**.
3. **Trusted entity type:** selecciona **AWS service**.
4. **Use case:** elige **CodeDeploy**.
5. Haz clic en **Next**.
6. Adjunta la política administrada: `AWSCodeDeployRole`
7. Dale un nombre al rol: `devops-dmc-codedeploy-role`
8. Haz clic en **Create role**.

**Nombre del rol:** `APELLIDO-devops-dmc-codedeploy-role`

---

### 2. Crear la Aplicación en CodeDeploy
1. En la consola, busca **CodeDeploy**.
2. Haz clic en **Applications** → **Create application**.
3. Configura:
    *   **Application name:** `devops-dmc-app`
    *   **Compute platform:** `EC2/On-premises`
4. Haz clic en **Create application**.

**Application name:** `APELLIDO-devops-dmc-app`

---

### 3. Crear el Deployment Group en CodeDeploy
1. Dentro de la aplicación `devops-dmc-app`, haz clic en **Create deployment group**.
2. Configura:
    *   **Deployment group name:** `devops-dmc-deployment-group`
    *   **Service role:** selecciona el rol `devops-dmc-codedeploy-role`.
    *   **Deployment type:** `In-place`.
    *   **Environment configuration:**
        *   Selecciona **Amazon EC2 instances**.
        *   Usa **Tags** para identificar la instancia creada en la sesión 1. Ejemplo: `Key: Name`, `Value: devops-dmc-ec2`.
    *   **Agent configuration:** deja la configuración por defecto
    *   **Load balancer**: Deshabilitar Enable load balancing
3. Haz clic en **Create deployment group**.

**Application (dentro de):** `APELLIDO-devops-dmc-app`  
**Deployment group name:** `APELLIDO-devops-dmc-deployment-group`  
**Service role:** `APELLIDO-devops-dmc-codedeploy-role`  
**Tag Value (EC2):** `APELLIDO-devops-dmc-ec2`

---

### 4. Crear el Pipeline en CodePipeline
1. En la consola, busca **CodePipeline**.
2. Haz clic en **Create pipeline**.
3. Configura:
    *   **Build custom pipeline**
    *   **Pipeline name:** `devops-dmc-pipeline`
    *   **Service role:** selecciona **New service role** (se creará automáticamente).
    *   El resto de configuraciones deben quedar por defecto.
    *   Verificar **Advance Settings**: Configuración de Artifacts para Pipeline.
4. Haz clic en **Next**.

**Pipeline name:** `APELLIDO-devops-dmc-pipeline`

---

### 5. Fase de Origen (Source)
1. **Source provider:** selecciona **GitHub (via GitHub App)**.
2. Conecta tu cuenta de GitHub
3. Selecciona:
    *   **Repository:** tu repo creado en la sesión 1.
    *   **Branch:** `main`.
    *   El resto de configuraciones deben quedar por defecto.
4. Haz clic en **Next**.

---

### 6. Fase de Compilación (Build)
1. **Build provider:** selecciona **Other build providers AWS CodeBuild**.
2. Haz clic en **Create project**.
3. Configura:
    *   **Project name:** `devops-dmc-build`.
    *   **Environment:**
        *   Managed image
        *   Operating system: Amazon Linux
        *   Runtime(s): Standard
        *   Image: `aws/codebuild/amazonlinux-x86_64-standard:5.0`
    *   **Service role:** crear nuevo.
    *   **Buildspec:** selecciona **Use a buildspec file**.
    *   El resto de configuraciones deben quedar por defecto.
4. Haz clic en **Continue to CodePipeline**. (Si el navegador te pide la opción de Salir, escogerla para cerrar la ventana y volver a Codepipeline).
5. Haz clic en **Next**.

**Project name:** `APELLIDO-devops-dmc-build`  
**Test - optional:** Elegir **Skip test stage**

---

### 7. Fase de Despliegue (Deploy)
1. **Deploy provider:** selecciona **AWS CodeDeploy**.
2. Configura:
    *   **Application name:** `devops-dmc-app`
    *   **Deployment group:** `devops-dmc-deployment-group`
3. Haz clic en **Next**.

**Application name:** `APELLIDO-devops-dmc-app`  
**Deployment group:** `APELLIDO-devops-dmc-deployment-group`

---

### 8. Revisión y Creación del Pipeline
1. Revisa todas las fases: **Source** → **Build** → **Deploy**.
2. Haz clic en **Create pipeline**.
3. El pipeline se ejecutará automáticamente por primera vez.

---

### 9. Verificación del Despliegue
1. Espera a que las fases se completen con éxito.
2. Copia la IP pública de tu instancia EC2.
3. Abre en el navegador: `http://<EC2_PUBLIC_IP>`
4. Deberías ver tu página con el mensaje: “¡Bienvenido a nuestra aplicación desplegada con AWS DevOps!”

---

### Prueba del Flujo Completo
Edita el archivo `index.html` en tu repo local:
`<h1>¡Bienvenido a nuestra aplicación desplegada con AWS DevOps - Sesión 2!</h1>`
Haz commit y push a la rama `main`. Observa cómo CodePipeline detecta el cambio, ejecuta el pipeline y despliega la nueva versión. Refresca la página en el navegador y verifica que ahora aparece “Versión 1.0.1”.

**Con esto tienes un pipeline CI/CD completo:**
*   **Source:** GitHub
*   **Build:** CodeBuild
*   **Deploy:** CodeDeploy
*   **Infraestructura:** EC2 con agente CodeDeploy y SSM

---

### Resolución de Errores

**Error:** `The deployment failed because a specified file already exists at this location: /var/www/html/index.html`

**¿Por qué se produce?**  
Ese error significa que CodeDeploy intenta copiar `index.html` a `/var/www/html/`, pero el archivo ya existe (porque lo creaste en el UserData de la instancia al lanzarla). Cuando CodeDeploy encuentra un archivo en el destino que no puede sobrescribir, falla con `UnknownError`.

**Solución:** Crear un Change Set con el `stack-2.yml` (que ya no tiene la creación del archivo `index.html`, si no que se creará únicamente con el pipeline).
1. Abrir **CloudFormation** -> **Stacks**, seleccionar el stack creado al inicio de la sesión.
2. Seleccionar **Delete**. Esta configuración eliminará la infraestructura actual. Esperar a que la infraestructura se elimine.
3. Después en el panel derecho, selecciona **Create Stack** → **With new resources(standard)**.
4. Elegir **Choose an existing template** y **Upload a template file** y subir el archivo `stack-2.yml`.
5. Seleccionar check box: *I acknowledge that AWS CloudFormation might create IAM resources with custom names.*
6. En la consola de AWS, busca **EC2**, y selecciona la instancia ec2 que acaba de crearse con el nombre: `devops-dmc-ec2`. Busca la columna: **Public IPv4 DNS**, y accede a la url para verificar la aplicación.

**El stack a borrar/crear debe ser:** `APELLIDO-devops-dmc-stack`  
**La EC2 a verificar debe ser:** `APELLIDO-devops-dmc-ec2`

---

### Siguientes Pasos para el alumno:
*   Agregar un Step para la ejecución de Pruebas Unitarias (Usando Codebuild)
*   Configura un envío de Notificaciones para tu Pipeline:

**Crear un tópico SNS:**
1. Ve a **SNS** → **Topics** → **Create topic**.
2. Tipo: **Standard**.
3. Nombre: `devops-dmc-pipeline-topic`.
4. Crea el tópico.

**Nombre:** `APELLIDO-devops-dmc-pipeline-topic`

**Suscribirte con tu correo:**
1. Dentro del tópico, haz clic en **Create subscription**.
2. Protocol: **Email**.
3. Endpoint: tu dirección de correo.
4. Confirma el correo (te llegará un mail de AWS).

**Crear una regla de EventBridge:**
1. Ve a **EventBridge** → **Rules** → **Create rule**.
2. Nombre: `devops-dmc-pipeline-rule`.
3. Evento: selecciona **CodePipeline** → **Pipeline Execution State Change**.
4. Filtra por tu pipeline: `devops-dmc-pipeline`.
5. Target: selecciona **SNS topic** → `devops-dmc-pipeline-topic`.
6. Ahora cada vez que el pipeline cambie de estado (Succeeded, Failed, etc.), recibirás un correo.

**Nombre regla:** `APELLIDO-devops-dmc-pipeline-rule`  
**Filtrar pipeline:** `APELLIDO-devops-dmc-pipeline`  
**Target SNS topic:** `APELLIDO-devops-dmc-pipeline-topic`

---

### ⚠ ¡Importante! Limpieza de Recursos
Este taller utiliza AWS CloudFormation para crear automáticamente algunos recursos.  
Para evitar costos inesperados, es crucial que al finalizar el taller elimines el stack de CloudFormation. Esto asegurará que todos los recursos creados sean eliminados correctamente.

**Pasos para la eliminación:**
1. En la consola de AWS, busca **Cloudformation** -> **Stacks**, seleccionar el stack.
2. Seleccionar **Delete**. Esperar que AWS termine la eliminación de recursos de forma exitosa.

---
