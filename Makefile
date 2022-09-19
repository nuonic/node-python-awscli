ACCOUNT:=nuonic
NAME:=node-python-awscli
MAJOR:=3
MINOR:=1
PATCH:=0

build:
	docker build -t nuonic/node-python-awscli .

tag:
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR).$(MINOR).$(PATCH)
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR).$(MINOR)
	docker image tag nuonic/node-python-awscli nuonic/node-python-awscli:$(MAJOR)

push:
	docker image push --all-tags $(ACCOUNT)/$(NAME)

run:
	docker run --rm -it --name buildtest --volume /Users/guycarpenter/prism:/prism --volume /Users/guycarpenter/.aws:/root/.aws nuonic/node-python-awscli:2 bash
