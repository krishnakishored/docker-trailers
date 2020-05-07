.PHONY: it deploy rm

it:
	# docker stack services pg
	docker container exec -it redis bash

deploy:
	docker-compose up -d

down:
	docker-compose down
	
ps:
	docker-compose ps