#!/bin/bash

DEPLOY_USER="deploy"
NGINX_USER="www-data"
DEPLOY_HOST="<droplet-public-ip>"
DEPLOY_DIR="/var/www/html"


create_dir() {
    echo "Setting up remote directory..."
    ssh $DEPLOY_USER@$DEPLOY_HOST "
        sudo mkdir -p $DEPLOY_DIR && \
        sudo chown -R $DEPLOY_USER:$NGINX_USER $DEPLOY_DIR && \
        sudo chmod -R 755 $DEPLOY_DIR
    "
}

deploy_static_site() {
    echo "Deploying static site..."
    rsync -avz --delete ./static-site/ $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_DIR
    
    # Set correct permissions after deployment
    ssh $DEPLOY_USER@$DEPLOY_HOST "
        sudo chown -R $DEPLOY_USER:$NGINX_USER $DEPLOY_DIR && \
        sudo chmod -R 755 $DEPLOY_DIR
    "
    
    echo "Static site deployed successfully."
}

create_dir
deploy_static_site
