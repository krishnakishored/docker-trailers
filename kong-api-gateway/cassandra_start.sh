docker run -d --name kong-database \
        --networkkong-net \
        -e "KONG_DATABASE=cassandra" \
        -e "KONG_PG_HOST=kong-database" \
        -e "KONG_PG_PASSWORD=kong" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
        -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
        -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
        -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
        -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
        -p 9042:9042 \
        -p 9160:9160 \
        -p 7199:9160 \
        cassandra:3


            