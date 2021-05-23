# RES Lab04 WebInfrastructure

Autheurs: Alexandra Cerottini & Miguel Do Vale Lopes

Date: 22.05.2021

## Step 1: Static HTTP server with apache httpd

Nous avons premièrement créé les dossiers `docker-images/apache-php-image`  et implémenté notre configuration Docker dans le dossier `apache-php-image`.

Nous avons choisi l'image Docker qui nous permet d'utiliser un serveur apache httpd. Il s'agit de l'image [php](https://hub.docker.com/_/php) et plus exactement `php:7.2-apache`. 

Un Dockerfile a ensuite été créé avec cette image.

```dockerfile
FROM php:7.2-apache

COPY src/ /var/www/html/
```

La commande COPY permet de copier le contenu du dossier src dans le dossier `/var/www/html` à l'intérieur du container. Le dossier src contient un [template bootstrap](https://startbootstrap.com/theme/grayscale) utilisé comme site web statique.

Pour lancer ce container, il suffit de build l'image depuis l'emplacement du Dockerfile avec la commande: `docker build -t res/apache_php .` puis de le run avec `docker run -p 9090:80 res/apache_php`. Nous pouvons maintenant voir le résultat en ouvrant une page web et en allant sur `localhost:9090`. 

Les fichiers de configuration d'apache dans le container se trouvent dans le dossier `/etc/apache2/`.



## Step 2: Dynamic HTTP server with express.js

Nous avons premièrement créé le dossier `express-image` dans le dossier `docker-images`.

Nous avons choisi l'image Docker qui nous permet d'utiliser `node.js` pour notre application web dynamique. Il s'agit de l'image [node](https://hub.docker.com/_/node) et plus exactement: `node:14.17`.

Un Dockerfile a ensuite été créé avec cette image.

```dockerfile
FROM node:14.17

COPY src/ /opt/app

CMD ["node","/opt/app/index.js"]
```

La commande `CMD` permet d'exécuter notre script lors du lancement du container.

Le dossier `src` est également copié et contient un fichier `index.js`. Ce fichier permet de générer une liste d'animaux avec leur race, nom, genre et date de naissance. Pour générer du contenu random, le module chance a été utilisé. Il a fallu l'ajouter à l'aide de la commande `npm install --save chance`. Les requêtes sont faites à l'aide du module express qu'il a aussi fallu ajouter.

Pour lancer ce container, il suffit de build l'image depuis l'emplacement du Dockerfile avec la commande: `docker build -t res/express_animals .` puis de le run avec `docker run -p 3000:3000 res/express_animals`. Nous pouvons maintenant voir le résultat en ouvrant une page web et en allant sur `localhost:3030`. 



## Step 3: Reverse proxy with apache (static configuration)

Nous avons premièrement créé le dossier `apache-reverse-proxy` dans le dossier `docker-images`.

Nous avons choisi l'image Docker qui nous permet d'utiliser un serveur apache httpd. Il s'agit de l'image [php](https://hub.docker.com/_/php) et plus exactement `php:7.4-apache` (nous avions premièrement utilisé l'image `php:7.2-apache` mais elle a du être changé lors de la step 5).

Un Dockerfile a ensuite été créé avec cette image.

```dockerfile
FROM php:7.4-apache

COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```

La commande `RUN` permet de lancer les scripts `a2enmod` (enable un module) et `a2ensite` (activer des sites).

Le dossier `conf` est également copié et contient la configuration du reverse proxy.

Pour tester cette configuration, il faut tout d'abord modifier le fichier `etc/hosts` et y ajouter la ligne `127.0.0.1   demo.res.ch` (sur Linux).

Ensuite, il faut exécuter ces diverses commandes qui permettront de lancer les containers:

```Dock
Dans le dossier docker-images/apache-php-image:
docker build -t res/apache_php .

Dans le dossier docker-images/express-image:
docker build -t res/express_animals .

Dans le dossier docker-images/apache-reverse-proxy:
docker build -t res/apache_rp .

Pour lancer les containers:
docker run -d --name apache_static res/apache_php
docker run -d --name express_dynamic res/express_animals
docker run --name apache_rp -p 8080:80 res/apache_rp
```

Nous pouvons maintenant voir le résultat du site statique en ouvrant une page web et en allant sur `demo.res.ch:8080`. Pour voir le résultat du serveur HTTP dynamique, il faut aller sur `demo.res.ch:8080/api/animals/`.

Les serveurs statique et dynamique peuvent être atteint directement dans notre implémentation car nous nous trouvons sur Linux. En effet, Docker est installé directement sur notre machine. Les réseaux Docker nous sont donc directement accessibles. Nous pouvons accéder au serveur statique en tapant `http://172.17.0.2` et au serveur dynamique en tapant `http://172.17.0.3:3000` sur un navigateur web.

Le problème dans cette configuration est que nous devons regarder les adresses IP attribuées aux containers statique et dynamique (avec la commande `docker inspect <nom_container> | grep -i ipaddr`). Ils doivent ensuite être ajoutés dans le fichier `001-reverse-proxy.conf` comme ceci :

```
<VirtualHost *:80>
    ServerName demo.res.ch

	#ErrorLog ${APACHE_LOG_DIR}/error.log
	#CustomLog ${APACHE_LOG_DIR}/access.log combined

	ProxyPass "/api/students/" "http://172.17.0.3:3000/"
	ProxyPassReverse "/api/students/" "http://172.17.0.3:3000/"

	ProxyPass "/" "http://172.17.0.2:80/"
	ProxyPassReverse "/" "http://172.17.0.2:80"    
</VirtualHost>
```



## Step 4: AJAX requests with JQuery

Les trois Dockerfile ont été modifié pour installer nano qui nous permettra d'éditer des fichiers directement dans le container. Cette commande a donc été ajoutée: `RUN apt-get update && apt install nano`.

Dans cette étape, un script `animals.js` a été ajouté dans le dossier `docker-images/apache-php-image/src/js`. Ce script nous permet périodiquement de faire une requête HTTP en arrière plan sans recharger toute la page. Pour ce faire, nous avons utiliser [jQuery](https://api.jquery.com/jquery.getJSON/).  Nous avons également modifié le fichier index.html du dossier `docker-images/apache-php-image/src/` pour qu'il appelle notre script animals.js.

Pour tester cette configuration, il faut rebuild les trois images que nous avions créée précédemment et relancer les containers en veillant bien à ce qu'ils aient la même adresse IP qu'auparavant.

Lorsque nous sommes sur le `site demo.res.ch:8080`, nous pouvons voir les requêtes Ajax en appuyant sur la touche `f12`.

Tout ceci ne fonctionnerait pas sans un reverse proxy car un mécanisme de sécurité se prénommant "Same-origin policy" a été spécifié pour prévenir certaines attaques. Cette politique nous dit qu'un script qui est exécuté et qui vient d'un certain nom de domaine, ne peut faire des requêtes que vers le même nom de domaine. Si on travaillait directement avec les adresses IP, on ne pourrait pas envoyer une requête AJAX sur les deux containers car ils n'ont pas la même adresse. Pour éviter ce problème, on met en place un reverse proxy qui agit comme un point d'entrée unique avec un nom DNS (demo.res.ch).



## Step 5: Dynamic reverse proxy configuration

Dans cette étape, nous avons remplacé la configuration statique par une configuration dynamique en définissant des variables d'environnement au lancement du container. Nous avons dû ajouter dans le dossier `apache-reverse-proxy` un fichier `apache2-foreground` que nous avons récupéré sur le [git](https://github.com/docker-library/php/tree/master/7.4/buster/apache) de php puis nous y avons ajouté notre setup:

```
# Add setup for RES lab

echo "Setup for the RES lab..."
echo "Static app URL: $STATIC_APP"
echo "Dynamic app URL: $DYNAMIC_APP"
php /var/apache2/templates/config-template.php > /etc/apache2/sites-available/001-reverse-proxy.conf
```

On a aussi créé un dossier `conf` contenant le fichier config-template.php qui a remplacé la configuration statique du proxy. Un fichier config est ainsi généré au lancement du container en remplaçant dynamiquement les adresses IP par les variables d'envrionnement. 

```php
<?php
	$dynamic_app = getenv('DYNAMIC_APP');
	$static_app = getenv('STATIC_APP');
?>
<VirtualHost *:80>
    ServerName demo.res.ch  
				        
	ProxyPass '/api/animals/' 'http://<?php print "$dynamic_app"?>/'
	ProxyPassReverse '/api/animals/' 'http://<?php print "$dynamic_app"?>/'
	     
	ProxyPass '/' 'http://<?php print "$static_app"?>/'
	ProxyPassReverse '/' 'http://<?php print "$static_app"?>/'
</VirtualHost>
```

Pour ce faire, nous avons ajouté cette commande dans le Dockerfile: `COPY apache2-foreground /usr/local/bin/` et  `COPY template/ /var/apache2/templates`. 

Pour démarrer le container, il faut rebuild l'image et le lancer avec la commande `docker run -e STATIC_APP <adresse_ip1> -e DYNAMIC_APP <adresse_ip2> res/apache_rp`.



## Step 6: Load balancing: multiple server nodes

Nous avons trouvé de la documentation sur un module [mod_proxy_balancer](https://httpd.apache.org/docs/2.4/mod/mod_proxy_balancer.html) sur le site d'Apache et nous l'avons implémenté.

Pour ce faire, nous avons modifié le fichier `config-template.php` qui se trouve dans le dossier `docker_images/apache-reverse-proxy/` pour permettre l'ajout de deux autres variables d'envrionnements et pour implémenter le proxy balancer:

```php
<?php
  $dynamic_app_1 = getenv('DYNAMIC_APP_1');
  $dynamic_app_2 = getenv('DYNAMIC_APP_2');

  $static_app_1 = getenv('STATIC_APP_1');
  $static_app_2 = getenv('STATIC_APP_2');
?>

<VirtualHost *:80>

    ServerName demo.res.ch
    
    <Location /balancer-manager>
      SetHandler balancer-manager
    </Location>
    ProxyPass /balancer-manager !

    <Proxy "balancer://dynamic">
	    BalancerMember "http://<?php print "$dynamic_app_1"?>"
	    BalancerMember "http://<?php print "$dynamic_app_2"?>"
	</Proxy>

    
    <Proxy "balancer://static">
	    BalancerMember "http://<?php print "$static_app_1"?>"
	    BalancerMember "http://<?php print "$static_app_2"?>"
	</Proxy>

    ProxyPass "/api/animals/" "balancer://dynamic/"
    ProxyPassReverse "/api/animals/" 'balancer://dynamic/"

    ProxyPass "/" "balancer://static/"
    ProxyPassReverse "/" "balancer://static/"

</VirtualHost>
```

Nous avons également modifié le Dockerfile en ajoutant à la commande `RUN a2enmod` le mode `proxy_balancer` et le mode `lbmethod=byrequests`. En effet, pour utiliser le mode proxy_balancer, il faut que le mode proxy soit activé (déjà fait auparavant), le mode proxy_balancer et un module d'algorithme. Nous avons donc choisi le module `lbmethod_byrequest` comme algorithme.

Pour valider cette procédure, nous avons au préalable démarré deux containers statiques et deux containers dynamiques. Nous avons ensuite dû rebuild l'image puis lancer le container à nouveau avec la commande: `docker run -d -e STATIC_APP_1=172.17.0.2:80 -e STATIC_APP_2=172.17.0.3:80 -e DYNAMIC_APP_1=172.17.0.4:3000 -e DYNAMIC_APP_2=172.17.0.5:3000 --name apache_rp -p 8080:80 res/apache_rp`. 

Nous avons ensuite ouvert le balance-manager que nous avons ajouté dans le config-template.php. Pour l'ouvrir il suffit de taper `demo.res.ch:8080/balance-manager`. Nous tuons ensuite un container statique et un container dynamique et nous regardons si le site est toujours fonctionnel et si les charges ont été placées sur un seul serveur grâce au balance-manager.



## Step 7: Load balancing: round-robin vs sticky sessions

Pour cette étape, nous avons modifié le fichier `config-template.php` qui se trouve dans le dossier `docker_images/apache-reverse-proxy/` pour implémenter le round-robin et les sticky sessions:

```php
<?php
  $dynamic_app_1 = getenv('DYNAMIC_APP_1');
  $dynamic_app_2 = getenv('DYNAMIC_APP_2');

  $static_app_1 = getenv('STATIC_APP_1');
  $static_app_2 = getenv('STATIC_APP_2');
?>

<VirtualHost *:80>

    ServerName demo.res.ch
    
    <Location /balancer-manager>
      SetHandler balancer-manager
    </Location>
    ProxyPass /balancer-manager !

    <Proxy "balancer://dynamic">
	    BalancerMember "http://<?php print "$dynamic_app_1"?>"
	    BalancerMember "http://<?php print "$dynamic_app_2"?>"
	    ProxySet lbmethod=byrequests
    </Proxy>

    Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
    <Proxy "balancer://static">
	    BalancerMember "http://<?php print "$static_app_1"?>" route=1
	    BalancerMember "http://<?php print "$static_app_2"?>" route=2
	    ProxySet stickysession=ROUTEID
    </Proxy>

    ProxyPass "/api/animals/" "balancer://dynamic/"
    ProxyPassReverse "/api/animals/" 'balancer://dynamic/"

    ProxyPass "/" "balancer://static/"
    ProxyPassReverse "/" "balancer://static/"

</VirtualHost>
```

Nous avons également modifié le Dockerfile pour ajouter l'option `headers` à la commande `RUN a2enmod...`. 

Pour valider cette procédure, nous avons au préalable démarré deux containers statiques et deux containers dynamiques. Nous avons ensuite dû rebuild l'image puis lancer le container à nouveau avec la commande: `docker run -d -e STATIC_APP_1=172.17.0.2:80 -e STATIC_APP_2=172.17.0.3:80 -e DYNAMIC_APP_1=172.17.0.4:3000 -e DYNAMIC_APP_2=172.17.0.5:3000 --name apache_rp -p 8080:80 res/apache_rp`. 

Pour vérifier le round-robin, nous allons sur notre balance-manager (`demo.res.ch:8080/balance-manager` sur un navigateur) et nous regardons le "LoadBalancer Status for balancer://dynamic ..." et nous cherchons la case "Elected". Nous pouvons voir que le compteur augmente de manière alternée entre les deux serveurs lorsque l'on rafraichit la page du load balancer régulièrement. Si nous tuons un serveur dynamique, nous pouvons voir que seulement le compteur du serveur dynamique restant augmentera.

Pour vérifier le sticky session, nous allons sur notre balance-manager (`demo.res.ch:8080/balance-manager` sur un navigateur) et nous regardons le "LoadBalancer Status for balancer://static ..." et nous cherchons la case "StickySession". Nous voyons que ROUTEID y est écrit alors qu'auparavant la case comportait la mention (None).



## Step 9: Management UI

Pour cette étape, nous avons décidé d'utiliser [Portainer](https://documentation.portainer.io/v2.0/deploy/ceinstalldocker/) sur Docker. Pour ce faire, si l'utilisateur se trouve sur Linux, il lui suffit d'exécuter les commandes suivantes:

```
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
```

Il faut ensuite aller sur `localhost:9090` pour manager ses containers. Lors de la première connexion, il est demandé de choisir un mot de passe pour le compte admin. Il faut ensuite cliquer sur "Gérer l'envrionnement docker local" pour accéder à notre infrastructure.

Pour valider cette procédure, nous avons éteint puis rallumé un container Docker depuis l'interface tout en vérifiant entre deux sur un terminal en faisant un `docker ps` que le container n'apparaissait plus puis qu'il réapparaissait par la suite.