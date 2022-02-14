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