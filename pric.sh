CA_PATH="/usr/local/share/ca-certificates/pric"
CA_PRIVATE_KEY="${CA_PATH}/ca.key"
CA_CERTIFICATE="${CA_PATH}/ca.crt"
CERTIFICATE_CHAIN="${HOME}/localhost-certificate.pem"
OPENSSL_CONFIG="./openssl.cnf"
OPENSSL_DNS_CONFIG="./openssl.dns.cnf"
OPENSSL_DNS_DEFAULT_CONFIG="./openssl.dns.default.cnf"
OUTPUT_PATH="./output"
OUTPUT_CA_PRIVATE_KEY="${OUTPUT_PATH}/ca.key"
OUTPUT_CA_CERTIFICATE="${OUTPUT_PATH}/ca.crt"
OUTPUT_CA_SERIAL_NUMBER="${OUTPUT_PATH}/ca.srl"
OUTPUT_SERVER_PRIVATE_KEY="${OUTPUT_PATH}/localhost.key"
OUTPUT_SERVER_CERTIFICATE="${OUTPUT_PATH}/localhost.crt"
OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST="${OUTPUT_PATH}/localhost.csr"

printf "pric has been started\n"

# Create output directory
printf "\nCreating output directory\n"
(set -x; mkdir -p ${OUTPUT_PATH})

## Generate OpenSSL DNS config list if missing
if [ ! -f ${OPENSSL_DNS_CONFIG} ]; then
  ## Copying OpenSSL DNS config list from defaults
  printf "\nCopying OpenSSL DNS config list from defaults\n"
  (set -x; cp ${OPENSSL_DNS_DEFAULT_CONFIG} ${OPENSSL_DNS_CONFIG})
fi

# Create pric directory in Operating System CA registry
printf "\nCreating pric directory in Operating System CA registry\n"
(set -x; sudo mkdir -p ${CA_PATH})

# Certificate Authority Certificate

## Generate CA private key if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority private key
  printf "\nGenerating Certificate Authority private key\n"
  (set -x; openssl genrsa -out ${OUTPUT_CA_PRIVATE_KEY} 2048)

  ## Copy Certificate Authority private key to Operating System CA registry
  printf "\nCopying Certificate Authority private key to Operating System CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_PRIVATE_KEY} ${CA_PRIVATE_KEY})
else
  ## Copy Certificate Authority private key from Operating System CA registry
  printf "\nCopying Certificate Authority private key from Operating System CA registry\n"
  (set -x; cp ${CA_PRIVATE_KEY} ${OUTPUT_CA_PRIVATE_KEY})
fi

## Generate CA certificate if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority self-signed certificate
  printf "\nGenerating Certificate Authority self-signed certificate\n"
  (set -x; openssl req -x509 -new -nodes -key ${OUTPUT_CA_PRIVATE_KEY} -sha256 -days 36500 -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_CA_CERTIFICATE})

  ## Copy Certificate Authority certificate to Operating System CA registry
  printf "\nCopying Certificate Authority certificate to Operating System CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_CERTIFICATE} ${CA_CERTIFICATE})

  ## Update Operating System CA registry
  printf "\nUpdating Operating System CA registry\n"
  (set -x; sudo update-ca-certificates)
else
  ## Copy Certificate Authority certificate from Operating System CA registry
  printf "\nCopying Certificate Authority certificate from Operating System CA registry\n"
  (set -x; cp ${CA_CERTIFICATE} ${OUTPUT_CA_CERTIFICATE})
fi

# Local Server Certificate

## Generate localhost private key
printf "\nGenerating localhost private key\n"
(set -x; openssl genrsa -out ${OUTPUT_SERVER_PRIVATE_KEY} 2048)

## Generate localhost certificate signing request
printf "\nGenerating localhost certificate signing request\n"
(set -x; openssl req -new -key ${OUTPUT_SERVER_PRIVATE_KEY} -config ${OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST})

## Generate localhost certificate signed by Certificate Authority
printf "\nGenerating localhost certificate signed by Certificate Authority\n"
(set -x; openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONFIG} -in ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST} -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_CA_PRIVATE_KEY} -CAcreateserial -CAserial ${OUTPUT_CA_SERIAL_NUMBER} -days 36500 -sha256 -out ${OUTPUT_SERVER_CERTIFICATE})

## Compile PEM certificate chain
printf "\nCompiling PEM certificate chain\n"
(set -x; cat ${OUTPUT_SERVER_CERTIFICATE} ${CA_CERTIFICATE} ${OUTPUT_SERVER_PRIVATE_KEY} > "${CERTIFICATE_CHAIN}")
