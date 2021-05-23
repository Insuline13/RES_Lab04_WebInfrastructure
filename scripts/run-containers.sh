#!/bin/bash
#
# run-containers - run the containers for res http lab, remove the containers associated before
#		 - images must be built before
#
# usage: run-containers
#
# Miguel Do Vale Lopes 23.05.2021
#

# Kill any associated container
run_containers=$(docker ps -f "ancestor=res/apache_php" -f "ancestor=res/express_animals" -f "ancestor=res/apache_rp" --format "{{.Names}}")
if [ ! -z "$run_containers" ]
then
	echo "These containers have been stopped:"
	for run_c in $run_containers
	do
        	docker kill "$run_c"
	done
	echo ""
fi

# Remove any associated container
containers=$(docker ps -a -f "ancestor=res/apache_php" -f "ancestor=res/express_animals" -f "ancestor=res/apache_rp" --format "{{.Names}}")
if [ ! -z "$containers" ]
then
        echo "Thesse containers have been removed:"
        for c in $containers
        do
                docker rm "$c"
        done
	echo ""
fi

# Run the containers
echo "Running container..."
docker run -d --name static_1 res/apache_php
docker run -d --name static_2 res/apache_php
docker run -d --name dynamic_1 res/express_animals
docker run -d --name dynamic_2 res/express_animals

ip_static_1=$(bash ./container-ip.sh static_1)
ip_static_2=$(bash ./container-ip.sh static_2)
ip_dynamic_1=$(bash ./container-ip.sh dynamic_1)
ip_dynamic_2=$(bash ./container-ip.sh dynamic_2)

docker run -d --name apache_rp -e STATIC_APP_1="${ip_static_1}:80" -e STATIC_APP_2="${ip_static_2}:80" -e DYNAMIC_APP_1="${ip_dynamic_1}:3000" -e DYNAMIC_APP_2="${ip_dynamic_2}:3000" -p 8080:80 res/apache_rp
