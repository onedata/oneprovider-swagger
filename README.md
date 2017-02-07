# Oneprovider REST API defined using Swagger (http://swagger.io)

This repo contains Swagger specification of Oneprovider REST API.

Oneprovider is part of [Onedata](http://onedata.org), a distributed data management platform. Oneproviders manages local storage resources at a single site, communicates with other Oneprovider instance in other sites and provides the users transparent access to their distributed data.

For more details about Oneprovider service please check (http://github.com/onedata/oneprovider).

Compiling (Using Onedata docker repository):
```
./build.sh
```

Compiling from scratch:
```
# Install Node.js dependencies
npm install

# Aggregate Yaml specification files into a single swagger.json file
node resolve.js > swagger.json
```

After any of these steps you should have a complete `swagger.json` file, with specification of Oneprovider REST API. The file can be used by Swagger [code generator](https://github.com/swagger-api/swagger-codegen) to produce example code for clients in various languages or viewed online using for instance [Swagger Online Editor](http://editor.swagger.io/).


## Using generated Bash client

Below are command line examples for generated bash client.

```shell
export ONEPROVIDER_HOST=https://PROVIDER_IP:8443
export ONEPROVIDER_BASIC_AUTH="username:password"

./oneprovider-rest-cli -h

./oneprovider-rest-cli getAllSpaces -h

./oneprovider-rest-cli getAllSpaces


./oneprovider-rest-cli getFileAttributes path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" attribute=mode


./oneprovider-rest-cli getFileAttributes path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg" attribute=license extended=true


./oneprovider-rest-cli getFileMetadata -ac json path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg"


./oneprovider-rest-cli listFiles path="/OxfordFlowerDataset"

./oneprovider-rest-cli listFiles path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg"

./oneprovider-rest-cli -ac json getFileMetadataById id=0000000000917733836803640004677569646D0000005254576F796132686E575530775331424F516B5534646B5A4963565678644545795746684F616E646B5157466A615531484D565A33516E42785A794D6A6E7A69434565634B2D494A4679387770456E6E3850776D0000002B6136552D334675766A6A6C465A7251576D7639584256304E454448594A615A4C4D6132725A566F704F746B

echo '{"name":"Flower2","genus":"Astragalus"}' | ./oneprovider-rest-cli -ct json setFileMetadata path="/OxfordFlowerDataset/FlowerSet1/image_0801.jpg -"

./oneprovider-rest-cli getAllTransfers

./oneprovider-rest-cli getFileReplicas path="/OxfordFlowerDataset/FlowerSet1/image_0800.jpg"

```
