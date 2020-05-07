# docker container start
# docker run --name redis -v redis_data:/data -p 6379:6379 -d redis redis-server --appendonly yes 

# start server on local mac
redis-server /usr/local/etc/redis.conf

