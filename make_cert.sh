#!/bin/bash

if [ $# -lt 9 ]; then
  echo "usage : "
  echo "  make_cert.sh -n [Common Name] -p [password] -d [expire days] -c [Country Name] -s [State or Province Name] -l [Locality Name] -o [Organization Name] -u [Organizational Unit Name] -a [Subject Alternative Name] -a ..."
  echo "    Subject Alternative Name : DNS or IPaddress (ex: DNS.1=localhost, IP.1=192.168.1.1)"
  exit 1;
fi

touch subjectAltName

while getopts n:p:d:c:s:l:o:u:a: OPT
do
  case $OPT in
    "n" ) commonName="$OPTARG"; subj+="/CN="; subj+="$OPTARG" ;;
    "p" ) password=$OPTARG ;;
    "d" ) days="$OPTARG" ;;
    "c" ) subj+="/C="; subj+="$OPTARG" ;;
    "s" ) subj+="/ST="; subj+="$OPTARG" ;;
    "l" ) subj+="/L="; subj+="$OPTARG" ;;
    "o" ) subj+="/O="; subj+="$OPTARG" ;;
    "u" ) subj+="/OU="; subj+="$OPTARG" ;;
    "a" ) echo "$OPTARG" >> subjectAltName ;;
  esac
done

rm -rf $commonName
mkdir $commonName
touch index.txt
echo 01 > ./serial
cat v3_server.txt subjectAltName > $commonName/v3_server.txt

openssl genrsa -aes256 -passout pass:$password -out $commonName/cakey.pem 2048

openssl req -passin pass:$password -new -key $commonName/cakey.pem -out $commonName/cacert.csr -config openssl.cnf -subj $subj

openssl ca -passin pass:$password -in $commonName/cacert.csr -selfsign -keyfile $commonName/cakey.pem -notext -config openssl.cnf -subj $subj -outdir . -days $days -extfile v3_ca.txt -out $commonName/cacert.pem -batch

openssl x509 -in $commonName/cacert.pem -out $commonName/cacert.crt

rm index.txt
touch index.txt

openssl genrsa -aes256 -passout pass:$password -out $commonName/server.key 2048

openssl req -passin pass:$password -new -key $commonName/server.key -out $commonName/server.csr  -config openssl.cnf -subj $subj

openssl ca -passin pass:$password -in $commonName/server.csr -keyfile $commonName/cakey.pem -cert $commonName/cacert.pem -outdir . -notext -config openssl.cnf -extfile $commonName/v3_server.txt -extensions SAN -out $commonName/server.crt -days $days -batch

openssl rsa -passin pass:$password -in $commonName/server.key -out $commonName/server.key

openssl pkcs12 -passout pass:$password -export -in $commonName/server.crt -inkey $commonName/server.key -out $commonName/server.p12 -name server -CAfile ca.crt -caname server

rm -f serial* index.txt* *.pem subjectAltName
