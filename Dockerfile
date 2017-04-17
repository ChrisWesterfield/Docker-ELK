FROM alpine:latest

# Update image and install base packages
RUN apk update && \
    apk upgrade && \
    apk add bash curl openjdk8 openssl supervisor nodejs git && \
    mkdir /logs && \
    mkdir /data

#Install Elastic Search
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.zip > /elastic.zip && \
	cd / && \
	unzip elastic.zip && \
	mv /elasticsearch-5.3.0 /elasticsearch && \
	rm /elastic.zip && \
	mkdir /logs/elasticsearch && \
	mkdir /data/elasticsearch && \
	mv /elasticsearch/config/elasticsearch.yml /elasticsearch/config/elasticsearch.ymml.dist && \
	adduser -D -u 1000 -h /elasticsearch elasticsearch && \
	chown -R elasticsearch:elasticsearch /elasticsearch/ /logs/elasticsearch /data/elasticsearch && \
	cd / && \
	git clone https://github.com/mobz/elasticsearch-head.git /elasticsearchHead  && \
	cd /elasticsearchHead && \
	npm install

COPY ./config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

#Install Kibana
RUN curl https://artifacts.elastic.co/downloads/kibana/kibana-5.3.0-linux-x86_64.tar.gz > /kibana.tgz && \
	tar -xzf kibana.tgz && \
	mv /kibana-5.3.0-linux-x86_64 /kibana && \
	adduser -D -u 1001 -h /kibana kibana && \
	mkdir /logs/kibana && \
	chown -R kibana:kibana /kibana /logs/kibana && \
	rm -rf /kibana/node/ && \
	mkdir -p /kibana/node/bin && \
	ln -s /usr/bin/node /kibana/node/bin/node

#Install Logstash
RUN curl https://artifacts.elastic.co/downloads/logstash/logstash-5.3.0.tar.gz > /logstash.tgz && \
	cd / && \
	tar -xzf logstash.tgz && \
	mv /logstash-5.3.0 /logstash && \
	mkdir /logstash/etc && \
	mkdir /logs/logstash 



#Configure SuperVisor
RUN mkdir /etc/supervisor.d/ && \
	mv /etc/supervisord.conf /etc/supervisord.conf.dist
COPY ./config/supervisor/elasticsearch.ini /etc/supervisor.d/elasticsearch.ini
COPY ./config/supervisor/supervisord.conf /etc/supervisord.conf
COPY ./config/supervisor/elasticsearchHead.ini /etc/supervisor.d/elasticsearchHead.ini
COPY ./config/supervisor/kibana.ini /etc/supervisor.d/kibana.ini
COPY ./config/supervisor/logstash.ini /etc/supervisor.d/logstash.ini

RUN apk del --purge curl git && \
    rm -rf /var/cache/apk/*

EXPOSE 9100 9200 9300 5000

VOLUME "/data"

CMD ["/usr/bin/supervisord"]