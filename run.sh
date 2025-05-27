#!/bin/bash

# File is good for iterating on docker build and inspection

docker build . -t nest-graph

# On my machine, port 3000 is already used... your mileage may vary
container_id=$(docker run -d -p 4242:4242 -p 3001:3000 --restart unless-stopped -v /opt/nestdata:/data nest-graph)

docker ps

# Comment these out if you just want to build
docker exec -it ${container_id} /bin/bash
docker kill ${container_id}
docker ps
