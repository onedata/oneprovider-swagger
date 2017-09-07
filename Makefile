UID = $(shell id -u)

SWAGGER_AGGREGATOR_IMAGE    ?= docker.onedata.org/swagger-aggregator:1.5.0
SWAGGER_CLI_IMAGE           ?= docker.onedata.org/swagger-cli:1.5.0
SWAGGER_BOOTPRINT_IMAGE     ?= docker.onedata.org/swagger-bootprint:1.5.0
SWAGGER_MARKDOWN_IMAGE      ?= docker.onedata.org/swagger-gitbook:1.4.1
SWAGGER_COWBOY_SERVER_IMAGE ?= docker.onedata.org/swagger-codegen:1.5.3
SWAGGER_PYTHON_CLIENT_IMAGE ?= docker.onedata.org/swagger-codegen-official:ID-507bde287c
SWAGGER_BASH_CLIENT_IMAGE   ?= docker.onedata.org/bash-swagger-codegen:0.3.6
SWAGGER_REDOC_IMAGE         ?= docker.onedata.org/swagger-redoc:1.0.0

.PHONY : all swagger.json
all : cowboy-server python-client bash-client doc-static doc-markdown

clean:
	@rm -rf generated swagger.json

swagger.json:
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger ${SWAGGER_AGGREGATOR_IMAGE}

validate: swagger.json
	@RESULT="$(shell docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger ${SWAGGER_CLI_IMAGE} validate /swagger/swagger.json 2>&1)"; \
	if [[ $$RESULT =~ .*SyntaxError.* ]]; then\
		echo "$$RESULT";\
		exit 1;\
	fi

cowboy-server: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_COWBOY_SERVER_IMAGE} generate -i ./swagger.json -l cowboy -o ./generated/cowboy
	./fix_generated.py

python-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_PYTHON_CLIENT_IMAGE} generate -i ./swagger.json -l python -o ./generated/python -c python-config.json

bash-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

doc-static: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BOOTPRINT_IMAGE} swagger ./swagger.json generated/static

	@sed -n '/<body>/,/<\/body>/p' generated/static/index.html | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' > generated/static/oneprovider-static.html

doc-markdown: validate
	docker run --rm -v `pwd`:/swagger -t ${SWAGGER_MARKDOWN_IMAGE} convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties

preview: validate
	$(info Open http://localhost:8088  (or http://$${DOCKER_MACHINE_IP}:8088))
	@docker run -v `pwd`/swagger.json:/usr/share/nginx/html/swagger.json:ro -p 8088:80 ${SWAGGER_REDOC_IMAGE}
