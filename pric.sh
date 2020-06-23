CA_PATH="/usr/local/share/ca-certificates/!pric"
CA_PRIVATE_KEY="${CA_PATH}/ca.key"
CA_CERTIFICATE="${CA_PATH}/ca.crt"
CA_CERTIFICATE_LIFETIME_DAYS=825
SERVER_CERTIFICATE_LIFETIME_DAYS=825
OPENSSL_BASE_CONFIG="./openssl.base.cnf"
OPENSSL_BASE_CONFIG_DEFAULT="./openssl.base.default.cnf"
OPENSSL_DNS_CONFIG="./openssl.dns.cnf"
OPENSSL_DNS_CONFIG_DEFAULT="./openssl.dns.default.cnf"
OUTPUT_PATH="./output"
OUTPUT_CA_PRIVATE_KEY="${OUTPUT_PATH}/ca.key"
OUTPUT_CA_CERTIFICATE="${OUTPUT_PATH}/ca.crt"
OUTPUT_CA_SERIAL_NUMBER="${OUTPUT_PATH}/ca.srl"
OUTPUT_SERVER_PRIVATE_KEY="${OUTPUT_PATH}/localhost.key"
OUTPUT_SERVER_CERTIFICATE="${OUTPUT_PATH}/localhost.crt"
OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST="${OUTPUT_PATH}/localhost.csr"
OUTPUT_OPENSSL_CONFIG="${OUTPUT_PATH}/openssl.cnf"
CERTIFICATE_CHAIN="${HOME}/localhost-certificate.pem"
OPERATING_SYSTEM=$(uname -s)

printf "!pric has been started\n"

# Initialization

## Determine if output directory is missing
if [ ! -d ${OUTPUT_PATH} ]; then
  ## Create output directory
  printf "\n# Creating output directory\n"
  (set -x; mkdir -p ${OUTPUT_PATH})
fi

## Determine if OpenSSL base config is missing
if [ ! -f ${OPENSSL_BASE_CONFIG} ]; then
  ## Copying OpenSSL base config from defaults
  printf "\n# Copying OpenSSL base config from defaults\n"
  (set -x; cp ${OPENSSL_BASE_CONFIG_DEFAULT} ${OPENSSL_BASE_CONFIG})
fi

## Determine if OpenSSL DNS config list is missing
if [ ! -f ${OPENSSL_DNS_CONFIG} ]; then
  ## Copying OpenSSL DNS config list from defaults
  printf "\n# Copying OpenSSL DNS config list from defaults\n"
  (set -x; cp ${OPENSSL_DNS_CONFIG_DEFAULT} ${OPENSSL_DNS_CONFIG})
fi

## Compile OpenSSL final config from intermediates
printf "\n# Compiling OpenSSL final config from intermediates\n"
(set -x; cat ${OPENSSL_BASE_CONFIG} ${OPENSSL_DNS_CONFIG} > "${OUTPUT_OPENSSL_CONFIG}")

## Determine if CA registry directory is missing
if [ ! -d ${CA_PATH} ]; then
  ## Create !pric directory in operating system CA registry
  printf "\n# Creating !pric directory in operating system CA registry\n"
  (set -x; sudo mkdir -p ${CA_PATH})
fi

# Certificate Authority

## Determine if CA private key file is missing
if [ ! -f ${CA_PRIVATE_KEY} ]; then
  ## Generate Certificate Authority private key
  printf "\n# Generating Certificate Authority private key\n"
  (set -x; openssl genrsa -out ${OUTPUT_CA_PRIVATE_KEY} 2048)

  ## Copy Certificate Authority private key to operating system CA registry
  printf "\n# Copying Certificate Authority private key to operating system CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_PRIVATE_KEY} ${CA_PRIVATE_KEY})
else
  ## Copy Certificate Authority private key from operating system CA registry
  printf "\n# Copying Certificate Authority private key from operating system CA registry\n"
  (set -x; cp ${CA_PRIVATE_KEY} ${OUTPUT_CA_PRIVATE_KEY})
fi

## Determine if CA certificate file is missing
if [ ! -f ${CA_CERTIFICATE} ]; then
  ## Generate Certificate Authority self-signed certificate
  printf "\n# Generating Certificate Authority self-signed certificate\n"
  (set -x; openssl req -x509 -new -nodes -key ${OUTPUT_CA_PRIVATE_KEY} -sha256 -days ${CA_CERTIFICATE_LIFETIME_DAYS} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_CA_CERTIFICATE})

  ## Copy Certificate Authority certificate to operating system CA registry
  printf "\n# Copying Certificate Authority certificate to operating system CA registry\n"
  (set -x; sudo cp ${OUTPUT_CA_CERTIFICATE} ${CA_CERTIFICATE})
else
  ## Copy Certificate Authority certificate from operating system CA registry
  printf "\n# Copying Certificate Authority certificate from operating system CA registry\n"
  (set -x; cp ${CA_CERTIFICATE} ${OUTPUT_CA_CERTIFICATE})
fi

## Update operating system CA registry
printf "\n# Updating operating system CA registry\n"
case $OPERATING_SYSTEM in
  Linux*)
    if [ $(command -v update-ca-certificates) ]; then
      (set -x; sudo update-ca-certificates)
    elif [ $(command -v update-ca-trust) ]; then
      (set -x; sudo update-ca-trust)
    else
      LINUX_DISTRIBUTIVE=$(head -1 /etc/os-release | sed -e "s/NAME=//g" | sed -e "s/\"//g" | sed -e "s/ /+/g")
      printf "\nUnsupported Linux Distributive: ${LINUX_DISTRIBUTIVE}"
      printf "\nCreate an issue on GitHub https://github.com/pric/pric/issues/new?title=Linux+distributive+${LINUX_DISTRIBUTIVE}+not+supported\n"
      exit
    fi
    ;;
  Darwin*)
    (set -x; sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${OUTPUT_CA_CERTIFICATE})
    ;;
  *)
    printf "\nUnsupported OS: ${OPERATING_SYSTEM}"
    printf "\nCreate an issue on GitHub https://github.com/pric/pric/issues/new?title=OS+${OPERATING_SYSTEM}+not+supported\n"
    exit
esac

# Server Certificate

## Generate server private key
printf "\n# Generating server private key\n"
(set -x; openssl genrsa -out ${OUTPUT_SERVER_PRIVATE_KEY} 2048)

## Generate server certificate signing request
printf "\n# Generating server certificate signing request\n"
(set -x; openssl req -new -key ${OUTPUT_SERVER_PRIVATE_KEY} -config ${OUTPUT_OPENSSL_CONFIG} -subj "/O=\!pric/CN=localhost" -out ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST})

## Generate server certificate signed by Certificate Authority
printf "\n# Generating server certificate signed by Certificate Authority\n"
(set -x; openssl x509 -req -extensions v3_req -extfile ${OUTPUT_OPENSSL_CONFIG} -in ${OUTPUT_SERVER_CERTIFICATE_SIGNING_REQUEST} -CA ${CA_CERTIFICATE} -CAkey ${OUTPUT_CA_PRIVATE_KEY} -CAcreateserial -CAserial ${OUTPUT_CA_SERIAL_NUMBER} -days ${SERVER_CERTIFICATE_LIFETIME_DAYS} -sha256 -out ${OUTPUT_SERVER_CERTIFICATE})

# Optional

## Compile PEM certificate chain
printf "\n# Compiling PEM certificate chain\n"
(set -x; cat ${OUTPUT_SERVER_CERTIFICATE} ${CA_CERTIFICATE} ${OUTPUT_SERVER_PRIVATE_KEY} > "${CERTIFICATE_CHAIN}")
