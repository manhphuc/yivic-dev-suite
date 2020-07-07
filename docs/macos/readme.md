# Check for prerequisites
All requisites should be available for your distribution. The most important are:

* [Git] (https://git-scm.com/downloads)
* [Docker] (https://docs.docker.com/engine/installation/)
* [Docker Compose] (https://docs.docker.com/compose/install/)

# Installation
- Clone and download the project to your working directory:

```
$ git clone https://github.com/manhphuc/yivic-dev-suite
```

- Go to the working directory:

```
$ cd yivic-dev-suite
```

The current working folder will be `yivic-dev-suite`. After all the prerequisites have been installed, run the following commands to start the installation of docker images.
  - This command will check if there’s .env file, if there is not, it will init and generate an .env file. Then you can repair values that need to be updated located on your based folder.

```
$ sh scripts/init-env-file.sh
```

  - When environment variables have been updated, we will generate the `docker-compose.yml` and configuration files (Nginx conf - How to modify Nginx conf can be found [here](#set-up-custom-domain)).

```
$ sh scripts/init-dev-suite.sh
```

  - Then download and bring up all the containers by the following command:

```
$ docker-compose up -d --build
```

- Wait for several mins and you'll have:
  - Nginx (work as a webserver)
  - PHP-FPM (PHP execution server)
  - MySql
  - Phpmyadmin
- When it finishes downloading, we can check the list of all services by the command:

```
$ docker-compose ps
```

# Modify document root directory
Firstly, create two files called `index.html` and `info.php` within folder `<path-to-document-root-directory>` and input the content:
- index.html

```
<h1>Webserver works</h1>
```

- info.php

```
<?php echo phpinfo();
```

Later on, if your web page works, these contents will be shown.

We have to modify the configuration for the `default.conf` file of Nginx container before launching. (View more details [here](#set-up-custom-domain))

# Set up custom domain
Before launching the web page, the configurations for the `default.conf` file of Nginx container need to be modified.
- Create a file called `default.conf` from sample `default.conf.example` with folder `etc/nginx` to repair document root. Each site will have its own Ngixn conf file.
    - As what we have in `default.conf`, where php74 is a container in dev suite, according to that, path for $php_fpm_document_root should be path on that php74 and the root is path to file of the Nginx instance. 
    - We are using Nginx from docker container then the path should be path to file inside that nginx_main container.
    - In addition, `default.conf` is a file, which has root path is the `yivic-dev-suite` folder, mapped from local machine to docker container. As we replaced the actual data folders in `docker-compose.yml` file, remember to put the right directory which is alias in docker:

```
"${WWW_DIR}:/var/www/html"
```

 - `${WWW_DIR}` : is your actual directory of the root folder, which is set in .env file.
 - `:/var/www/html` : this is the directory reflected by docker in which it will operate in.
 - So the `/var/www/html/` will be the path to `index.html` files on docker.

- Later on, if you want to add configuration for other sites, simply create another conf file for each site and put it into folder `etc/nginx/sites-enabled`.
  - Create a file called `sample.conf` from `sample.conf.example` within folder `etc/nginx/sites-enabled` to make changes for document root.
  - This is similar to the `default.conf` case, but we have to add the other domain site to `server_name` section as well as its root directory, which should be path to file inside the nginx_main containter.
  - There is a line saying `include /etc/nginx/conf.d/sites-enabled/*.conf;` in `default.conf` means that all configuration files within /etc/nginx/sites-enabled will be included for the process of nginx.
  
- Then check and restart nginx with the following commands to take effect what modified: 

```
$ docker exec -it nginx_main nginx -t 
$ docker exec -it nginx_main nginx -s reload
```

- If it still does not work, run:

```
$ docker-compose down
``` 

to turn off the docker for checking changes on your params, if there’s any problem and docker can not turn off all of its service, restart docker program on your machine and run it again by:

```
$ docker-compose up -d 
```

- Check the nginx container if it is running by the command:

```
$ docker-compose ps nginx_main
```

- The information of the container will be shown with its state as __“UP”__.

- If its state is shown as __“EXIT”__, that means there is error that Nginx could not be started and we should check the log to see the cause.

```
$ docker-compose logs nginx_main
```

- To see the logs, usually, errors come from configuration and you can change the configs in `etc/nginx/default.conf`  or `*.conf` in `etc/nginx/sites-enabled` (because we will include all *.conf in that folder to our nginx config).

# Assign your domain to localhost IP
Open `/etc/hosts` then add your domain to localhost:

```
127.0.0.1 your-domain-name.example
```

Save & exit
- Now test your domains on the browser `http://your-domain-name.example:${NGINX_HTTP_EXPOSING_PORT}` and `https://your-domain-name.example:${NGINX_HTTPS_EXPOSING_PORT}`, you should see the content of file `index.html` shown. 

- Or `http://your-domain-name.example:${NGINX_HTTP_EXPOSING_PORT}/info.php` and `https://your-domain-name.example:${NGINX_HTTPS_EXPOSING_PORT}/info.php` to check if the `info.php` file works also.

*** Note: Since we have declared 2 variables for ${NGINX_HTTP_EXPOSING_PORT} and ${NGINX_HTTPS_EXPOSING_PORT} in .env file, so to access to the http and https of the web page, these ports should be added to the URL too.

# Set up Mysql Database and Phpmyadmin
- MySQL is the database system used for the website. We have installed __mysql57__, __mysql57_slave__, __mysql80__ and __mysql80_slave__ so that one of these containers can be used, others are for later, when we want to have replication.
- In the .env file, the database name, root password (using with root user of local machine), mysql user and password of these mysql containers are set, which we can use to log in through the Phpmyadmin.
- Phpmyadmin is intended to handle the administration of MySQL over the Web. We can use one of these mysql information declared in `docker-compose.yml` to log in through Phpmyadmin page: `your-domain-name.example:${PHPMYADMIN_WEB_EXPOSING_PORT}` and `your-domain-name.example:{PHPMYADMIN_SLAVE_WEB_EXPOSING_PORT}`.
- But since the mysql container as well as its database can be deleted once we stop and restart the docker, it's better to use the mysql from the local machine. In this case, the server named `host.docker.internal` is used to mapped to local database.
- After log in, we can create a database for the website and manage it.

*** Note: This case is similar to Nginx port, the ${PHPMYADMIN_WEB_EXPOSING_PORT} and ${PHPMYADMIN_SLAVE_WEB_EXPOSING_PORT} have been set in the .env file, so one of these ports should be added to the URL too.

# Troubleshooting
 ### 1. Nginx is running but not pointing to correct root directory
- You may encounter 404, 504 or your browser showing wrong contents when you direct to the domain name. There are two steps to check this error:
  - Open the error log file (you created in the nginx conf file) to check the error notification.
  - Check if you alias the directories correctly by reviewing your local directories and container’s directories. If the alias is set correctly, the files you put in your root folder locally should automatically appear in the root folder of the container. 
    - For example, you’ve put the `index.html` inside `~/workspace/www/`, and in the `docker-compose.yml`, you created an alias from local root to `/var/www/html` inside the container. Hence, the file data should appear in the `/var/www/html` of the container.

    - Go through the container by the following command:

```
$ docker exec -it nginx_main sh
cd /var/www/
ls 
```

If you cannot find the `index.html`, then either recheck the alias you created in the `docker-compose.yml` or stop all containers from `yivic-dev-suite` and start them again to see if the changes take place.

### 2. Port is allocated
- Whenever you restart your machine, or bring up the docker, some default ports would be allocated by other services which leads to error of the progress of docker and the error is like `Port is already allocated` is showing up. Some default ports would be 80, 443... In this case, we can just simply restart the Docker.
If the error is still there after restarting, we could check which service is running on that port by the following command:

```
$ lsof -nP -i4TCP:$PORT | grep LISTEN      
```

- Remember to replace $PORT with the allocated port.
- By doing this, a list of the services using the port will be shown. And we can modify and remove the service based on that.
