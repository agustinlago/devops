echo "Iniciando"
cluster=$(oc project) &> /dev/null
TOKEN=${COMPLETAR CON EL TOKEN}
URL_CLUSTER=${COMPLETAR URL DEL CLUSTER}
case $cluster in
            *"$URL_CLUSTER"* )
                echo "Se encuentra logueado a PROD, se va a usar el usuario: $(oc whoami)"
                LOG=1
            ;;
            *"$URL_CLUSTER"* )
                echo "Se encuentra logueado a DEVQA, se va a usar la SA Generica.."
                oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null
                LOG=0
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

echo "Procesando.."

#APP_NAME=snvs-cuidarfile-sheduler
#BASE_PROJECT=snvs-ws-api
#MODULO=snvs
GIT_KUSTOMIZE=ssh://git@10.10.103.100/DevOps/manifests${MODULO}${BASE_PROJECT}/${APP_NAME}.git

oc process manifest-cd-pipeline-template -n openshift -o yaml \
    --param APP_NAME=${APP_NAME} \
    --param BASE_PROJECT=${BASE_PROJECT} \
    --param GIT_KUSTOMIZE=${GIT_KUSTOMIZE} > .$MODULO${BASE_PROJECT}/prod/pipelines/${APP_NAME}-manifest-cd-pipeline.yaml

oc process prod-app-template -n openshift -o yaml --param APP_NAME=$APP_NAME --param BASE_PROJECT=$BASE_PROJECT --param MODULO=$MODULO > .$MODULO$BASE_PROJECT/prod/apps/prod-${APP_NAME}-app.yaml

if [ $LOG -eq 0 ]
then
    echo "Se va a desloguear de OCP"
    oc logout &> /dev/null
fi

echo "Finalizado con exito!"

