#!/bin/bash
#
# build-images - build the images for res http lab, remove the conatiners associated
#		 and previous images before build
#
# usage: build-images
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

# Remove any existing image
images=$(docker images -f "reference=res/apache_php" -f "reference=res/express_animals" -f "reference=res/apache_rp" --format "{{.Repository}}")
if [ ! -z "$images" ]
then
	echo "These images have been removed:"
	for i in $images
        do
                docker rmi "$i"
        done
        echo ""
fi

# Build the images
docker build -t res/apache_php ../docker-images/apache-php-image/
docker build -t res/express_animals ../docker-images/express-image/
docker build -t res/apache_rp ../docker-images/apache-reverse-proxy/
