docker run --rm -it \
            -p 2181:2181 -p 3030:3030 -p 9092:9092 \
            -e ADV_HOST=kafka \
            --name kafka \
            -d \
            --network ilp_stack_ilps \
            landoop/fast-data-dev:1.0.1

            # -p 8081:8081 -p 8082:8082 -p 8083:8083 \