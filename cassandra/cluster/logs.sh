echo "./logs.sh <short_service_name (calculate/submission/slam_positioning/slam_learning)>"
docker service logs -ft cassandra_stack_$1
