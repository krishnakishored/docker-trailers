#! /bin/bash -e
sudo yum update -y
sudo yum install java-1.8.0-openjdk -y

file="./kafka_2.11-2.0.0.tgz"
if [ -f "$file" ]
then
	echo "$file found."
else
    curl -o ./kafka_2.11-2.0.0.tgz http://mirrors.ocf.berkeley.edu/apache/kafka/2.0.0/kafka_2.11-2.0.0.tgz
    tar xzvf ./kafka_2.11-2.0.0.tgz
    sudo mv ./kafka_2.11-2.0.0 /opt/kafka
fi

sudo cp ./kafka*.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable kafka-zookeeper
sudo systemctl start kafka-zookeeper

sudo systemctl enable kafka
sudo systemctl start kafka
