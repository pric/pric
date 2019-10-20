CA_PATH="/usr/local/share/ca-certificates/pric"
CA_PRIVATE_KEY="${CA_PATH}/ca.key"
CA_CERTIFICATE="${CA_PATH}/ca.crt"
CERTIFICATE_CHAIN="${HOME}/localhost-certificate.pem"
OPENSSL_CONFIG="openssl.cnf"
OUTPUT_PATH="./output"
OUTPUT_CA_PRIVATE_KEY="${OUTPUT_PATH}/ca.key"
OUTPUT_CA_CERTIFICATE="${OUTPUT_PATH}/ca.crt"

printf "pric has been started\n"

# Create output directory
printf "\nCreating output directory\n"
printf "mkdir -p ${OUTPUT_PATH}\n"
mkdir -p ${OUTPUT_PATH}

# Create pric directory in Operating System CA registry
printf "\nCreating pric directory in Operating System CA registry\n"
printf "sudo mkdir -p ${CA_PATH}\n"
sudo mkdir -p ${CA_PATH}

# Certificate Authority Certificate

## Generate CA private key if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority private key
  printf "\nGenerating Certificate Authority private key\n"
  pfintf "openssl genrsa -out ${OUTPUT_CA_PRIVATE_KEY} 2048\n"
  openssl genrsa -out ${OUTPUT_CA_PRIVATE_KEY} 2048

  ## Copy Certificate Authority private key to Operating System CA registry
  printf "\nCopying Certificate Authority private key to Operating System CA registry\n"
  printf "sudo cp ${OUTPUT_CA_PRIVATE_KEY} ${CA_PRIVATE_KEY}\n"
  sudo cp ${OUTPUT_CA_PRIVATE_KEY} ${CA_PRIVATE_KEY}
else
  ## Copy Certificate Authority private key from Operating System CA registry
  printf "\nCopying Certificate Authority private key from Operating System CA registry\n"
  printf "cp ${CA_PRIVATE_KEY} ${OUTPUT_CA_PRIVATE_KEY}\n"
  cp ${CA_PRIVATE_KEY} ${OUTPUT_CA_PRIVATE_KEY}
fi

## Generate CA certificate if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority self-signed certificate
  printf "\nGenerating Certificate Authority self-signed certificate\n"
  printf "\nopenssl req -x509 -new -nodes -key ${OUTPUT_CA_PRIVATE_KEY} -sha256 -days 36500 -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_CA_CERTIFICATE}\n"
  openssl req -x509 -new -nodes -key ${OUTPUT_CA_PRIVATE_KEY} -sha256 -days 36500 -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_CA_CERTIFICATE}

  ## Copy Certificate Authority certificate to Operating System CA registry
  printf "\nCopying Certificate Authority certificate to Operating System CA registry\n"
  printf "\nsudo cp ${OUTPUT_CA_CERTIFICATE} ${CA_CERTIFICATE}\n"
  sudo cp ${OUTPUT_CA_CERTIFICATE} ${CA_CERTIFICATE}

  ## Update Operating System CA registry
  printf "\nUpdating Operating System CA registry\n"
  printf "sudo update-ca-certificates\n"
  sudo update-ca-certificates
else
  ## Copy Certificate Authority certificate from Operating System CA registry
  printf "\nCopying Certificate Authority certificate from Operating System CA registry\n"
  printf "cp ${CA_CERTIFICATE} ${OUTPUT_CA_CERTIFICATE}"
  cp ${CA_CERTIFICATE} ${OUTPUT_CA_CERTIFICATE}
fi

# Local Server Certificate

## Generate localhost private key
printf "\nGenerating localhost private key\n"
printf "openssl genrsa -out ${OUTPUT_PATH}/localhost.key 2048"
openssl genrsa -out ${OUTPUT_PATH}/localhost.key 2048

## Generate localhost certificate signing request
printf "\nGenerating localhost certificate signing request\n"
printf "openssl req -new -key ${OUTPUT_PATH}/localhost.key -config ${OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_PATH}/localhost.csr"
openssl req -new -key ${OUTPUT_PATH}/localhost.key -config ${OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_PATH}/localhost.csr

## Generate localhost certificate signed by Certificate Authority
printf "\nGenerating localhost certificate signed by Certificate Authority\n"
printf "openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONFIG} -in ${OUTPUT_PATH}/localhost.csr -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_PATH}/ca.key -CAcreateserial -CAserial ${OUTPUT_PATH}/ca.srl -days 36500 -sha256 -out ${OUTPUT_PATH}/localhost.crt"
openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONFIG} -in ${OUTPUT_PATH}/localhost.csr -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_PATH}/ca.key -CAcreateserial -CAserial ${OUTPUT_PATH}/ca.srl -days 36500 -sha256 -out ${OUTPUT_PATH}/localhost.crt

## Compile PEM certificate chain
printf "\nCompiling PEM certificate chain\n"
printf "cat ${OUTPUT_PATH}/localhost.crt ${CA_CERTIFICATE} ${OUTPUT_PATH}/localhost.key > "${CERTIFICATE_CHAIN}"\n"
cat ${OUTPUT_PATH}/localhost.crt ${CA_CERTIFICATE} ${OUTPUT_PATH}/localhost.key > "${CERTIFICATE_CHAIN}"
