#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "=== 1. Generating Root CA ==="
openssl genrsa -out certs/ca/ca.key 2048
MSYS_NO_PATHCONV=1 openssl req -new -x509 -days 1461 \
  -key certs/ca/ca.key \
  -out certs/ca/ca.crt \
  -subj "/CN=Accelerator-Dev-Root-CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"

echo "=== 2. Generating MinIO Server Certificate ==="
openssl genrsa -out certs/minio/private.key 2048
MSYS_NO_PATHCONV=1 openssl req -new \
  -key certs/minio/private.key \
  -out certs/minio/server.csr \
  -subj "/CN=minio"

SAN_MINIO="DNS:localhost,DNS:minio,DNS:localip,DNS:host.docker.internal,IP:127.0.0.1"
cat <<EOF > certs/minio_ext.cnf
[v3]
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=${SAN_MINIO}
EOF

openssl x509 -req -days 1461 \
  -in certs/minio/server.csr \
  -CA certs/ca/ca.crt \
  -CAkey certs/ca/ca.key \
  -CAcreateserial \
  -out certs/minio/public.crt \
  -extfile certs/minio_ext.cnf \
  -extensions v3

rm -f certs/minio/server.csr certs/minio_ext.cnf

echo "=== 3. Generating Backend Server Certificate ==="
openssl genrsa -out certs/backend/private.key 2048
MSYS_NO_PATHCONV=1 openssl req -new \
  -key certs/backend/private.key \
  -out certs/backend/server.csr \
  -subj "/CN=web_be"

SAN_BACKEND="DNS:localhost,DNS:web_be,DNS:localip,DNS:host.docker.internal,IP:127.0.0.1"
cat <<EOF > certs/backend_ext.cnf
[v3]
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=${SAN_BACKEND}
EOF

openssl x509 -req -days 1461 \
  -in certs/backend/server.csr \
  -CA certs/ca/ca.crt \
  -CAkey certs/ca/ca.key \
  -CAcreateserial \
  -out certs/backend/public.crt \
  -extfile certs/backend_ext.cnf \
  -extensions v3

rm -f certs/backend/server.csr certs/backend_ext.cnf

echo "=== Certificates successfully generated! ==="
