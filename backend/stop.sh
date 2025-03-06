#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Stop all containers including Consul
echo -e "${YELLOW}Stopping all containers...${NC}"
docker stop $(docker ps -q --filter "name=medapp-*")

# Remove all containers including Consul
echo -e "${YELLOW}Removing stopped containers...${NC}"
docker rm $(docker ps -aq --filter "name=medapp-*")

# Remove Docker network
echo -e "${YELLOW}Removing Docker network...${NC}"
docker network rm medapp-network

# Remove Consul data volume
echo -e "${YELLOW}Removing Consul data volume...${NC}"
docker volume rm medapp-consul-data

# Remove Docker images if needed
echo -e "${YELLOW}To remove Docker images, run: docker rmi \$(docker images -q 'medapp-*')${NC}"

echo -e "${GREEN}Cleanup complete!${NC}"