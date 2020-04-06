FROM kong:1.5.1-ubuntu

# COPY kong.yml /

# to configure kong, the kong.conf file should be stored on directory /etc/kong (the directory where kong searches for it’s configuration).
RUN cp /etc/kong/kong.conf.default /etc/kong/kong.conf 

# ---------------------------------------------------------------
# FROM kong:latest  
# this image has write permission issues while copying