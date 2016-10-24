#!/usr/bin/env bats


export ONEPROVIDER_HOST="https://localhost:9443"
export ONEPROVIDER_API_KEY="SECRET"

export ONEPROVIDER_CLI=generated/bash/oneprovider-rest-cli

#
# Tests generation of curl requests
#
@test "getAllSpaces Api key passed as header" {
    run bash $ONEPROVIDER_CLI getAllSpaces --dry-run X-Auth-Key:SECRET
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/spaces" ]]
    [[ "$output" =~ "-X GET" ]]
    [[ "$output" =~ "X-Auth-Token: SECRET" ]]
}

@test "getAllSpaces Api key from environment variable" {
    run bash $ONEPROVIDER_CLI getAllSpaces --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/spaces" ]]
    [[ "$output" =~ "-X GET" ]]
    [[ "$output" =~ "X-Auth-Token: SECRET" ]]
}

@test "getAllSpaces username and password" {
    run bash $ONEPROVIDER_CLI -u username:password getAllSpaces --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/spaces" ]]
    [[ "$output" =~ "-X GET" ]]
    [[ "$output" =~ "-u username:password" ]]
}

@test "getFileAttributes not extended" {
    run bash $ONEPROVIDER_CLI getFileAttributes path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" attribute=mode --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/attributes//OxfordFlowerDataset/FlowerSet1/image_0800.jpg?attribute=mode" ]]
    [[ "$output" =~ "-X GET" ]]
}

@test "getFileAttributes extended" {
    run bash $ONEPROVIDER_CLI getFileAttributes path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" attribute=license extended=true --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/attributes//OxfordFlowerDataset/FlowerSet1/image_0800.jpg?" ]]
    [[ "$output" =~ "attribute=license" ]]
    [[ "$output" =~ "extended=true" ]]
    [[ "$output" =~ "-X GET" ]]
}

@test "getFileAttributes extended with spaces" {
    run bash $ONEPROVIDER_CLI getFileAttributes path="/Oxford Flower Dataset/Flower Set1/image_0800.jpg" attribute=license extended=true --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/attributes//Oxford%20Flower%20Dataset/Flower%20Set1/image_0800.jpg?" ]]
    [[ "$output" =~ "attribute=license" ]]
    [[ "$output" =~ "extended=true" ]]
    [[ "$output" =~ "-X GET" ]]
}

@test "getFileMetadata json" {
    run bash $ONEPROVIDER_CLI getFileAttributes -ac json path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/attributes//OxfordFlowerDataset/FlowerSet1/image_0800.jpg" ]]
    [[ "$output" =~ "-H 'Accept: application/json'" ]]
    [[ "$output" =~ "-X GET" ]]
}

@test "getFileMetadata rdf" {
    run bash $ONEPROVIDER_CLI getFileAttributes -ac rdf path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/attributes//OxfordFlowerDataset/FlowerSet1/image_0800.jpg" ]]
    [[ "$output" =~ "-H 'Accept: application/rdf+xml'" ]]
    [[ "$output" =~ "-X GET" ]]
}

@test "setFileMetadata from file" {
    run bash ${ONEPROVIDER_CLI} -ct json -d @metadata.json setFileMetadata path="/OxfordFlowerDataset/FlowerSet1/image_0801.jpg" --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/metadata//OxfordFlowerDataset/FlowerSet1/image_0801.jpg" ]]
    [[ "$output" =~ "-H 'Content-type: application/json'" ]]
    [[ "$output" =~ "-d @metadata.json" ]]
    [[ "$output" =~ "-X PUT" ]]
}

@test "querySpaceIndexes attributes" {
    run bash ${ONEPROVIDER_CLI} querySpaceIndexes iid="1234-1234-1234-1234" endkey_docid=123 inclusive_end=45 --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/oneprovider/query-index/1234-1234-1234-1234" ]]
    [[ "$output" =~ "endkey_docid=123" ]]
    [[ "$output" =~ "-X GET" ]]
}

