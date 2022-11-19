#!/bin/sh

BASEDIR=$(dirname "$0")

export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

envsubst > $BASEDIR/../encryption-config.yml <<-EOF
kind: EncryptionConfig
apiVersion: v1
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $ENCRYPTION_KEY
  - identity: {}
EOF
