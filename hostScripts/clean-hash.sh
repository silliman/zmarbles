#!/bin/bash

# Clear out marbles app hash
HASH='"last_startup_hash": ""'
cd ${ZMARBLES_HOME}
sed -i '12d' marblesUI/config/marbles1.json
sed -i '12d' marblesUI/config/marbles2.json
sed -i '12i\    '"${HASH}" marblesUI/config/marbles1.json
sed -i '12i\    '"${HASH}" marblesUI/config/marbles2.json
#pkill -f 'node app.js'

