.PHONY: it deploy rm

compose-file := docker-compose_with_postgres.yml 
# compose-file := docker-compose_with_cassandra.yml

it:
	docker container exec -it kong sh

down:
	docker-compose -f $(compose-file) down

1_kong-database:
	docker-compose -f $(compose-file) up -d kong-database	

2_kong-migrations:
	docker-compose -f $(compose-file) up kong-migrations

3_kong-migrations-up:
	docker-compose -f $(compose-file) up kong-migrations-up

4_kong:
	docker-compose -f $(compose-file) up -d kong

5_adminer:
	docker-compose -f $(compose-file) up -d adminer
	# http://localhost:28080/
	# server - 192.168.1.136:5432(ifconfig |grep inet -  ip of host), username,pwd,db(..kong)

ps:
	docker-compose -f $(compose-file) ps

ls:
	docker container ls

exec:
	docker exec --privileged -it kong bash

# deploy:
	# docker stack deploy -c $(compose-file)

#----------------------------------#


