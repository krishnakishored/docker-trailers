docker run -d --name kong_nodb \
     --network=kong-net \
     --mount type=bind,source="$(pwd)"/kong,target=/usr/local/kong/declarative \
     -e "KONG_DATABASE=off" \
     -e "KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml" \
     -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
     -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
     -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
     -p 8000:8000 \
     -p 8443:8443 \
     -p 127.0.0.1:8001:8001 \
     -p 127.0.0.1:8444:8444 \
     kong:ubuntu 



     # -v "kong-vol:/usr/local/kong/declarative" \
     # -v "$(pwd)"/kong:/usr/local/kong/declarative \

##################### Tips  ###############################################     
# 1. create the docker-network   (Prequisite)
     # docker network create kong-net 
# 2. #  watch -n1 docker container logs kong  
# 3. curl -i http://localhost:8001/
# 4. curl -i http://localhost:8001/services                                                                                                                          ✭