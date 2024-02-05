#!/bin/bash
docker volume create shared
# O que for colocado dentro desta pasta, aparecerá dentro do container
mkdir /var/lib/docker/volumes/shared/_data/codes
docker volume create portainer_data
docker run -itd --name compiler -v shared:/codes --workdir /codes dnredson/p4c
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

