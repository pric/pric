# !pric

![!pric](https://user-images.githubusercontent.com/1849174/67256070-f33df200-f48d-11e9-9cfc-33b1a979cf65.png)

Issue localhost development server certificates signed by own Private Certificate Authority in no time.

**Use !pric only for development on local hosts. For public hosts consider using [Let's Encrypt](https://letsencrypt.org/)!**

## Introduction

Self-signed certificates cause trust errors and issue locally-trusted development certificates signed by real
Certificate Authority (CA) can be dangerous or even impossible for the hosts like `localhost`.

!pric automatically creates and installs a local CA in the system root store, and generates locally-trusted certificates.

## Usage

[Download !pric sources](https://github.com/pric/pric/archive/master.zip) via browser and unzip file.

In unzipped directory execute `pric.sh` terminal command:

```sh
$ sh pric.sh
```

This command will:

1. Generate Certificate Authority private key in `/usr/local/share/ca-certificates/!pric/ca.key`
2. Generate Certificate Authority self-signed certificate in `/usr/local/share/ca-certificates/!pric/ca.crt`
3. Generate localhost private key in `./output/localhost.key`
4. Generate localhost certificate signing request in `./output/localhost.csr`
5. Generate localhost certificate signed by Certificate Authority in `./output/localhost.crt`
6. Compile PEM file in `~/localhost-certificate.pem` (required for [Reverse proxy for PHP built-in server](https://github.com/mpyw/php-hyper-builtin-server))

Terminal output:

![!pric output](https://user-images.githubusercontent.com/1849174/67256373-5419fa00-f48f-11e9-884c-2a3cbe97bd73.png)

### Import Certificate Authority to browser

#### Firefox

1. Go to `about:preferences` in address bar.
2. Search for `Certificates` and click `View Cerficicates` button.
3. In `Authorities` tab click `Import` and choose `/usr/local/share/ca-certificates/!pric/ca.crt` certificate.

`!pric` Certificate Authority will be added to the list.

#### Chromium (Chrome)

1. Go to `chrome://settings/certificates` in address bar.
2. In `Authorities` tab click `Import` and choose `/usr/local/share/ca-certificates/!pric/ca.crt` certificate.

`org-!pric` Certificate Authority will be added to the list.

## Customization

By default `!pric` creates certificate for the following domain names:

- `localhost`
- `test.localhost`
- `*.test.localhost` (wildcard)

This list could be changed in `./openssl.dns.cnf` file (`!pric` creates missing config file on start).

## Verify Certificate Working

Run web development server on 4000 port and try to access it via cURL:

```sh
$ curl -v https://localhost:4000

* Rebuilt URL to: https://localhost:4000/
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 4000 (#0)
* found 150 certificates in /etc/ssl/certs/ca-certificates.crt
* found 602 certificates in /etc/ssl/certs
* ALPN, offering http/1.1
* SSL connection using TLS1.2 / ECDHE_RSA_AES_128_GCM_SHA256
* 	 server certificate verification OK
* 	 server certificate status verification SKIPPED
* 	 common name: localhost (matched)
* 	 server certificate expiration date OK
* 	 server certificate activation date OK
* 	 certificate public key: RSA
* 	 certificate version: #3
* 	 subject: O=!pric,CN=localhost
* 	 start date: Mon, 21 Oct 2019 00:11:45 GMT
* 	 expire date: Wed, 27 Sep 2119 00:11:45 GMT
* 	 issuer: O=!pric,CN=localhost
* 	 compression: NULL
* ALPN, server did not agree to a protocol
> GET / HTTP/1.1
> Host: localhost:4000
> User-Agent: curl/7.47.0
> Accept: */*
```

## Authors

- [Anton Komarev](https://komarev.com)
- [Dmitry Romanyuta](https://github.com/dumus)

## License

- `!pric` is open-sourced software licensed under the [MIT license](LICENSE) by [Anton Komarev](https://komarev.com).
- `IT Specialist Help` logo image licensed under [Creative Commons 3.0](https://creativecommons.org/licenses/by/3.0/us/) by Gan Khoon Lay.
