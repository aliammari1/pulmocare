# Stop all containers including Consul
Write-Host "Stopping all containers..." -ForegroundColor Yellow
docker stop $(docker ps -q --filter "name=medapp-*")

# Remove all containers including Consul
Write-Host "Removing stopped containers..." -ForegroundColor Yellow
docker rm $(docker ps -aq --filter "name=medapp-*")

# Remove Docker network
Write-Host "Removing Docker network..." -ForegroundColor Yellow
docker network rm medapp-network

# Remove Consul data volume
Write-Host "Removing Consul data volume..." -ForegroundColor Yellow
docker volume rm medapp-consul-data

# Remove Docker images if needed
Write-Host "To remove Docker images, run: docker rmi $(docker images -q 'medapp-*')" -ForegroundColor Yellow

Write-Host "Cleanup complete!" -ForegroundColor Green