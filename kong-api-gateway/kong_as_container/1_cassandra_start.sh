docker network create kong-net


docker run -d --name kong-database \
        --network=kong-net \
        -e "CASSANDRA_USER=kong" \
        -e "CASSANDRA_PASSWORD=kong" \
        -p 9042:9042 \
        -p 9160:9160 \
        -p 7199:7199 \
        cassandra:3
        


            