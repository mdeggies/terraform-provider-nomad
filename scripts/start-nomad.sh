#!/bin/bash

export VAULT_TEST_TOKEN=terraform-provider-nomad-token
export VAULT_ADDR=http://localhost:8200

if [ ! -e /tmp/vault-test.pid ]; then
    vault server -dev -dev-root-token-id=$VAULT_TEST_TOKEN > /dev/null 2>&1 &

    VAULT_PID=$!
    echo $VAULT_PID > /tmp/vault-test.pid
else
    echo "Vault server already running"
fi

if [ ! -e /tmp/consul-test.pid ]; then
    consul agent -dev > /dev/null 2>&1 &

    CONSUL_PID=$!
    echo $CONSUL_PID > /tmp/consul-test.pid
else
    echo "Consul agent already running"
fi

if [ ! -e /tmp/nomad-test.pid ]; then
    echo "Nomad agent not running, starting it.."
    sudo nomad agent -dev -bind 0.0.0.0 -acl-enabled -vault-address=$VAULT_ADDR -vault-token $VAULT_TEST_TOKEN -vault-enabled -vault-allow-unauthenticated=false
    NOMAD_PID=$!
    echo $NOMAD_PID > /tmp/nomad-test.pid

    # Give some time for the process to initialize
    sleep 10

    nomad node status
    http --ignore-stdin POST http://localhost:4646/v1/acl/bootstrap | jq -r '.SecretID' > /tmp/nomad-test.token
    echo export NOMAD_TOKEN=$(cat /tmp/nomad-test.token)
    echo export $NOMAD_TOKEN >> $GITHUB_ENV
elif [ -e /tmp/nomad-test.token ]; then 
  echo "Nomad agent already running"
  echo export NOMAD_TOKEN=$(cat /tmp/nomad-test.token)
  echo export $NOMAD_TOKEN >> $GITHUB_ENV
fi
