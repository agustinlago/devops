echo "Iniciando"
cluster=$(oc project) &> /dev/null
TOKEN=${COMPLETAR CON EL TOKEN}
URL_CLUSTER=${COMPLETAR URL DEL CLUSTER}
echo "Se va a usar la SA generica"
oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null

read -p "Ingrese el nombre del Base-Project (Namespace sin el entorno): " project

if [ -z $project ]
then
    echo "Falta el parametro BASE-PROJECT"
    exit
else
    if [ -d $project ]
    then
        echo "Se va a usar el proyecto: '$project'"
    else
        echo "No proyecto no existe!"
        exit
    fi
        BASE_PROJECT=$project
fi

read -p "Ingrese el nombre de la Aplicacion (APP_NAME): " app_name

if [ -z $app_name ]
then
    echo "Falta el parametro APP_NAME"
    exit
else
    echo "Se va a usar la aplicacion: '$app_name'"
    APP_NAME=$app_name
fi

read -p "Ingrese el nombre de la Tecnologia a usar (java/nodejs): " tech

if [ -z $tech ]
then
    echo "Falta el parametro TECH"
    exit
else
    echo "Se va a usar el proyecto: '$tech'"
    TECH=$tech
fi

read -p "Ingrese el repo de codigo de la Aplicacion: " repo_codigo

if [ -z $repo_codigo ]
then
    echo "Falta el parametro GIT_REPO"
    exit
else
    echo "Se va a usar el repo: '$repo_codigo'"
    GIT_REPO=$repo_codigo
fi

read -p "Ingrese el repo de codigo de la Aplicacion: " repo_manifests

if [ -z $repo_manifests ]
then
    echo "Falta el parametro GIT_REPO"
    exit
else
    echo "Se va a usar el repo: '$repo_manifests'"
    GIT_KUSTOMIZE=$repo_manifests
fi

echo "Procesando.."

#APP_NAME=snvs-cuidarfile-sheduler
#BASE_PROJECT=snvs-ws-api
#MODULO=snvs
#TECH=java
#GIT_REPO=ssh://git@10.10.103.100/${BASE_PROJECT}/${APP_NAME}.git
#GIT_KUSTOMIZE=https://github.com/agustinlago/devops/DevOps/manifests/${BASE_PROJECT}/${APP_NAME}.git

oc process repository-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT  > ../../repositories/$BASE_PROJECT/${APP_NAME}-repo.yaml

oc process ${TECH}-ci-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} > ${BASE_PROJECT}/dev/pipelines/${APP_NAME}-${TECH}-ci-pipeline.yaml

oc process dev-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/dev/apps/${APP_NAME}-app.yaml



oc process ${TECH}-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > ${BASE_PROJECT}/qa/pipelines/${APP_NAME}-${TECH}-cd-pipeline.yaml

oc process qa-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/qa/apps/${APP_NAME}-app.yaml



oc process manifest-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > ${BASE_PROJECT}/uat/pipelines/${APP_NAME}-manifest-cd-pipeline.yaml

oc process uat-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/uat/apps/${APP_NAME}-app.yaml

echo "Se va a desloguear de OCP"
oc logout &> /dev/null

echo "Finalizado con exito!"

