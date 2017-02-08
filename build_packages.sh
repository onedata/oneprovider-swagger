#!/usr/bin/env bash

declare -A releases

#
# Maps branch names to release names
#
releases["release/3.0.0-rc9"]="3.0.0-rc9"
releases["release/3.0.0-rc10"]="3.0.0-rc10"
releases["release/3.0.0-rc11"]="3.0.0-rc11"
releases["release/3.0.0-rc12"]="3.0.0-rc12"

rm -rf packages
for release_branch in "${!releases[@]}"; do
    git checkout $release_branch
    rm -rf generated

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0
    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:ID-6abaae2b01 generate \
        -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

    mkdir -p "packages/bash/${releases[$release_branch]}"
    cp generated/bash/oneprovider-rest-cli \
        "packages/bash/${releases[$release_branch]}/"
    cp generated/bash/_oneprovider-rest-cli \
        "packages/bash/${releases[$release_branch]}/"
    cp generated/bash/oneprovider-rest-cli.bash-completion \
        "packages/bash/${releases[$release_branch]}/"
done

git checkout master