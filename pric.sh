CA_PATH="/usr/local/share/ca-certificates/pric"
CA_PRIVATE_KEY="${CA_PATH}/ca.key"
CA_CERTIFICATE="${CA_PATH}/ca.crt"
CERTIFICATE_CHAIN="${HOME}/localhost-certificate.pem"
OPENSSL_CONFIG="openssl.cnf"
OUTPUT_PATH="output"

# Create output directory
mkdir -p ${OUTPUT_PATH}

# Create pric directory in Operating System CA registry
sudo mkdir -p ${CA_PATH}

# Certificate Authority Certificate

## Generate CA private key if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority private key
  openssl genrsa -out ${OUTPUT_PATH}/ca.key 2048

  ## Copy Certificate Authority private key to Operating System CA registry
  sudo cp ${OUTPUT_PATH}/ca.key ${CA_PRIVATE_KEY}
else
  ## Copy Certificate Authority private key from Operating System CA registry
  cp ${CA_PRIVATE_KEY} ${OUTPUT_PATH}/ca.key
fi

## Generate CA certificate if not exists
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority self-signed certificate
  openssl req -x509 -new -nodes -key ${OUTPUT_PATH}/ca.key -sha256 -days 36500 -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_PATH}/ca.crt

  ## Copy Certificate Authority certificate to Operating System CA registry
  sudo cp ${OUTPUT_PATH}/ca.crt ${CA_CERTIFICATE}

  ## Update Operating System CA registry
  sudo update-ca-certificates
else
  ## Copy Certificate Authority certificate from Operating System CA registry
  cp ${CA_CERTIFICATE} ${OUTPUT_PATH}/ca.crt
fi

# Local Server Certificate

## Generate localhost private key
openssl genrsa -out ${OUTPUT_PATH}/localhost.key 2048

## Generate localhost certificate signing request
openssl req -new -key ${OUTPUT_PATH}/localhost.key -config ${OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_PATH}/localhost.csr

## Generate localhost certificate signed by Certificate Authority
openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONFIG} -in ${OUTPUT_PATH}/localhost.csr -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_PATH}/ca.key -CAcreateserial -CAserial ${OUTPUT_PATH}/ca.srl -days 36500 -sha256 -out ${OUTPUT_PATH}/localhost.crt

## Compile PEM certificate chain
cat ${OUTPUT_PATH}/localhost.crt ${CA_CERTIFICATE} ${OUTPUT_PATH}/localhost.key > "${CERTIFICATE_CHAIN}"
