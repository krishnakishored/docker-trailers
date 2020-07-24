#!/bin/bash

kong migrations bootstrap -v
kong migrations up -v
echo 'Kong migrations complete!'

kong prepare -v -p "/usr/local/kong";

ln -s /usr/local/kong/logs/access.log /var/log/outputs/

# echo "Known peers:"
# dig tasks.kong +short | tee /konwn_peers
# echo "$(wc -l /konwn_peers) peers in total"

echo 'Kong prepare complete!'
