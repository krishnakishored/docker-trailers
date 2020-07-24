#!/bin/sh
# This script checks for DSE service status from the Cluster
#-----------------------------------------------------------------------------
# Get the hostname and set all letters to uppercase
HOSTNAME=$(hostname | /usr/bin/tr '[a-z]' '[A-Z]')

MAILTO="Your_Email_Id@gmail.com"

ipadr=$(/sbin/ifconfig  | grep 'inet'| grep -v '127.0.0.1' | awk 'FNR==2{print $0} ' |awk '{ print $2}')
node_ip=$(hostname -i)
echo "$node_ip"

/etc/init.d/dse status >/logs/dse_status.out
current_status=$( < /logs/dse_status.out)

if [ "$current_status" = 'dse is not running' ]; then
echo "Critical :DSE service is down on $node_ip at $(date)", Please check immediately |mail  -s "Cassandra Database : DSE service is down on $node_ip at $(date)" $MAILTO
else
echo "$node_ip Health is OK!"
fi

# -----------------------------------------------------------------------------
# #!/bin/sh
# # wait-for-cassandra.sh

# set -e
  
# host="$1"
# shift
# cmd="$@"
  
# until PGPASSWORD=$CASSANDRA_PASSWORD cqlsh -h "$host" -U "cassandra" -c '\q'; do
#   >&2 echo "cassandra is unavailable - sleeping"
#   sleep 1cl
# done
  
# >&2 echo "cassandra is up - executing command"
# exec $cmd

