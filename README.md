# pric

Generate localhost development certificate in no time.

## Usage

### Generate certificate

Run `pric` command:

```sh
$ pric.sh
```

This command will:

1. Generate Certificate Authority private key in `/usr/local/share/ca-certificates/pric/ca.key`
2. Generate Certificate Authority self-signed certificate in `/usr/local/share/ca-certificates/pric/ca.crt`
3. Generate localhost private key in `./output/localhost.key`
4. Generate localhost certificate signing request in `./output/localhost.csr`
5. Generate localhost certificate signed by Certificate Authority in `./output/localhost.crt`
6. Compile PEM file in `~/localhost-certificate.pem` (required for [Reverse proxy for PHP built-in server](https://github.com/mpyw/php-hyper-builtin-server))

### Add certificate to browser

#### Firefox

Go to `about:preferences` in address bar. Search for `Certificates` and click `View Cerficicates` button. In `Authorities` tab click `Import` and choose `/usr/local/share/ca-certificates/pric/ca.crt` certificate.

`!pric` Certificate Authority will be added to the list.

#### Chromium (Chrome)

Go to `chrome://settings/certificates` in address bar. In `Authorities` tab click `Import` and choose `/usr/local/share/ca-certificates/pric/ca.crt` certificate.

`org-!pric` Certificate Authority will be added to the list.

## Customization

By default `pric` creates certificate for the following domain names:

- `localhost`
- `test.localhost`
- `*.test.localhost` (wildcard)

This list could be changed in `./dns.cnf` file. 

## License

- `Pric` is open-sourced software licensed under the [MIT license](LICENSE) by [Anton Komarev](https://komarev.com).
