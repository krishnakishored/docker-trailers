### Amazon ELB(elastic load balancer)
* allows you to make your applications highly available by using health checks and distributing traffic across a number of instances.

* To launch a larger instance like an m5-large in place of t2-micro is called vertical scaling when you replace an instance with a more powerful instance. This Isn't always economical

* Another approach can be to use a bunch of smaller instances like t2-micros and distribute the website traffic between them. And Elastic Load Balancer allows you to do just that.
    - It distributes incoming application or network traffic across multiple targets, such as Amazon EC2 instances, containers, and IP addresses, in multiple Availability Zones.
    - It uses health checks to detect which instances are healthy and directs traffic only across those instances.

1. Classic Load Balancer (CLB)
- Once configured, it distributes the load across all the registered instances regardless of what is present on the servers. Hence, it can only be used to distribute traffic to a single URL.
* Classic Load Balancer provides basic load balancing across multiple Amazon EC2 instances and operates at both the request level and connection level. Classic Load Balancer is intended for applications that were built within the EC2-Classic network.

2. Application Load Balancer (ALB)
* This load balancer is specially designed for web applications with HTTP and HTTPS traffic.
  There is a networking model called the OSI Model (Open Systems Interconnection) that is used to explain how computer networks work. This model has 7 layers and the top layer is the Application Layer. This load balancer works at this Application Layer, hence the name.

* It also provides advanced routing features such as host-based and path-based routing and also works with containers and microservices.
    - Host-based Routing
        Suppose you have two websites medium.com and admin.medium.com. Each website is hosted on two EC2 instances for high availability and you want to distribute the incoming web traffic between them.
        If you were using the CLB you would have to create two load balancers, one for each website.
        But you can do the same thing using a single ALB! Hence you will be saving money as you will only be paying for a single ALB instead of two CLBs.

    - Path-based Routing
        Suppose the website of your company is payzello.com and the company’s blog is hosted on payzello.com/blog. The operations team has decided to host the main website and the blog on different instances.
        Using ALB you can route traffic based on the path of the requested URL. So again a single ALB is enough to handle this for you.

3. Network Load Balancer (NLB)
* This load balancer operates at the Network layer of the OSI model, hence the name.
    Suppose your company’s website is running on four m4-xlarge instances and you are using an ALB to distribute the traffic among them.
    Now your company launched a new product today which got viral and your website starts to get millions of requests per second.
    In this case, the ALB may not be able to handle the sudden spike in traffic. This is where the NLB really shines. 
* NLB has the capability to handle a sudden spike in traffic since it works at the connection level.
* It also provides support for static IPs.


### OSI(Open Systems Interconnection) Model
* The OSI model categorizes the various operations that are involved in getting a network communication from one computer program on one machine to another computer program on another machine.

- 7. Application  ----- ALB (Application Load Balancer)   
- 6. Presentation 
- 5. Session
- 4. Transport ----- NLB (Network Load Balancer) 
- 3. Network
- 2. Datalink
- 1. Physical






### References:
* https://medium.com/containers-on-aws/using-aws-application-load-balancer-and-network-load-balancer-with-ec2-container-service-d0cb0b1d5ae5


























