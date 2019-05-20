# Docker Tutorial notes


---    
### Docker Concepts

* Docker is a platform for developers and sysadmins to develop, deploy, and run applications with containers. The use of Linux containers to deploy applications is called containerization. Containers are not new, but their use for easily deploying applications is.

* Containerization is increasingly popular because containers are:
- Flexible: Even the most complex applications can be containerized.
- Lightweight: Containers leverage and share the host kernel.
- Interchangeable: You can deploy updates and upgrades on-the-fly.
- Portable: You can build locally, deploy to the cloud, and run anywhere.
- Scalable: You can increase and automatically distribute container replicas.
- Stackable: You can stack services vertically and on-the-fly.

* Add your user to docker group (on linux) to avoid sudo.  
      `sudo usermod -aG docker <username>`
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

* Package Managers like apt, yum  are one of the reasons to build containers from ubuntu,centOS, Debian or Fedora
* `ENV` - environment variables were chosen as preferred way to inject key/value is they work everywherer on every OS and config

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

* Bind Mounting
    - Maps a host file or directory to a container file or directory
    - Basically just two locations pointing to the same file(s)
    - Again, skips UFS, and host files overwrite any in container 
    - Can't use in Dockerfile, must be at container run     
        - `... run -v /Users/bret/stuff:/path/container`

### Docker Compose


### Docker swarm
* play-with-docker.com  
    - only needs a browserm, but resets after 4 hours

* docker-machine + VirtualBox
* Digital Ocean + Docker install    

### Misc
    Logo: MobyDock
    Mascot : @gordonTheTurtle
    Batteries Included, But Removable


