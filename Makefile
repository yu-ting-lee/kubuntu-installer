SHELL = /bin/bash
CONTAINER = installer


.ONESHELL:

env:
	docker build -t base .

clean:
	docker container stop ${CONTAINER} | xargs docker rm

run:
	docker run -it -d --name ${CONTAINER} base
	docker cp src ${CONTAINER}:/home/user/

ssh:
	@CONTAINER_IP=$(shell docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${CONTAINER})
	ssh "user@$${CONTAINER_IP}"