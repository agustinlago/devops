echo "Iniciando"
cluster=$(oc project) &> /dev/null
TOKEN=${COMPLETAR CON EL TOKEN}
URL_CLUSTER=${COMPLETAR URL DEL CLUSTER}
case $cluster in
            *"$URL_CLUSTER_PROD"* )
                echo "Se encuentra logueado a PROD, se va a usar la SA Generica.."
                oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null
                LOG=0
            ;;
            *"$URL_CLUSTER"* )
                echo "Se encuentra logueado a DEVQA, se va a usar el usuario: $(oc whoami)"
                LOG=1
            ;;
            *"No project has been set. Pass a project name to make that the default."* )
                echo "No se puede determinar, se va a usar la SA Generica"
                oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null
                LOG=0
            ;;
            * )
                echo "No estas logueado en OCP, se va a usar la SA generica"
                oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null
                LOG=0
            ;;
esac

read -p "Ingrese el nombre del Modulo o dejelo vacio sino se usa: " modulo

if [ -z $modulo ]
then
    MODULO='/'
    echo "Se va a crear un proyecto sin modulo"
else
    if [ -d $modulo ]
    then
        echo "Se va a usar el modulo: '$modulo'"
    else
        echo "El modulo no existe!"
        exit
    fi
    


    MODULO='/'$modulo'/'
fi

read -p "Ingrese el nombre del Base-Project (Namespace sin el entorno): " project

if [ -z $project ]
then
    echo "Falta el parametro BASE-PROJECT"
    exit
else
    if [ -d .$MODULO$project ]
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

echo "Procesando.."

#APP_NAME=snvs-cuidarfile-sheduler
#BASE_PROJECT=snvs-ws-api
#MODULO=snvs
#TECH=java
GIT_REPO=ssh://git@10.10.103.100${MODULO}${BASE_PROJECT}/${APP_NAME}.git
GIT_KUSTOMIZE=ssh://git@10.10.103.100/DevOps/manifests${MODULO}${BASE_PROJECT}/${APP_NAME}.git

oc process repository-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param MODULO=$MODULO > ../../repositories$MODULO$BASE_PROJECT/${APP_NAME}-repo.yaml

oc process ${TECH}-ci-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} > .$MODULO${BASE_PROJECT}/dev/pipelines/${APP_NAME}-${TECH}-ci-pipeline.yaml

oc process dev-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param MODULO=$MODULO  > .$MODULO$BASE_PROJECT/dev/apps/${APP_NAME}-app.yaml



oc process ${TECH}-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_REPO=${GIT_REPO} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > .$MODULO${BASE_PROJECT}/qa/pipelines/${APP_NAME}-${TECH}-cd-pipeline.yaml

oc process qa-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param MODULO=$MODULO > .$MODULO$BASE_PROJECT/qa/apps/${APP_NAME}-app.yaml



oc process manifest-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > .$MODULO${BASE_PROJECT}/uat/pipelines/${APP_NAME}-manifest-cd-pipeline.yaml

oc process uat-app-template -n openshift -o yaml \
    --param APP_NAME=$APP_NAME \
    --param BASE_PROJECT=$BASE_PROJECT \
    --param MODULO=$MODULO > .$MODULO$BASE_PROJECT/uat/apps/${APP_NAME}-app.yaml



if [ $LOG -eq 0 ]
then
    echo "Se va a desloguear de OCP"
    oc logout &> /dev/null
fi

echo "Finalizado con exito!"

