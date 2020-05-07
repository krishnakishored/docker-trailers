# https://docs.confluent.io/current/app-development/kafkacat-usage.html

docker run --rm --tty \
    --network ilps-net \
    confluentinc/cp-kafkacat \
    kafkacat -b kafka:9092 $@
