# Configuration parameters
CULL_PERIOD ?= 30
CULL_TIMEOUT ?= 60
LOGGING ?= debug
POOL_SIZE ?= 5

tmpnb-image: Dockerfile
	docker build -t jupyter/tmpnb .

images: tmpnb-image demo-image minimal-image

minimal-image:
	docker pull jupyter/minimal-notebook

demo-image:
	docker pull jupyter/demo

proxy-image:
	docker pull jupyter/configurable-http-proxy

proxy: proxy-image
	docker run --net=host -d -e CONFIGPROXY_AUTH_TOKEN=devtoken \
		--name proxy \
		jupyter/configurable-http-proxy \
		--default-target http://127.0.0.1:9999

tmpnb: minimal-image tmpnb-image
	docker run --net=host -d -e CONFIGPROXY_AUTH_TOKEN=devtoken \
		--name tmpnb \
		-v /var/run/docker.sock:/docker.sock jupyter/tmpnb python orchestrate.py \
<<<<<<< ours
		--image=jupyter/all-spark-notebook --cull_timeout=$(CULL_TIMEOUT) --cull_period=$(CULL_PERIOD) \
		--logging=$(LOGGING) --pool_size=$(POOL_SIZE) --host-directories=/tmp/data:/home/jovyan/work:rw
=======
		--image=jupyter/minimal-notebook --cull_timeout=$(CULL_TIMEOUT) --cull_period=$(CULL_PERIOD) \
		--logging=$(LOGGING) --pool_size=$(POOL_SIZE)
>>>>>>> theirs

dev: cleanup proxy tmpnb open

open:
	docker ps | grep tmpnb
	docker ps | grep minimal-notebook
	-open http:`echo $(DOCKER_HOST) | cut -d":" -f2`:8000

cleanup:
	-docker stop `docker ps -aq --filter name=tmpnb --filter name=proxy --filter name=minimal-notebook`
	-docker rm   `docker ps -aq --filter name=tmpnb --filter name=proxy --filter name=minimal-notebook`
#	-docker images -q --filter "dangling=true" | xargs docker rmi

log-tmpnb:
	docker logs -f tmpnb

log-proxy:
	docker logs -f proxy

.PHONY: cleanup
