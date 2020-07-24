ARG BASE_IMAGE=kong:2.0.5-ubuntu

FROM $BASE_IMAGE



## TODO: Dev mode, remove resty-repl from release version
# RUN apk add git\
#    && luarocks install lua-resty-repl

# # if there are any lua custom plugins
# COPY plugins /opt/kong-plugins
# RUN cd /opt/kong-plugins/; \
# 	for plugin in $(ls); do \
# 	(cd $plugin; luarocks make *.rockspec) \
# 	done;

# COPY filebeat ${FILEBEAT_CFG}
# RUN chmod -R go-w ${FILEBEAT_CFG}

# # COPY pre-template /etc/containerpilot.d/pre-template
# COPY post-template /etc/containerpilot.d/post-template
# COPY post-startup /etc/containerpilot.d/post-startup

# COPY config/kong.conf.hcl /etc/consul-template/conf.d/
# COPY config/kong.conf.ctmpl /etc/consul-template/templates/

# COPY config/kong.conf /usr/local/kong/nginx.conf

ENV SERVICE_NAME=kong \
	SERVICE_PORT=8000 \
	SERVICE_CHECK="/usr/bin/curl -fso /dev/null http://localhost:8001/status"

STOPSIGNAL SIGTERM
# Unwrapped container-friendly version of
# CMD ["kong", "start", "-v"]
CMD ["/usr/local/openresty/nginx/sbin/nginx", "-p", "/usr/local/kong/", "-c", "nginx.conf"]
