echo "Iniciando"
cluster=$(oc project) &> /dev/null
TOKEN=${COMPLETAR CON EL TOKEN}
URL_CLUSTER=${COMPLETAR URL DEL CLUSTER}
echo "Se va a usar la SA generica"
oc login --server=$URL_CLUSTER --token=$TOKEN &> /dev/null

read -p "Ingrese el nombre del Modulo o dejelo vacio sino se usa: " modulo


read -p "Ingrese el nombre del Base-Project (Namespace sin el entorno): " project

if [ -z $project ]
then
    echo "Falta el parametro BASE-PROJECT"
    exit
else
    if [ -d $project ]
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
        mkdir $project
        echo "Se creo el proyecto: '$project'"
    fi
        mkdir $project/dev &> /dev/null
        mkdir $project/dev/apps &> /dev/null
        mkdir $project/dev/commons &> /dev/null
        mkdir $project/dev/pipelines &> /dev/null
        mkdir $project/dev/project &> /dev/null
        mkdir $project/qa &> /dev/null
        mkdir $project/qa/apps &> /dev/null
        mkdir $project/qa/commons &> /dev/null
        mkdir $project/qa/pipelines &> /dev/null
        mkdir $project/qa/project &> /dev/null
        mkdir $project/uat &> /dev/null
        mkdir $project/uat/apps &> /dev/null
        mkdir $project/uat/commons &> /dev/null
        mkdir $project/uat/pipelines &> /dev/null
        mkdir $project/uat/project &> /dev/null
        mkdir ../../repositories/$project &> /dev/null
        BASE_PROJECT=$project
fi

echo "Procesando.."

oc process base-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT  > $BASE_PROJECT-project.yaml

oc process dev-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/dev/project/dev-project.yaml
oc process qa-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/qa/project/qa-project.yaml
oc process uat-project-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > $BASE_PROJECT/uat/project/uat-project.yaml

#echo "Agregando permisos de admin sobre Dev al grupo msal-desarrollo"
#oc process rolebinding-template -n openshift -o yaml --param BASE_PROJECT=$BASE_PROJECT > ../permisos/msal-desarrollo/dev-$BASE_PROJECT.yaml


echo "Se va a desloguear de OCP"
oc logout &> /dev/null

echo "Finalizado con exito!"