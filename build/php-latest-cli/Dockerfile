FROM manhphucofficial/php:latest-cli

RUN apt-get update -y

# Node and yarn
RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash -
RUN apt-get -y install nodejs
RUN npm install -g yarn

# Mysql 5.7
RUN apt-get -y install mysql-client-5.7 php-apc