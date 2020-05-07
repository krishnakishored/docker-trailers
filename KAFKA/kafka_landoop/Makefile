.PHONY: it run exec stop console

it: exec

console:
	docker run --rm -it --net=dev \
		landoop/fast-data-dev:1.0.1 \
		bash

exec:
	docker exec --privileged -it kafka bash

kafkacat:
	docker run --tty \
           --network dev \
		   confluentinc/cp-kafkacat:5.1.4 \
           kafkacat -b kafka:9092 \
                    -L

logs:
	docker logs -f kafka

restart: stop run

run:
	docker run --rm -it \
            -p 2181:2181 -p 3030:3030 -p 9092:9092 \
            --name kafka \
            -e ADV_HOST=192.168.1.14 \
            -d \
            --network dev \
            landoop/fast-data-dev:1.0.1

stop:
	docker stop kafka
