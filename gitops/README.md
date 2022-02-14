# OpenShift GitOps (argoCD)

## Instalacion OpenShift GitOps

La forma mas facil de instalar OpenShift GitOps es a travez del operator desde la consola web.

1. En la consola web desde la vista de administrador navegas a Operators -> OperatorHub.
2. Buscas "OpenShift GitOps" y clic.
3. Aparece la informacion del operator y clic en boton de Install.
4. En el wizard de instalacion dejamos la estrategia de aprobacion en Manual y el canal en Stable (actualmente la version del operator instalada es: 1.3.2).
5. Clic en Instalar y aparecera el Operador en la lista de Operadores instalados.
6. Verificar que se completo correctamente la instalacion en Operators -> Installed Operators.
7. Este operator nos dejara en el proyecto openshift-gitops ArgoCD corriendo.
8. Para ingresar a interfaz web de ArgoCD, busca el recurso route openshift-gitops-server, y ahi la url. Tambien se puede conseguir con el siguiente comando: 
```bash
oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
 ```
9. Para logearse a ArgoCD  user: admin y password se puede hallar en el secret openshift-gitops-cluster. Tambien se puede extraer con el siguiente comando:
```bash
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```
Mas info: https://docs.openshift.com/container-platform/4.7/cicd/gitops/installing-openshift-gitops.html
SSO: https://docs.openshift.com/container-platform/4.7/cicd/gitops/configuring-sso-for-argo-cd-on-openshift.html

## Conectarse a un repositorio

Primero antes de crear una "Application", se debe crear el repositorio donde estara todos los manifiestos a sincronizar. 

En argoCD un repositorio es un objecto que guarda la URL, creedenciales y certificados. Tambien argoCD nos provee la creacion de un repositorio "template" que funciona como base si usamos las mismas creedenciales para diversos repositorios.

Entonces el escenario seria: 

Un repositorio simplemente guardara la url:
ej:
```
url: ssh://git@10.10.103.100/devops/gitops.git
```

Y un template se guarda la base del repositorio y sus creedenciales
ej:
```
url:    ssh://git@10.10.103.100
sshPrivateKey:   *******
```

Tambien hay que tener en cuenta el tema de certificados del servidor al que estemos apuntado, mas adelante se explica con mayor detalle. 

Ahora para crear un el repositorio y el template hay varias alternativas, pero la forma declarativa, que seria lo ideal, en este momento no funciona, por el momento la unica forma de hacerlo es por UI o editando el configmap de argocd-cm (teniendo en encuenta que aqui esta la configuracion de argoCD).


Los siguientes apartados son las formas de crear el repositorio y template es para HTTP, tambien se puede hacer de forma similiar con SSH.

### UI 

Template: 
1. Navegar por Settings/Repositories -> Connect Repo using HTTPS 
2. Llenamos los campos con la url base y las credenciales 
3. De ser necesario se puede marcar la casilla de "Skip server verification"
4. Y clic en "Save as credentials template"
5. Deberia aparecer en la lista de "CREDENTIALS TEMPLATE URL"

Repositorio:
1. Navegar por Settings/Repositories -> Connect Repo using HTTPS 
2. Llenamos los campos con la url completa solamente.
3. Aca tambien se puede marcar la casilla de "Skip server verification"
4. Y clic en "Connect"
5. Deberia aparecer en la lista de repos con un tilde verde y la leyenda "Successful"

### CLI

Primero creamos el "template" con las credenciales 

```bash
argocd repo-creds add ssh://git@10.10.103.100 --sshPrivateKey *******
```

Y luego el agregamos el repo en si.
```bash 
argocd repo add ssh://git@10.10.103.100/devops/gitops.git
```
nota: para saltearse la verificacion del servidor usar el flag: `--insecure-skip-server-verification`

### Declarativo

Creando un en Openshift en el projecto de openshift-gitops dos secrets; uno para el repositorio y otro para el "template" con unos labels en especifico argoCD deberia reconocerlo.

Agregar las credenciales del repo base:
```bash
oc apply -f repositories/gitlab-ssh-repo-creds.yaml -n openshift-gitops
```

Agregar los repos solo con la url:
```bash
oc apply -f repositories/apps-repository.yaml -n openshift-gitops
```

mas info: https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#repositories


## Projecto de argoCD

Un proyecto de ArgoCD es una division logica para las aplicaciones, donde podremos crear diversas configuraciones de seguridad, para este conjunto de aplicaciones que vivira en el proyecto, como restricciones y permisos sobre lo que pueda o no crear la aplicacion (como limites o coutas).

No confundir el "project" de ArgoCD con "project"(o "namespaces") de Openshift. 

Para crear el projecto simplemente basta con crear un recurso en openshift del tipo AppProject y automaticamente argoCD reconocera este recurso nuevo y creara el proyecto con toda la especificacion que tenga de forma declarativa en el manifiesto. 

```bash
oc apply -f gitops/app-project.yaml -n openshift-gitops
```

Mas info: https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#projects

## Aplicacion ArgoCD

De manera simple una aplicacion para argoCD no es mas que un conjunto de manifiestos dados por Helm o Kustomize que sincronizara de manera automatica o manual. 

Estos manifiestos se encuentran obviamente en algun git (este caso tfs) que previamente hemos creado. 

Para crear una aplicacion primero debemos crear el repositorio y un projecto de argoCD (explicados mas adelante).

Para crear una aplicacion simplemente basta con crear un recurso en openshift del tipo Application y automaticamente ArgoCD reconocera este recurso nuevo y creara la aplicacion con toda la especificacion que tenga de forma declarativa en el manifiesto. 

```bash
oc apply -f ocp-bajos/applications.yaml-n openshift-gitops
```

Mas info: https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#applications

## Sync de una app usando API

1. Obtenemos un token 

```bash
export ARGOCD_SERVER=https://openshift-gitops-server-openshift-gitops.apps.ocp4.minsal.devqa
curl -ks $ARGOCD_SERVER/api/v1/session -d $'{"username":"admin","password":"6ZRgjFy4sw8fpvrGJANhTY3x9qbIPeaM"}'
```

2. Ejecutar el sync con ese token

```bash
export ARGOCD_TOKEN=

curl -ks -XPOST $ARGOCD_SERVER/api/v1/applications/dev-snvs-api68/sync -H "Authorization: Bearer $ARGOCD_TOKEN" 
```
agregar en el configMap de argo-cm, para evitar el Progressing de los SealedSecret
```yaml
spec:
    resource.customizations.health.bitnami.com_SealedSecret: |
    hs = {}
    hs.status = "Healthy"
    hs.message = "Controller doesn't report resource status"
    return hs
```