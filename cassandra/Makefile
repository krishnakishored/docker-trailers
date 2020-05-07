.PHONY: exec logs restart run stop

console:
	docker exec -it cassandra bash

# container_id=$(
#     for f in $(docker service ps -q cassandra);
#     do docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $f;
#     done)
#     # echo $container_id
	# docker exec -it $container_id bash
	# docker exec --privileged -it cassandra bash

cqlsh:
	docker exec -it cassandra $@

logs:
	docker logs -f cassandra

restart: stop run

run:
	docker run --rm \
		--name cassandra \
		-p 9042:9042 -p 9160:9160 \
		-e CASSANDRA_BROADCAST_ADDRESS=127.0.0.1 \
		-v `pwd`/testdb:/var/lib/cassandra \
		-v `pwd`/mnt:/mnt/shared \
		--network dev \
		-d cassandra

# docker network create ilps-net
# docker service create \
#     --name cassandra \
#     --network ilps-net \
#     -e CASSANDRA_BROADCAST_ADDRESS=127.0.0.1 \
#     -e CASSANDRA_LISTEN_ADDRESS=127.0.0.1 \
#     -e CASSANDRA_RPC_ADDRESS=127.0.0.1 \
#     -p 9042:9042 -p 9160:9160 \
#     --mount type=bind,source="$(pwd)"/testdb,destination=/var/lib/cassandra \
#     --mount type=bind,source="$(pwd)"/mnt,destination=/mnt/shared \
#     -d cassandra

stop:
	docker stop cassandra

# docker service rm cassandra
