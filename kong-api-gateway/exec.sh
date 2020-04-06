docker exec -it kong_nodb bash

# #Checking The Declarative Configuration File


# Multiple line comments
:'
$ kong version
$ kong config -c /etc/kong/kong.conf parse ./usr/local/kong/declarative/kong.yml --v
'
