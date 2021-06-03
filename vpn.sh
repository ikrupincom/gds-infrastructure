CONTAINER_NAME_PREFIX=${GDS_VPN_ARG_CONTAINER_PREFIX:=office}
VPN_CONTAINER_NAME=${CONTAINER_NAME_PREFIX}-vpn
CA_CONTAINER_NAME=${CONTAINER_NAME_PREFIX}-ca
OFFICE_VPN_DIR=${GDS_VPN_ARG_CONFIGS_PATH:=~/credentials/vpn}
OUTPUT_DIR=${OFFICE_VPN_DIR}/output
OUTPUT_CLIENTS_DIR=${OFFICE_VPN_DIR}/output-clients

mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_CLIENTS_DIR}

if [[ $1 == "gen-keys" ]]; then

  docker run -it --rm \
    -v ${VPN_CONTAINER_NAME}-easyrsa:/root/easy-rsa/ \
    -v ${OFFICE_VPN_DIR}/input/vars:/input/vars \
    -v ${OUTPUT_DIR}:/output \
    ikrupincom/gds-openvpn gen-keys

  docker run -it --rm \
    -v ${CA_CONTAINER_NAME}:/root/easy-rsa/ \
    -v ${OUTPUT_DIR}/server.req:/input/server.req \
    -v ${OUTPUT_DIR}:/output \
    ikrupincom/gds-easyrsa sign server server

fi

if [[ $1 == "init" ]]; then

  docker run -it --rm \
    -v ${CA_CONTAINER_NAME}:/root/easy-rsa/ \
    -v ${OUTPUT_DIR}:/output \
    ikrupincom/gds-easyrsa get-ca

  docker run -it --rm \
    -v ${VPN_CONTAINER_NAME}-easyrsa:/root/easy-rsa/ \
    -v ${VPN_CONTAINER_NAME}-conf:/etc/openvpn/ \
    -v ${VPN_CONTAINER_NAME}-clients:/root/client-configs/ \
    -v ${OFFICE_VPN_DIR}/input/base-client.conf:/input/base-client.conf \
    -v ${OFFICE_VPN_DIR}/input/server.conf:/input/server.conf \
    -v ${OUTPUT_DIR}/server.key:/input/server.key \
    -v ${OUTPUT_DIR}/server.crt:/input/server.crt \
    -v ${OUTPUT_DIR}/ta.key:/input/ta.key \
    -v ${OUTPUT_DIR}/ca.crt:/input/ca.crt \
    -v ${OUTPUT_DIR}/crl.pem:/input/crl.pem \
    ikrupincom/gds-openvpn init

fi

if [[ $1 == "create-client" ]]; then

  docker run -it --rm \
    -v ${VPN_CONTAINER_NAME}-easyrsa:/root/easy-rsa/ \
    -v ${VPN_CONTAINER_NAME}-conf:/etc/openvpn/ \
    -v ${VPN_CONTAINER_NAME}-clients:/root/client-configs/ \
    -v ${OUTPUT_CLIENTS_DIR}:/output \
    ikrupincom/gds-openvpn client $2

  docker run -it --rm \
    -v ${CA_CONTAINER_NAME}:/root/easy-rsa/ \
    -v ${OUTPUT_CLIENTS_DIR}/$2.req:/input/$2.req \
    -v ${OUTPUT_CLIENTS_DIR}:/output \
    ikrupincom/gds-easyrsa sign $2 client

  docker run -it --rm \
    -v ${VPN_CONTAINER_NAME}-easyrsa:/root/easy-rsa/ \
    -v ${VPN_CONTAINER_NAME}-conf:/etc/openvpn/ \
    -v ${VPN_CONTAINER_NAME}-clients:/root/client-configs/ \
    -v ${OUTPUT_CLIENTS_DIR}/$2.crt:/input/$2.crt \
    -v ${OUTPUT_CLIENTS_DIR}:/output \
    ikrupincom/gds-openvpn client-config $2

fi

if [[ $1 == "remove-client" ]]; then

  docker run -it --rm \
    -v ${CA_CONTAINER_NAME}:/root/easy-rsa/ \
    -v ${OUTPUT_DIR}:/output \
    ikrupincom/gds-easyrsa revoke $2

  sudo docker cp ${OUTPUT_DIR}/crl.pem ${VPN_CONTAINER_NAME}:/etc/openvpn/server/crl.pem

fi

if [[ $1 == "start" ]]; then

  docker run -it --rm \
    --name ${VPN_CONTAINER_NAME} \
    -p 1194:1194/udp \
    --cap-add=NET_ADMIN \
    -v ${VPN_CONTAINER_NAME}-easyrsa:/root/easy-rsa/ \
    -v ${VPN_CONTAINER_NAME}-conf:/etc/openvpn/ \
    -v ${VPN_CONTAINER_NAME}-clients:/root/client-configs/ \
    ikrupincom/gds-openvpn start

fi
