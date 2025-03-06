# Create Docker network if it doesn't exist
Write-Host "Setting up Docker network..." -ForegroundColor Green
docker network create medapp-network 2>$null

# Create Docker volumes for persistence
Write-Host "Creating Docker volumes..." -ForegroundColor Green
docker volume create medapp-consul-data

# Function to build and start a service
function Start-DockerService {
    param(
        [string]$servicePath,
        [string]$serviceName
    )
    
    Write-Host "Building and starting $serviceName..." -ForegroundColor Green
    docker build -t "medapp-$serviceName" "$servicePath"
    docker run -d --name "medapp-$serviceName" `
        --network medapp-network `
        -e CONSUL_HOST=medapp-consul `
        -e CONSUL_PORT=8500 `
        -e CONSUL_HTTP_TOKEN=medapp-token `
        "medapp-$serviceName"
}

# Start Consul first
Write-Host "Starting Consul..." -ForegroundColor Green
docker run -d --name medapp-consul `
    --network medapp-network `
    -v medapp-consul-data:/consul/data `
    -e CONSUL_BIND_INTERFACE=eth0 `
    -e CONSUL_CLIENT_INTERFACE=eth0 `
    -e 'CONSUL_LOCAL_CONFIG={"acl": {"enabled": true, "default_policy": "deny", "tokens": {"master": "medapp-token"}}}' `
    -p 8500:8500 `
    -p 8600:8600/udp `
    consul:1.15.4 agent -server -bootstrap-expect=1 -ui -client=0.0.0.0

# Wait for Consul to be ready
Write-Host "Waiting for Consul to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Start Registry Service
Write-Host "Starting Registry Service..." -ForegroundColor Green
docker build -t medapp-registry "./registry"
docker run -d --name medapp-registry `
    --network medapp-network `
    -e CONSUL_HOST=medapp-consul `
    -e CONSUL_PORT=8500 `
    -e CONSUL_HTTP_TOKEN=medapp-token `
    -p 8761:8761 medapp-registry

# Wait for Registry to be up
Write-Host "Waiting for Registry to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Start Gateway Service
Write-Host "Starting Gateway Service..." -ForegroundColor Green
docker build -t medapp-gateway "./gateway"
docker run -d --name medapp-gateway `
    --network medapp-network `
    -e CONSUL_HOST=medapp-consul `
    -e CONSUL_PORT=8500 `
    -e CONSUL_HTTP_TOKEN=medapp-token `
    -p 8000:8000 medapp-gateway

# Start all other services
$services = @{
    "knowledge" = "services/knowledge"
    "medecins" = "services/medecins"
    "ordonnances" = "services/ordonnances"
    "patients" = "services/patients"
    "radiologue" = "services/radiologue"
    "reports" = "services/reports"
    "xray" = "services/xray"
}

foreach ($serviceName in $services.Keys) {
    Start-DockerService -servicePath $services[$serviceName] -serviceName $serviceName
    Start-Sleep -Seconds 2
}

Write-Host "All services started!" -ForegroundColor Green
Write-Host "To stop all services, run: docker stop $(docker ps -q)" -ForegroundColor Yellow
Write-Host "To view logs of a service, run: docker logs <container-name>" -ForegroundColor Yellow
Write-Host "Gateway is available at http://localhost:8000" -ForegroundColor Green
Write-Host "Consul UI is available at http://localhost:8500" -ForegroundColor Green
Write-Host "Consul ACL Token: medapp-token" -ForegroundColor Green

# Keep the script running and show containers status
while ($true) {
    Clear-Host
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Start-Sleep -Seconds 5
}