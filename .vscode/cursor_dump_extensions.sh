#!/bin/bash

dir=$(dirname $0)
cursor --list-extensions | jq -R '[inputs] | {"recommendations": .}' > $dir/extensions.json 
