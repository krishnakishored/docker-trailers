.PHONY: it deploy rm

it:
	docker stack services pg

deploy:
	docker stack deploy -c docker-compose.yml pg

rm:
	docker stack rm pg
