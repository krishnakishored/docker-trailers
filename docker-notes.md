# Docker Tutorial notes
------------------------------------------    

## Kong

The `Kong API Gateway` is open-source, cloud-native and platform agnostic, allowing it to be deployed in a wide range of different patterns including monolithic, service-based, serverless and microservices/service mesh-based. 
Some of the most common applications of API policies include:
 - Security
 - Traffic Limiting
 - Transformation of Data

Kong is a Lua application running in Nginx and made possible by the lua-nginx-module. Instead of compiling Nginx with this module, Kong is distributed along with `OpenResty`, which already includes lua-nginx-module. OpenResty is not a fork of Nginx, but a bundle of modules extending its capabilities.

- `plugin`: a plugin executing actions inside Kong before or after a request has been proxied to the upstream API.
- `Service`: the Kong entity representing an external upstream API or microservice.
- `Route`: the Kong entity representing a way to map downstream requests to upstream services.
- `Consumer`: an entity that makes requests for Kong to proxy; it represents either a user or an external service.
- `Credential`: a unique string associated with a Consumer, also referred to as an API key.
- `Upstream service`: this refers to your own API/service sitting behind Kong, to which client requests are forwarded

### Getting Started

#### Installation with Cassandra DB
1. Create docker network  -  `$ docker network create kong-net`
1. Start your database   
    `
        $ docker run -d --name kong-database \
            --network=kong-net \
            -p 9042:9042 \
            cassandra:3
    `
1. Prepare your database. Run the migrations with an ephemeral Kong container:  
    `
    $ docker run --rm \
     --network=kong-net \
     -e "KONG_DATABASE=cassandra" \
     -e "KONG_PG_HOST=kong-database" \
     -e "KONG_PG_PASSWORD=kong" \
     -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
     kong:latest kong migrations bootstrap
    `
1. Start Kong  
    `
    $ docker run -d --name kong \
        --network=kong-net \
        -e "KONG_DATABASE=cassandra" \
        -e "KONG_PG_HOST=kong-database" \
        -e "KONG_PG_PASSWORD=kong" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
        -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
        -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
        -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
        -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
        -p 8000:8000 \
        -p 8443:8443 \
        -p 127.0.0.1:8001:8001 \
        -p 127.0.0.1:8444:8444 \
        kong:latest
    `

#### Installation with DB-less mode

1. Create docker network - `$ docker network create kong-net`
> This step is not strictly needed for running Kong in DB-less mode, but it is a good precaution in case you want to add other things in the future (like a rate-limiting plugin backed up by a Redis cluster).

1. Kong comes with a default configuration file that can be found at `/etc/kong/kong.conf.default` if you installed Kong via one of the official packages. To start configuring Kong, you can copy this file: `$ cp /etc/kong/kong.conf.default /etc/kong/kong.conf`

1. You can verify the integrity of your settings with the check command: `$ kong check <path/to/kong.conf>`  
    `
    $ kong config -c /etc/kong/kong.conf parse ./usr/local/kong/declarative/kong.yml --v
    `
        2020/04/06 07:24:22 [verbose] Kong: 2.0.2
        2020/04/06 07:24:22 [verbose] prefix in use: /usr/local/kong
        2020/04/06 07:24:22 [verbose] reading config file at /usr/local/kong/.kong_env
        2020/04/06 07:24:22 [verbose] prefix in use: /usr/local/kong
        2020/04/06 07:24:22 [info] parse successful

1. Kong exposes a RESTful Admin API on port :8001. Kong’s configuration, including adding Services and Routes, is made via requests on that API.
1. Loading The Declarative Configuration File
    - update the files. e.g.: in kong.yml (url: http://192.168.1.149:9091)
    `$ kong reload`

#### Configuring a service

1. Add your Service using the Admin API   
    `
    $ curl -i -X POST \
    --url http://localhost:8001/services/ \
    --data 'name=example-service' \
    --data 'url=http://mockbin.org'
    `
1. Add a Route for the Service  
    `
    $ curl -i -X POST \
    --url http://localhost:8001/services/example-service/routes \
    --data 'hosts[]=example.com'
    `
    - Kong is now aware of your Service and ready to proxy requests.   

1. Forward your requests through Kong
    `
        $ curl -i -X GET \
        --url http://localhost:8000/ \
        --header 'Host: example.com'
    `
    - Note that by default Kong handles proxy requests on port :8000
    - A successful response means Kong is now forwarding requests made to http://localhost:8000 to the url we configured in step #1, and is forwarding the response back to us. Kong knows to do this through the header defined in the above cURL request:

#### Enabling Plugins    

1. Configure the key-auth plugin
    `
    $ curl -i -X POST \
    --url http://localhost:8001/services/example-service/plugins/ \
    --data 'name=key-auth'
    `
1. Verify that the plugin is properly configured
    `
    $ curl -i -X GET \
    --url http://localhost:8000/ \
    --header 'Host: example.com'
    `
    - Since you did not specify the required apikey header or parameter, the response should be 401 Unauthorized:

#### Adding Consumers
1. Create a Consumer through the RESTful API
    `
    $ curl -i -X POST \
    --url http://localhost:8001/consumers/ \
    --data "username=Jason"
    `
- Kong also accepts a custom_id parameter when creating consumers to associate a consumer with your existing user database

1. Provision key credentials for your Consumer
    `
    $ curl -i -X POST \
    --url http://localhost:8001/consumers/Jason/key-auth/ \
    --data 'key=ENTER_KEY_HERE'
    `

### Request Transformer
A Kong plugin that transforms the request sent by a client on the fly on Kong, before hitting the upstream server.
This plugin is compatible with requests with the following protocols: http, https  
This plugin is compatible with DB-less mode  

- Enabling the plugin on a Service
    `
     $  curl -X POST http://kong:8001/services/{service}/plugins \
        --data "name=request-transformer"  \
        --data "config.remove.headers=x-toremove" \
        --data "config.remove.headers=x-another-one" \
        --data "config.remove.querystring=qs-old-name:qs-new-name" \
        --data "config.remove.querystring=qs2-old-name:qs2-new-name" \
        --data "config.remove.body=formparam-toremove" \
        --data "config.remove.body=formparam-another-one" \
        --data "config.rename.headers=header-old-name:header-new-name" \
        --data "config.rename.headers=another-old-name:another-new-name" \
        --data "config.rename.querystring=qs-old-name:qs-new-name" \
        --data "config.rename.querystring=qs2-old-name:qs2-new-name" \
        --data "config.rename.body=param-old:param-new" \
        --data "config.rename.body=param2-old:param2-new" \
        --data "config.add.headers=x-new-header:value" \
        --data "config.add.headers=x-another-header:something" \
        --data "config.add.querystring=new-param:some_value" \
        --data "config.add.querystring=another-param:some_value" \
        --data "config.add.body=new-form-param:some_value" \
        --data "config.add.body=another-form-param:some_value"
    `
- Enabling the plugin on a Route
    `
    $ curl -X POST http://kong:8001/routes/{route}/plugins \
        --data "name=request-transformer"  \
        --data "config.remove.headers=x-toremove" \
        --data "config.remove.headers=x-another-one" \
        --data "config.remove.querystring=qs-old-name:qs-new-name" \
        --data "config.remove.querystring=qs2-old-name:qs2-new-name" \
        --data "config.remove.body=formparam-toremove" \
        --data "config.remove.body=formparam-another-one" \
        --data "config.rename.headers=header-old-name:header-new-name" \
        --data "config.rename.headers=another-old-name:another-new-name" \
        --data "config.rename.querystring=qs-old-name:qs-new-name" \
        --data "config.rename.querystring=qs2-old-name:qs2-new-name" \
        --data "config.rename.body=param-old:param-new" \
        --data "config.rename.body=param2-old:param2-new" \
        --data "config.add.headers=x-new-header:value" \
        --data "config.add.headers=x-another-header:something" \
        --data "config.add.querystring=new-param:some_value" \
        --data "config.add.querystring=another-param:some_value" \
        --data "config.add.body=new-form-param:some_value" \
        --data "config.add.body=another-form-param:some_value"
    `
    - {route} is the id or name of the Route that this plugin configuration will target.



- Enabling the plugin on a Consumer
    `
    $ curl -X POST http://kong:8001/consumers/{consumer}/plugins \
        --data "name=request-transformer" \
        \
        --data "config.remove.headers=x-toremove" \
        --data "config.remove.headers=x-another-one" \
        --data "config.remove.querystring=qs-old-name:qs-new-name" \
        --data "config.remove.querystring=qs2-old-name:qs2-new-name" \
        --data "config.remove.body=formparam-toremove" \
        --data "config.remove.body=formparam-another-one" \
        --data "config.rename.headers=header-old-name:header-new-name" \
        --data "config.rename.headers=another-old-name:another-new-name" \
        --data "config.rename.querystring=qs-old-name:qs-new-name" \
        --data "config.rename.querystring=qs2-old-name:qs2-new-name" \
        --data "config.rename.body=param-old:param-new" \
        --data "config.rename.body=param2-old:param2-new" \
        --data "config.add.headers=x-new-header:value" \
        --data "config.add.headers=x-another-header:something" \
        --data "config.add.querystring=new-param:some_value" \
        --data "config.add.querystring=another-param:some_value" \
        --data "config.add.body=new-form-param:some_value" \
        --data "config.add.body=another-form-param:some_value"
    `
    - {consumer} is the id or username of the Consumer that this plugin configuration will target.
    - You can combine consumer.id and service.id in the same request, to further narrow the scope of the plugin.

- A plugin which is not associated to any Service, Route, or Consumer (or API, if you are using an older version of Kong) is considered "`global`", and will be run on every request. Using a database, all plugins can be configured using the `http://kong:8001/plugins/` endpoint.

- Dynamic Transformation Based on Request Content
The Request Transformer plugin bundled with Kong Enterprise allows for adding or replacing content in the upstream request based on variable data found in the client request, such as request headers, query string parameters, or URI parameters as defined by a URI capture group.

- Order of execution
Plugin performs the response transformation in following order  - `remove –> rename –> replace –> add –> append`  

- Examples 

1. Add multiple headers by passing each header:value pair separately:
    `
    curl -X POST http://localhost:8001/services/example-service/plugins \
    --data "name=request-transformer" \
    --data "config.add.headers[1]=h1:v1" \
    --data "config.add.headers[2]=h2:v1"
    `
    incoming request headers - h1: v1
    upstream proxied headers - h1: v1 , h2: v1

1. Add multiple headers by passing comma separated header:value pair (only possible with a database):  
    `
    $ curl -X POST http://localhost:8001/services/example-service/plugins \
    --data "name=request-transformer" \
    --data "config.add.headers=h1:v1,h2:v2"
    `
1. Add multiple headers passing config as JSON body (only possible with a database):  
    `
    $ curl -X POST http://localhost:8001/services/example-service/plugins \
    --header 'content-type: application/json' \
    --data '{"name": "request-transformer", "config": {"add": {"headers": ["h1:v2", "h2:v1"]}}}'
    `
1. Add a querystring and a header:
    `
    $ curl -X POST http://localhost:8001/services/example-service/plugins \
    --data "name=request-transformer" \
    --data "config.add.querystring=q1:v2,q2:v1" \
    --data "config.add.headers=h1:v1"
    `
1. Append multiple headers and remove a body parameter:
`
$ curl -X POST http://localhost:8001/services/example-service/plugins \
  --header 'content-type: application/json' \
  --data '{"name": "request-transformer", "config": {"append": {"headers": ["h1:v2", "h2:v1"]}, "remove": {"body": ["p1"]}}}
`

### Health Checks
Kong supports multiple types of health checks to identify unhealthy targets on individual Kong nodes.
- Active Checks: Periodically request a specific HTTP or HTTPS endpoint and mark it as healthy or unhealthy based on its response.
- Passive Checks: Analyze proxied traffic on an ongoing basis to determine the health of targets. This method is also known as a circuit breaker.
By actively and passively monitoring the health of targets, you can take remedial action when needed to restore functionality and ensure all nodes in a Kong cluster have access to the endpoints they require.

### Load Balancing
Kong allows load balancing using several different methods:
- A Records: Using an A record containing multiple IP addresses, all entries will be treated equally in a round robin.
- DNS-based: DNS-based load balancing allows backend service registration to occur outside of Kong with periodic updates from the DNS server.
- SRV Records: SRV records can contain IP addresses, port information and weighting, allowing multiple instances of a service to run via different ports on the same IP address.
The last method is particularly useful as the weighting allows the load balancer to adjust individual services according to their weighting, rather than treating them all equally.

---------------------------------------

## ELK stack

### Elastic Search 

1. elasticsearch & kibana  
    Submit a _cat/nodes request to see that the nodes are up and running:
        - ` $ curl -X GET "localhost:9200/_cat/nodes?v&pretty" `

### Logstash 
1. Logstash has two types of configuration files: pipeline configuration files, which define the Logstash processing pipeline, and settings files, which specify options that control Logstash startup and execution.
    - `$ docker run --rm -it -v ./pipeline/:/usr/share/logstash/pipeline/ docker.elastic.co/logstash/logstash:7.5.2`

1. On Unix-like operating systems, the nc command runs Netcat, a utility for sending raw data over a network connection.
   `$ ls | nc localhost 5000`


### Kibana 
1. Kibana has its own API for saved objects, including Index Patterns.
   The following examples are for an Index Pattern with an ID of logstash-*.
   
    ~~~sh
     curl -XPOST -D- 'http://localhost:5601/api/saved_objects/index-pattern' \
    -H 'Content-Type: application/json' \
    -H 'kbn-version: 7.5.2' \
    -d '{"attributes":{"title":"logstash-*","timeFieldName":"@timestamp"}}'
    ~~~
     >reponse

        HTTP/1.1 200 OK
        kbn-name: kibana
        kbn-xpack-sig: 16334c76451733348fa7089edef387f0
        content-type: application/json; charset=utf-8
        cache-control: no-cache
        content-length: 255
        Date: Wed, 22 Jan 2020 08:26:27 GMT
        Connection: keep-alive

        {"type":"index-pattern","id":"e1eaf1f0-3cf0-11ea-9b8c-432d77c94b5d","attributes":{"title":"logstash-*","timeFieldName":"@timestamp"},"references":[],"migrationVersion":{"index-pattern":"6.5.0"},"updated_at":"2020-01-22T08:26:26.830Z","version":"WzMsMV0="}%


### Beats
1. Beats are open source data shippers that you install as agents on your servers to send operational data to Elasticsearch.  
   Elastic provides Beats for capturing: Audit data (Auditbeat), Log files(Filebeat), Cloud data (Functionbeat), Availability(Heartbeat), Systemd journals(Journalbeat), Metrics(Metricbeat), Network traffic(Packetbeat), Windows event logs(Winlogbeat)
1. Beats can send data directly to Elasticsearch or via Logstash, where you can further process and enhance the data, before visualizing it in Kibana.

1. `Filebeat` is part of the Elastic Stack, meaning it works seamlessly with Logstash, Elasticsearch, and Kibana. Whether you want to transform or enrich your logs and files with Logstash, fiddle with some analytics in Elasticsearch, or build and share dashboards in Kibana, Filebeat offers a lightweight way to forward and centralize logs and files.
1. Aggregate, “ tail -f ” & search
   After you start Filebeat, open the Logs UI and watch your files being tailed right in Kibana. Use the search bar to filter by service, app, host, datacenter, or other criteria to track down curious behavior across your aggregated logs.

### Tips for running ELK

1. By default, the stack exposes the following ports:
    - `5000`: Logstash will listen for any TCP input on port 5000
    - `9200`: Elasticsearch for HTTP REST API
    - `9300`: Elasticsearch TCP nodes communication
    - `5601`: Kibana web UI

1. `$ lsof -PiTCP -sTCP:LISTEN`

---------------------  
### Docker Concepts

* Docker is a platform for developers and sysadmins to develop, deploy, and run applications with containers. The use of Linux containers to deploy applications is called containerization. Containers are not new, but their use for easily deploying applications is.

* Containerization is increasingly popular because containers are:
    - Flexible: Even the most complex applications can be containerized.
    - Lightweight: Containers leverage and share the host kernel.
    - Interchangeable: You can deploy updates and upgrades on-the-fly.
    - Portable: You can build locally, deploy to the cloud, and run anywhere.
    - Scalable: You can increase and automatically distribute container replicas.
    - Stackable: You can stack services vertically and on-the-fly.

* Containerization makes Continuous Integration /Continuous Deployment seamless. For example:
    - applications have no system dependencies
    - updates can be pushed to any part of a distributed application 
    - resource density can be optimized.
    With Docker, scaling your application is a matter of spinning up new executables, not running heavy VM hosts.

* Using a script from - get.docker.com in install docker on linux
    * This script is meant for quick & easy install via:
    `$ curl -fsSL https://get.docker.com -o get-docker.sh`
    `$ sh get-docker.sh`
    * Install docker-machine  `docker-compose version`

        docker-compose version 1.23.2, build 1110ad01  
        docker-py version: 3.6.0  
        CPython version: 3.6.6   
        OpenSSL version: OpenSSL 1.1.0h  27 Mar 2018   
* `docker-machine  create —driver`   -- Creates virtual machines with docker built into them          
---    
    
### Image Vs Container
* An image is an executable package that includes everything needed to run an application--the code, a runtime, libraries, environment variables, and configuration files.
* A container is a runtime instance of an image--what the image becomes in memory when executed (that is, an image with state, or a user process). You can see a list of your running containers with the command, `docker ps`, just as you would in Linux.

### Container vs Virtual Machines
* A container runs natively on Linux and shares the kernel of the host machine with other containers. It runs a discrete process, taking no more memory than any other executable, making it lightweight.

* By contrast, a virtual machine (VM) runs a full-blown “guest” operating system with virtual access to host resources through a hypervisor. In general, VMs provide an environment with more resources than most applications need.

* We can have many containers running off the same image  
* Containers 
    * Are not Mini-VMs
    * They are just processes
    * Limited to what resources they can access
    * Exit when process stops  
    Examples  
    `$ docker container run -p 3306:3306 --name mysql_server  --env MYSQL_RANDOM_ROOT_PASSWORD=true -d mysql`  
    `$ docker container run -p 80:80 --name nginx_server -d nginx`  
    `$ docker container run --publish 8080:80 --name httpd_server --detach httpd`


### Services
* Services are really just “containers in production.” A service only runs one image, but it codifies the way that image runs—what ports it should use, how many replicas of the container should run so the service has the capacity it needs, and so on. Scaling a service changes the number of container instances running that piece of software, assigning more computing resources to the service in the process.

* Luckily it’s very easy to define, run, and scale services with the Docker platform -- just write a docker-compose.yml file.
* A docker-compose.yml file is a YAML file that defines how Docker containers should behave in production

---
### Swarm Cluster
* Multi-container, multi-machine applications are made possible by joining multiple machines into a “Dockerized” cluster called a swarm.
* A swarm is a group of machines that are running Docker and joined into a cluster. After that has happened, you continue to run the Docker commands you’re used to, but now they are executed on a cluster by a swarm manager. The machines in a swarm can be physical or virtual. After joining a swarm, they are referred to as nodes.

### Stack
* A stack is a group of interrelated services that share dependencies, and can be orchestrated and scaled together. A single stack is capable of defining and coordinating the functionality of an entire application (though very complex applications may want to use multiple stacks).


---
### CLI Process monitoring : ~ what’s going on in a container
`$ docker container logs mysql_server`  
`$ docker container inspect nginx_server`   
`$ docker container stats <optional container_name>`  

---

### Getting shell to a container (no need of SSH)
`-t : allocate a pseudo tty`  
`-i : interactive `
`$ docker container run -it`    - start a new container interactively  
`$ docker container exec -it`   - run additional command in existing container  

Example:  
`$ docker container run  -it --name quick ubuntu:18.04 bash`    ..  gets a shell   
 
 To install any packages needed, say curl  
    `$ apt-get update`  
    `$ apt-get install curl`  
    `$ curl google.com ` # check if it’s working   
    
Same container with previous installations intact     
`$ docker container start -ai <container_name>`  
`-a, --attach `    Attach STDOUT/STDERR and forward signals  
`-i, --interactive`          Attach container's STDIN   

`$ docker container exec -it mysql_server bash`  
    tip:-> ‘ps’ is no longer available by default, so install after getting a shell to the running container.   
    `$ apt-get update`  
    `$ apt-get install -y procps`  

---
### Docker Networks
 - Each docker container is connected to private virtual network “bridge”
 - Each virtual Network routes through NAT firewall on host IP 
 - Attach containers to more than one virtual network (or none)
 - Skip virtual network & join host’s  
   `$ docker container port <container_name>`    — ports in use  
    80/tcp -> 0.0.0.0:80. 

	`$ docker container inspect --format '{{.NetworkSettings.IPAddress}}' <container_name>`       - ip adds of container                        
	172.17.0.2.  

	`$  ifconfig en0` — Host machine’s ip address  
	en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500   
	ether 8c:85:90:46:82:4a  
	inet6 fe80::2f:d612:d72f:28f8%en0 prefixlen 64 secured scopeid 0x8   
	inet 10.10.15.11 netmask 0xffffff00 broadcast 10.10.15.255  
	nd6 options=201<PERFORMNUD,DAD>   
	media: autoselect   
	status: active  

    tip:-> nginx:latest removed ping   
    so use `docker container run <stuff> nginx:alpine ` instead of nginx:latest

---

### Docker Networks CLI Management

`$ docker network ls`  -- shows networks    
`$ docker network inspect` -- Inspects  
`$ docker network create --driver`  -- create a new virtual network using builtin/3rd party drivers 
`$ docker network connect` -- Attach a network to a container    
dynamically creates a NIC in a container on an existing virtual network     
`$ docker network disconnect `-- Detach a network from a container      
- `bridge` - is the default virtual network which is NATed behind the Host's ip   
`$ docker network inspect bridge`       
    lists containers in the network & subnets...        

- `host` - it gains performance by skipping virtual networks but sacrifices security of container model     

- `none` - removes eth0 and only leaves you with localhost interface in container

- Default Security
    - Create apps so frontend/backend sit on the same Docker network
    - Their inter-communication never leaves host
    - All externally exposed ports are closed by default
    - you must manually expose via -p, which is better default security
    - This gets better with Swarm or Overlay networks

- Example   
    `$ docker network create my_app_net`
    `$ docker network inspect my_app_net`       
    `$ docker container run --name new_webhost --network my_app_net -d  nginx`  -- create a container in a network

    `$ docker network connect my_app_net webhost`       
    `$ docker network disconnect my_app_net webhost`        

---

### DNS : How container find each other 
tip:-> Static IPs & using IPs for talking to containers is an anti-pattern. Avoid it.    
- How DNs is key to easy inter-container communication.          
- how it works by default with custom networks      
- use `--link` to enable DNS on default bridge network, by default it's not. But we can specify list of containers to connect to.
- Docker daemon has a built-in DNS Server that containers use by default
- Docker defaults the host name to container's name. But aliases can be set
- Example
    `$ docker container run -d --name second_webhost --network my_app_net nginx:alpine`
    `$ docker container run -d --name first_webhost --network my_app_net nginx:alpine`
    `$ docker network inspect my_app_net`
    `$ docker container exec -it first_webhost ping second_webhost`
    `$ docker container exec -it second_webhost ping first_webhost`

    tip:-> `$ docker container run --rm -it centos:7 bash`   - `--rm` removes the container on __exit__ from the shell 

### Docker Images
* Image = _App binaries & dependencies_ + _Metadata about the image data and how to run the image._
* Image Layers 
* Images are designed using `Union file system` making layers of changes 

`$ docker history nginx:alpine `   

        IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
        0476319fbdad        2 days ago          /bin/sh -c #(nop)  CMD ["nginx" "-g" "daemon…   0B
        <missing>           2 days ago          /bin/sh -c #(nop)  STOPSIGNAL SIGTERM           0B
        <missing>           2 days ago          /bin/sh -c #(nop)  EXPOSE 80                    0B
        <missing>           2 days ago          /bin/sh -c #(nop) COPY file:ebf4f0eb33621cc0…   1.09kB
        <missing>           2 days ago          /bin/sh -c #(nop) COPY file:4c82b9f10b84c567…   643B
        <missing>           2 days ago          /bin/sh -c GPG_KEYS=B0F4253373F8F6F510D42178…   14.5MB
        <missing>           2 days ago          /bin/sh -c #(nop)  ENV NGINX_VERSION=1.15.10    0B
        <missing>           3 weeks ago         /bin/sh -c #(nop)  LABEL maintainer=NGINX Do…   0B
        <missing>           3 weeks ago         /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B
        <missing>           3 weeks ago         /bin/sh -c #(nop) ADD file:88875982b0512a9d0…   5.53MB
 

* Every layer gets it's unique SHA to distinguish from others
*  `$ docker image inspect nginx:alpine`  - gives the image info in json

* proper tagging of images   
* Tagging images for upload to Docker hub
* How tagging is related to image ID
* latest tag is just a default tag
* Logging into Docker Hub from docker cli - 
`cat .docker/config.json`  - Docker for mac stores this auth in Keychain for better security    
`$ docker image tag nginx ksignk/nginx` - tagging an image      
`$ docker image push ksignk/<image>` - push it to your hub             

### Dockerfile 
* Dockerfile defines what goes on in the environment inside your container. 
* Access to resources like networking interfaces and disk drives is virtualized inside this environment, which is isolated from the rest of your system, so you need to map ports to the outside world, and be specific about what files you want to “copy in” to that environment. 
* However, after doing that, you can expect that the build of your app defined in this Dockerfile behaves exactly the same wherever it runs.


* Package Managers like apt, yum  are one of the reasons to build containers from ubuntu,centOS, Debian or Fedora
* `ENV` - environment variables were chosen as preferred way to inject key/value is they work everywhere on every OS and config

* `RUN` - run shell commands
`&& ` - use chaining to save on layers

* proper way to log inside a con tainer is to not log to a log file. point log file to stdout & stderr. docker handles the logs written to stdout/stderr

* `EXPOSE` - exposes the ports specified to the docker's virtual network. You still need to use `-p` to open/forward ports on host. by default no tcp/udp ports are open for docker containers

* `CMD` - is required parameter . The final command that is run every time when a new container runs from an images or a container is restarts

### Building Images
* `$ docker build -t <name> .`
* when this is run the second time - the un altered lines are not built
* makes use of the cached layers already present. If there's a line that changes, every line after that get's run again
* `WORK_DIR` is preferred to using `RUN cd /some/path'`
* Sometimes we don't have to specify EXPOSE or CMD because they're in  the FROM <image> layer
`$ docker container run -p 80:80 -d --rm nginx`     
`$ docker container run -p 80:80 --rm nginx-with-html:latest`  - check local host to see the default html changing      


### Persistent data
* Container are usually immutable and ephemeral
* immutable infrastructure :  only re-deploy containers, never change
* What about databases or unique data:
    - Two ways to solve : Volumes &  Bind mounts
    - Volumes : make special location outside of container UFS
    - Bind mounts : link container path to host path

* Volumes 
    - `VOLUME` command in Dockerfile
    - Also override with `$ docker run -v /path/in/container`
    - Bypasses Union File system & stores in alt location on host
    - Connect to one or multiple containers at once
    - Not subject to commit, save, or exportcommands
    - By default they only have a unique ID but you can assign name - 'named volume'
    - you can tear down the containers and volumes by running `$ docker-compose down -v`  

* Bind Mounting
    - Maps a host file or directory to a container file or directory
    - Basically just two locations pointing to the same file(s)
    - Again, skips UFS, and host files overwrite any in container 
    - Can't use in Dockerfile, must be at container run     
        - `... run -v /Users/bret/stuff:/path/container`

### Docker Compose



### Docker swarm
* Swarm Mode is a clustering solution built inside Docker
* play-with-docker.com  
    - only needs a browserm, but resets after 4 hours
* Raft database stores the config of the swarm 
* "docker service" in swarm replaces the "docker run" command

* docker-machine + VirtualBox
* Digital Ocean + Docker install    

----
### Docker & DevOps

----
### Misc
    Logo: MobyDock
    Mascot : @gordonTheTurtle
    Batteries Included, But Removable


----
### CheatSheet
----
* List Docker CLI commands      
`$ docker`      
`$ docker container --help`

* Display Docker version and info        
`$ docker --version`        
`$ docker version`      
`$ docker info`     

* Execute Docker image      
`$ docker run hello-world`      

* List Docker images    
`$ docker image ls`     

* List Docker containers (running, all, all in quiet mode)      
`$ docker container ls`     
`$ docker container ls --all`       
`$ docker container ls -aq`


* Add your user to docker group (on linux) to avoid sudo.  
      `sudo usermod -aG docker <username>`
----
* part2
* Note: Accessing the name of the host when inside a container retrieves the container ID, which is like the process ID for a running executable.

~~~docker
    docker build -t friendlyhello .  # Create image using this directory's Dockerfile
    docker run -p 4000:80 friendlyhello  # Run "friendlyhello" mapping port 4000 to 80
    docker run -d -p 4000:80 friendlyhello         # Same thing, but in detached mode
    docker container ls                                # List all running containers
    docker container ls -a             # List all containers, even those not running
    docker container stop <hash>           # Gracefully stop the specified container
    docker container kill <hash>         # Force shutdown of the specified container
    docker container rm <hash>        # Remove specified container from this machine
    docker container rm $(docker container ls -a -q)         # Remove all containers
    docker image ls -a                             # List all images on this machine
    docker image rm <image id>            # Remove specified image from this machine
    docker image rm $(docker image ls -a -q)   # Remove all images from this machine
    docker login             # Log in this CLI session using your Docker credentials
    docker tag <image> username/repository:tag  # Tag <image> for upload to registry
    docker push username/repository:tag            # Upload tagged image to registry
    docker run username/repository:tag                   # Run image from a registry
~~~
----
* part3
~~~docker

docker stack ls                                            # List stacks or apps
docker stack deploy -c <composefile> <appname>  # Run the specified Compose file
docker service ls                 # List running services associated with an app
docker service ps <service>                  # List tasks associated with an app
docker inspect <task or container>                   # Inspect task or container
docker container ls -q                                      # List container IDs
docker stack rm <appname>                             # Tear down an application
docker swarm leave --force      # Take down a single node swarm from the manager

~~~

----
* part4
~~~docker 
docker-machine create --driver virtualbox myvm1 # Create a VM (Mac, Win7, Linux)
docker-machine create -d hyperv --hyperv-virtual-switch "myswitch" myvm1 # Win10
docker-machine env myvm1                # View basic information about your node
docker-machine ssh myvm1 "docker node ls"         # List the nodes in your swarm
docker-machine ssh myvm1 "docker node inspect <node ID>"        # Inspect a node
docker-machine ssh myvm1 "docker swarm join-token -q worker"   # View join token
docker-machine ssh myvm1   # Open an SSH session with the VM; type "exit" to end
docker node ls                # View nodes in swarm (while logged on to manager)
docker-machine ssh myvm2 "docker swarm leave"  # Make the worker leave the swarm
docker-machine ssh myvm1 "docker swarm leave -f" # Make master leave, kill swarm
docker-machine ls # list VMs, asterisk shows which VM this shell is talking to
docker-machine start myvm1            # Start a VM that is currently not running
docker-machine env myvm1      # show environment variables and command for myvm1
eval $(docker-machine env myvm1)         # Mac command to connect shell to myvm1
& "C:\Program Files\Docker\Docker\Resources\bin\docker-machine.exe" env myvm1 | Invoke-Expression   # Windows command to connect shell to myvm1
docker stack deploy -c <file> <app>  # Deploy an app; command shell must be set to talk to manager (myvm1), uses local Compose file
docker-machine scp docker-compose.yml myvm1:~ # Copy file to node's home dir (only required if you use ssh to connect to manager and deploy the app)
docker-machine ssh myvm1 "docker stack deploy -c <file> <app>"   # Deploy an app using ssh (you must have first copied the Compose file to myvm1)
eval $(docker-machine env -u)     # Disconnect shell from VMs, use native docker
docker-machine stop $(docker-machine ls -q)               # Stop all running VMs
docker-machine rm $(docker-machine ls -q) # Delete all VMs and their disk images

~~~

----

### References
1. https://docs.docker.com/compose/compose-file/
1. https://training.play-with-docker.com/docker-volumes/

1. https://12factor.net/
1. https://www.oreilly.com/ideas/3-docker-compose-features-for-improving-team-development-workflow
1. https://www.qemu.org/
1. https://blog.hasura.io/an-exhaustive-guide-to-writing-dockerfiles-for-node-js-web-apps-bbee6bd2f3c/
1. https://github.com/BretFisher/node-docker-good-defaults
1. https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md
1. https://medium.com/@huseinzolkepli/elk-for-flask-bc486d58deb3

- Elastic Search

1. https://www.elastic.co/guide/en/elasticsearch/reference/6.5/deb.html
1. https://www.bogotobogo.com/DevOps/Docker/Docker_ELK_ElasticSearch_Logstash_Kibana.php
1. https://www.elastic.co/guide/en/elastic-stack-get-started/7.1/get-started-elastic-stack.html
1. https://linuxize.com/post/how-to-install-elasticsearch-on-ubuntu-18-04/
1. https://www.elastic.co/guide/en/elasticsearch/reference/7.2/docker.html
1. https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html

- Kong

1. https://docs.konghq.com/install/docker/
1. https://docs.konghq.com/2.0.x/db-less-and-declarative-config/#the-declarative-configuration-format
1. https://medium.com/@matias_azucas/db-less-kong-tutorial-8cbf8f70b266
1. https://docs.konghq.com/0.13.x/configuration/
1. https://discuss.konghq.com/t/rfc-kong-native-declarative-config-format/2719
1. https://docs.konghq.com/hub/kong-inc/request-transformer/#