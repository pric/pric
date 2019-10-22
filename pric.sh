CA_PATH="/usr/local/share/ca-certificates/!pric"
CA_PRIVATE_KEY="${CA_PATH}/ca.key"
CA_CERTIFICATE="${CA_PATH}/ca.crt"
CERTIFICATE_CHAIN="${HOME}/localhost-certificate.pem"
OPENSSL_CONFIG="./openssl.cnf"
OPENSSL_CONFIG_DEFAULT="./openssl.default.cnf"
OPENSSL_DNS_CONFIG="./openssl.dns.cnf"
OPENSSL_DNS_CONFIG_DEFAULT="./openssl.dns.default.cnf"
OUTPUT_PATH="./output"
OUTPUT_CA_PRIVATE_KEY="${OUTPUT_PATH}/ca.key"
OUTPUT_CA_CERTIFICATE="${OUTPUT_PATH}/ca.crt"
OUTPUT_CA_SERIAL_NUMBER="${OUTPUT_PATH}/ca.srl"
OUTPUT_SERVER_PRIVATE_KEY="${OUTPUT_PATH}/localhost.key"
OUTPUT_SERVER_CERTIFICATE="${OUTPUT_PATH}/localhost.crt"
OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST="${OUTPUT_PATH}/localhost.csr"

printf "!pric has been started\n"

# Prepare directories & configuration files

## Determine if output directory is missing
if [ ! -d ${OUTPUT_PATH} ]; then
  ## Create output directory
  printf "\n# Creating output directory\n"
  (set -x; mkdir -p ${OUTPUT_PATH})
fi

## Determine if OpenSSL config is missing
if [ ! -f ${OPENSSL_CONFIG} ]; then
  ## Copying OpenSSL config from defaults
  printf "\n# Copying OpenSSL config from defaults\n"
  (set -x; cp ${OPENSSL_CONFIG_DEFAULT} ${OPENSSL_CONFIG})
fi

## Determine if OpenSSL DNS config list is missing
if [ ! -f ${OPENSSL_DNS_CONFIG} ]; then
  ## Copying OpenSSL DNS config list from defaults
  printf "\n# Copying OpenSSL DNS config list from defaults\n"
  (set -x; cp ${OPENSSL_DNS_CONFIG_DEFAULT} ${OPENSSL_DNS_CONFIG})
fi

## Determine if CA registry directory is missing
if [ ! -d ${CA_PATH} ]; then
  ## Create !pric directory in Operating System CA registry
  printf "\n# Creating !pric directory in Operating System CA registry\n"
  (set -x; sudo mkdir -p ${CA_PATH})
fi

# Certificate Authority Certificate

## Determine if CA private key file is missing
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority private key
  printf "\n# Generating Certificate Authority private key\n"
  (set -x; openssl genrsa -out ${OUTPUT_CA_PRIVATE_KEY} 2048)

  ## Copy Certificate Authority private key to Operating System CA registry
  printf "\n# Copying Certificate Authority private key to Operating System CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_PRIVATE_KEY} ${CA_PRIVATE_KEY})
else
  ## Copy Certificate Authority private key from Operating System CA registry
  printf "\n# Copying Certificate Authority private key from Operating System CA registry\n"
  (set -x; cp ${CA_PRIVATE_KEY} ${OUTPUT_CA_PRIVATE_KEY})
fi

## Determine if CA certificate file is missing
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority self-signed certificate
  printf "\n# Generating Certificate Authority self-signed certificate\n"
  (set -x; openssl req -x509 -new -nodes -key ${OUTPUT_CA_PRIVATE_KEY} -sha256 -days 36500 -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_CA_CERTIFICATE})

  ## Copy Certificate Authority certificate to Operating System CA registry
  printf "\n# Copying Certificate Authority certificate to Operating System CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_CERTIFICATE} ${CA_CERTIFICATE})

  ## Update Operating System CA registry
  printf "\n# Updating Operating System CA registry\n"
  (set -x; sudo update-ca-certificates)
else
  ## Copy Certificate Authority certificate from Operating System CA registry
  printf "\n# Copying Certificate Authority certificate from Operating System CA registry\n"
  (set -x; cp ${CA_CERTIFICATE} ${OUTPUT_CA_CERTIFICATE})
fi

# Local Server Certificate

## Generate localhost private key
printf "\n# Generating localhost private key\n"
(set -x; openssl genrsa -out ${OUTPUT_SERVER_PRIVATE_KEY} 2048)

## Generate localhost certificate signing request
printf "\n# Generating localhost certificate signing request\n"
(set -x; openssl req -new -key ${OUTPUT_SERVER_PRIVATE_KEY} -config ${OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST})

## Generate localhost certificate signed by Certificate Authority
printf "\n# Generating localhost certificate signed by Certificate Authority\n"
(set -x; openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONFIG} -in ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST} -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_CA_PRIVATE_KEY} -CAcreateserial -CAserial ${OUTPUT_CA_SERIAL_NUMBER} -days 36500 -sha256 -out ${OUTPUT_SERVER_CERTIFICATE})

## Compile PEM certificate chain
printf "\n# Compiling PEM certificate chain\n"
(set -x; cat ${OUTPUT_SERVER_CERTIFICATE} ${CA_CERTIFICATE} ${OUTPUT_SERVER_PRIVATE_KEY} > "${CERTIFICATE_CHAIN}")
