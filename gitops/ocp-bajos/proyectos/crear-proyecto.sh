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
        echo "Ya existe el modulo: '$modulo'"
        read -p "¿Desea sobreescribirlo? (Y/N):  " yn
        case $yn in
            y|Y )
            ;;
            * )
                echo "Abortado.."
                break
            ;;
        esac
    else
        mkdir $modulo &> /dev/null
        echo "Se creo el modulo: '$modulo'"
    fi

    mkdir ../../repositories/$modulo &> /dev/null

    oc process modulo-project-template -n openshift -o yaml --param MODULO=$modulo > $modulo-project.yaml
    
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
        echo "Ya existe el proyecto: '$project'"
        read -p "¿Desea sobreescribirlo? (Y/N):  " yn
        case $yn in
            y|Y ) 
            ;;
            * )
                echo "Abortado.."
                exit
            ;;
        esac
    else
        mkdir .$MODULO$project
        echo "Se creo el proyecto: '$project'"
    fi
        mkdir .$MODULO$project/dev &> /dev/null
        mkdir .$MODULO$project/dev/apps &> /dev/null
        mkdir .$MODULO$project/dev/commons &> /dev/null
        mkdir .$MODULO$project/dev/pipelines &> /dev/null
        mkdir .$MODULO$project/dev/project &> /dev/null
        mkdir .$MODULO$project/qa &> /dev/null
        mkdir .$MODULO$project/qa/apps &> /dev/null
        mkdir .$MODULO$project/qa/commons &> /dev/null
        mkdir .$MODULO$project/qa/pipelines &> /dev/null
        mkdir .$MODULO$project/qa/project &> /dev/null
        mkdir .$MODULO$project/uat &> /dev/null
        mkdir .$MODULO$project/uat/apps &> /dev/null
        mkdir .$MODULO$project/uat/commons &> /dev/null
        mkdir .$MODULO$project/uat/pipelines &> /dev/null
        mkdir .$MODULO$project/uat/project &> /dev/null
        mkdir ../../repositories$MODULO$project &> /dev/null
        BASE_PROJECT=$project
fi

echo "Procesando.."

oc process base-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT --param MODULO=$MODULO > .$MODULO$BASE_PROJECT-project.yaml

oc process dev-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > .$MODULO$BASE_PROJECT/dev/project/dev-project.yaml
oc process qa-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > .$MODULO$BASE_PROJECT/qa/project/qa-project.yaml
oc process uat-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > .$MODULO$BASE_PROJECT/uat/project/uat-project.yaml

echo "Agregando permisos de admin sobre Dev al grupo msal-desarrollo"

oc process rolebinding-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > ../permisos/msal-desarrollo/dev-$BASE_PROJECT.yaml

if [ $LOG -eq 0 ]
then
    echo "Se va a desloguear de OCP"
    oc logout &> /dev/null
fi

echo "Finalizado con exito!"