FROM docker.elastic.co/logstash/logstash:7.2.0

RUN rm -f /usr/share/logstash/pipeline/logstash.conf
COPY pipeline /usr/share/logstash/pipeline/