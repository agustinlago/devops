# Creacion de proyectos

## 1 - Repositorios
### Estructura de los repositorios:
Los nombres de **grupos**/**repositorios**/**aplicaciones** deben estar todos en **minusculas**, separados por **guiones medios**
- **Estructura Gitlab source:**

1. ssh://git@10.10.103.100/[BASE_PROJECT]/[APP_NAME].git

#### Compuesto de dos branchs, master y develop

Branch: **develop** -> **pipeline ci**, construye la imagen para el proyecto **dev** en ocp

Branch: **master** -> **pipeline cd**, construye la imagen para los proyectos **qa**, **uat** y **prod** en ocp

- **Estructura manifest:**

1. ssh://git@10.10.103.100/DevOps/manifests/[BASE_PROJECT]/[APP_NAME].git

## 2 Crear los manifiestos

- -  oc get secrets -o yaml -n argocd | oc neat > secrets.yaml

## 3 Modificar y Agregar el proyecto y la aplicacion en el repo de DevOps/gitops (ArgoCD)

1. Agregar el repositorio gitlab del proyecto con los manifest en la carpeta repositories

    /DevOps/gitops/repositories

2. Agregar proyecto y aplicaciones en: 

    /DevOps/gitops/[cluster]/proyectos

    (si no existe agregar la carpeta contenedora "[BASE_PROJECT]")

..... completar .....

## 4 Import template ci
```bash
APP_NAME=nomivac-tableros-backend 
GIT_REPO=ssh://git@10.10.103.100/central-reportes/nomivac-tableros-backend.git
BASE_PROJECT=central-reportes

oc process java-ci-pipeline-template -n openshift -o yaml --param APP_NAME=${APP_NAME} --param NAMESPACE=dev-${BASE_PROJECT} --param GIT_REPO=${GIT_REPO} | oc apply -f - -n ${NAMESPACE}
```



```bash
APP_NAME=snvs-cuidarfile-sheduler 
GIT_REPO=ssh://git@10.10.103.100/snvs/snvs-ws-api/nomivac-tableros-backend.git
GIT_KUSTOMIZE=ssh://git@10.10.103.100/DevOps/manifests/central-reportes/nomivac-tableros-backend.git
BASE_PROJECT=central-reportes
TECH=java

oc process ${TECH}-ci-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param NAMESPACE=dev-${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} > dev/pipelines/${APP_NAME}-${TECH}-ci-pipeline.yaml

oc process ${TECH}-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param NAMESPACE=qa-${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > qa/pipelines/${APP_NAME}-${TECH}-cd-pipeline.yaml

oc process manifest-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > uat/pipelines/${APP_NAME}-manifest-cd-pipeline.yaml


```

oc get secrets -o yaml -n dev-snvs-ws-api | oc neat > secrets.yaml

## Sealed Secret

kubeseal --scope cluster-wide \
         --controller-namespace sealed-secrets \
         --controller-name sealedsecretcontroller-sealed-secrets  \
  <secret-uat-sisaown-database-credentials.yaml \
  >sealed-secret-uat-sisaown-database-credentials.yaml


kubeseal --scope cluster-wide \
         --controller-namespace sealed-secrets \
         --controller-name sealedsecretcontroller-sealed-secrets  \
  <secret-detectar-back-database.yaml \
  >sealed-secret-detectar-back-database.yaml

kubeseal --scope cluster-wide \
         --controller-namespace sealed-secrets \
         --controller-name sealedsecretcontroller-sealed-secrets  \
  <secret-detectar-back-headers.yaml \
  >sealed-secret-detectar-back-headers.yaml

kubeseal --scope cluster-wide \
         --controller-namespace sealed-secrets \
         --controller-name sealedsecretcontroller-sealed-secrets  \
  <secret-database.yaml \
  >sealed-secret-database.yaml