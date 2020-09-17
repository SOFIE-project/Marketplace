#!/bin/sh

# Usage: update_config.sh contract_file ganache_url output_file

if [ "$#" -ne 3 ]
then
    echo "Usage: $0 contract_file ganache_url output_file" >&2
    exit 1
fi

address=$(cat $1|jq -r '(.networks | to_entries | map(.value.address))[-1]')
minter=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' $2 | jq -r '(.result)[0]')

echo "[marketplace]
url=$2
contract=$address
minter=$minter
artifact=$1
" > $3
