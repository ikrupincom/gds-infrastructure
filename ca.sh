CONTAINER_NAME_PREFIX=${GDS_CA_ARG_CONTAINER_PREFIX:=office}
CA_CONTAINER_NAME=${CONTAINER_NAME_PREFIX}-ca

if [[ $1 == "init" ]]; then

    docker run -it --rm \
        -v ${CA_CONTAINER_NAME}:/root/easy-rsa/ \
        -v $2:/input/vars \
        ikrupincom/gds-easyrsa init

fi