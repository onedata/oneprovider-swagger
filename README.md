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

