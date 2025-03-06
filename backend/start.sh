#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create Docker network if it doesn't exist
echo -e "${GREEN}Setting up Docker network...${NC}"
docker network create medapp-network 2>/dev/null

# Create Docker volumes for persistence
echo -e "${GREEN}Creating Docker volumes...${NC}"
docker volume create medapp-consul-data

# Function to build and start a service
start_docker_service() {
    local service_path=$1
    local service_name=$2
    
    echo -e "${GREEN}Building and starting $service_name...${NC}"
    docker build -t "medapp-$service_name" "$service_path"
    docker run -d --name "medapp-$service_name" \
        --network medapp-network \
        -e CONSUL_HOST=medapp-consul \
        -e CONSUL_PORT=8500 \
        -e CONSUL_HTTP_TOKEN=medapp-token \
        "medapp-$service_name"
}

# Start Consul first
echo -e "${GREEN}Starting Consul...${NC}"
docker run -d --name medapp-consul \
    --network medapp-network \
    -v medapp-consul-data:/consul/data \
    -e CONSUL_BIND_INTERFACE=eth0 \
    -e CONSUL_CLIENT_INTERFACE=eth0 \
    -e 'CONSUL_LOCAL_CONFIG={"acl": {"enabled": true, "default_policy": "deny", "tokens": {"master": "medapp-token"}}}' \
    -p 8500:8500 \
    -p 8600:8600/udp \
    consul:1.15.4 agent -server -bootstrap-expect=1 -ui -client=0.0.0.0

# Wait for Consul to be ready
echo -e "${YELLOW}Waiting for Consul to be ready...${NC}"
sleep 10

# Start Registry Service
echo -e "${GREEN}Starting Registry Service...${NC}"
docker build -t medapp-registry "./registry"
docker run -d --name medapp-registry \
    --network medapp-network \
    -e CONSUL_HOST=medapp-consul \
    -e CONSUL_PORT=8500 \
    -e CONSUL_HTTP_TOKEN=medapp-token \
    -p 8761:8761 medapp-registry

# Wait for Registry to be up
echo -e "${YELLOW}Waiting for Registry to be ready...${NC}"
sleep 10

# Start Gateway Service
echo -e "${GREEN}Starting Gateway Service...${NC}"
docker build -t medapp-gateway "./gateway"
docker run -d --name medapp-gateway \
    --network medapp-network \
    -e CONSUL_HOST=medapp-consul \
    -e CONSUL_PORT=8500 \
    -e CONSUL_HTTP_TOKEN=medapp-token \
    -p 8000:8000 medapp-gateway

# Define services
declare -A services
services=(
    ["knowledge"]="services/knowledge"
    ["medecins"]="services/medecins"
    ["ordonnances"]="services/ordonnances"
    ["patients"]="services/patients"
    ["radiologue"]="services/radiologue"
    ["reports"]="services/reports"
    ["xray"]="services/xray"
)

# Start all other services
for service_name in "${!services[@]}"; do
    start_docker_service "${services[$service_name]}" "$service_name"
    sleep 2
done

echo -e "${GREEN}All services started!${NC}"
echo -e "${YELLOW}To stop all services, run: docker stop \$(docker ps -q)${NC}"
echo -e "${YELLOW}To view logs of a service, run: docker logs <container-name>${NC}"
echo -e "${GREEN}Gateway is available at http://localhost:8000${NC}"
echo -e "${GREEN}Consul UI is available at http://localhost:8500${NC}"
echo -e "${GREEN}Consul ACL Token: medapp-token${NC}"

# Keep the script running and show containers status
while true; do
    clear
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    sleep 5
done