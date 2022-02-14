echo "Iniciando"
cluster=$(oc project) &> /dev/null
TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IkJoRkdkeHF6UFNoXzY2Nm40UmtvZV9WN1NGcVN5cU9pa2ZyQW5tVWx0ODQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJvcGVuc2hpZnQiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoidmlldy10ZW1wbGF0ZXMtdG9rZW4tcWNkbmciLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoidmlldy10ZW1wbGF0ZXMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJmNWI0OGMzZi01NmFlLTRlMTAtYTVkNi0xY2Y5MGYyNGQ2MDYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6b3BlbnNoaWZ0OnZpZXctdGVtcGxhdGVzIn0.t6J0Un8TrKSOX1z93Pt7a7u6MxFiU9GZXueLo2j2TpthJ9Rf3hH8evDd3_XaLEwxvhBlyw624nR4_EIKUpRf0p9Y-c1CUz89VHsbx5zwD5wzPdWdx9R6tHvpiVIm5CGwBGZF5yOOM7CeXM7BTH79WV4J6mCA2-pVnBQE5YU9piG_pocsJXrnXtFN91emBrmL6p1qTiFZRO0gFju0CmNw2OUdPTWnuVMWurQczJbADaoRl6PpE9it5GQaHME5HzMlfIG61A7DDy602mC4rYXBlt4IhA4a0qmhjzEXDHA3rffz-a7NejFaVYuwRnJjzg44_WM2SA4tXbfpwJTQeHLm4ZN9qWREOstHHiwu6fRu6w5n2hvDfomC_3S1DmB_CTrSvoY2OZuPuB3lEG4RvsWAjt360yhcB2-0wzri8dgU3iBU71KFezbw-h6orYVt0oEBLQNH8d11wq47xLOg4CYRFdUEioefGPs5AcfrljrQY44xRfIteQpikoOdAlbIUkCdJQIqWie5lvbcsYnqXUjNeEVv94VUqEFIkygw_iAj7MD1-iY2lMPiqbC-EjtZQDd0BAhaamWMeRXzDg0zFzemN9Bv3ChraleuhcZXEeK_HrCEk8puGHl0cbHXzd9sCnfMakNZNAxgAmR75igL4EUWlpOzhZUF0jD2dqqRNLLZSKU
URL_CLUSTER=https://api.cluster-493e.493e.sandbox512.opentlc.com:6443
echo "Se va a usar la SA generica"
oc login --server=$URL_CLUSTER --token=$TOKEN 

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

read -p "Ingrese el repo de manifiestos de la Aplicacion: " repo_manifests

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
    --param BASE_PROJECT=$BASE_PROJECT \
    --param REPO=$GIT_KUSTOMIZE > ../../repositories/$BASE_PROJECT/${APP_NAME}-repo.yaml

oc process ${TECH}-ci-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} > ${BASE_PROJECT}/dev/pipelines/${APP_NAME}-${TECH}-ci-pipeline.yaml

oc process dev-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > $BASE_PROJECT/dev/apps/${APP_NAME}-app.yaml



oc process ${TECH}-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > ${BASE_PROJECT}/qa/pipelines/${APP_NAME}-${TECH}-cd-pipeline.yaml

oc process qa-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > $BASE_PROJECT/qa/apps/${APP_NAME}-app.yaml



oc process manifest-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > ${BASE_PROJECT}/uat/pipelines/${APP_NAME}-manifest-cd-pipeline.yaml

oc process uat-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > $BASE_PROJECT/uat/apps/${APP_NAME}-app.yaml

echo "Se va a desloguear de OCP"
oc logout &> /dev/null

echo "Finalizado con exito!"

