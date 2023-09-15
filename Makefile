ACCOUNT:=nuonic
NAME:=node-python-awscli
MAJOR:=6
MINOR:=0
PATCH:=0

build:
	docker buildx build -t nuonic/node-python-awscli .

build-mac:
	docker buildx build -t nuonic/node-python-awscli --platform linux/amd64 .

tag:
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR).$(MINOR).$(PATCH)
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR).$(MINOR)
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR)

push:
	docker image push --all-tags $(ACCOUNT)/$(NAME)

run:
	docker run --rm -it --name buildtest --platform linux/amd64 --volume /Users/denzil/PycharmProjects/inLoop/prism:/prism --volume /Users/denzil/.aws:/root/.aws nuonic/node-python-awscli bash
