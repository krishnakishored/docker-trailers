A simple Hello World app written in Node.js (Express).

Contains Dockerfiles for Development (with Hot Reloading) and Production.

Build and run using any dockerfile:

$ docker build -f [dockerfile] -t node-docker .
$ docker run --rm -it -p 8080:8080 node-docker

1. Simple Dockerfile Example
    ~~~sh
    
    ➜  docker build -f 1.node-simple.Dockerfile -t node-docker-dev .
    ➜  docker run --rm -it -p 8080:8080 node-docker-dev 
    ➜  curl -X GET http://localhost:8080
    Hello World
    ~~~

1. Hot Reloading with Nodemon
    * All edits in theappdirectory will trigger a rebuild and changes will be available live at http://localhost:8080. Note that we have mounted the files into the container so that nodemon can actually work.

    ~~~sh
    ➜  docker build -f 2.node-hot-reload-nodemon.Dockerfile -t node-docker-dev:latest .
    
    ➜  docker run --rm -it -p 8080:8080 -v $(pwd):/app node-docker-dev bash 
    
    root@12de7663d59e:/app# ls
    root@12de7663d59e:/app# nodemon src/server.js 
       
    ~~~


1. Optimizations
    * In your Dockerfile, prefer COPY over ADD unless you are trying to add auto-extracting tar files, according to Docker’s best practices.
    * Bypass package.json ‘s start command and bake it directly into the image itself. 
      So use `$ CMD ["node","server.js"]` instead of `$ CMD ["npm","start"]` in your Dockerfile CMD. 
      This reduces the number of processes running inside the container and it also causes exit signals such as SIGTERM and SIGINT to be received by the Node.js process instead of npm swallowing them.
    * You can also use the `--init` flag to wrap your Node.js process with a lightweight init system, which will respond to Kernel Signals like SIGTERM (CTRL-C) etc. For example, `$ docker run --rm -it --init -p 8080:8080 -v $(pwd):/app node-docker-dev bash`     

1. Serving Static Files
    * using the npm package `serve` to serve static files. Assuming you are building a UI app using React/Vue/Angular, you would ideally build your final bundle using`npm run build` which would generate a minified JS and CSS file.
    * The other alternative is to either 1) build the files locally and use an nginx docker to serve these static files or 2) via a CI/CD pipleline.    

1. Single Stage Production Build
    * The image built will be ~700MB (depending on your source code), due to the underlying Debian layer. 

    ~~~sh
        ➜  docker build -f 5.single-stage-prod-build.Dockerfile -t node-docker-dev:latest .             
        ➜  docker run --rm -it -p 8080:8080 -v $(pwd):/app node-docker-dev    
    ~~~

1. Multi Stage Production build
    * With multi stage builds, you use multiple FROM statements in your Dockerfile but the final build stage will be the one used, which will ideally be a tiny production image with only the exact dependencies required for a production server.
    * With the above, the image built with Alpine comes to around ~70MB, a 10X reduction in size. The alpine variant is usually a very safe choice to reduce image sizes.
    
    ~~~sh
         ➜  docker build -f 6.multi-stage-prod-build.Dockerfile -t node-docker-dev:latest .  
         ➜  docker run --rm -it -p 8080:8080 -v $(pwd):/app node-docker-dev   
    ~~~
