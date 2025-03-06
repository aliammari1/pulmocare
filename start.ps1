#!/usr/bin/env pwsh

# Exit on any error
$ErrorActionPreference = "Stop"

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Function to generate random password
function Get-RandomPassword {
    param(
        [int]$Length = 12
    )
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    return -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Check if Docker is running
$docker = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "Starting Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Start-Sleep -Seconds 30
}

# Check prerequisites
Write-Host "Checking prerequisites..."
$prerequisites = @("docker", "flutter")
foreach ($tool in $prerequisites) {
    if (-not (Test-CommandExists $tool)) {
        Write-Error "Error: $tool is required but not found in PATH"
        exit 1
    }
}

# Check for .env file
if (-not (Test-Path .env)) {
    Write-Host "Creating default .env file..."
    @"
# MongoDB
MONGODB_USERNAME=medapp
MONGODB_PASSWORD=medapppass
MONGODB_DATABASE=medapp
MONGODB_HOST=mongodb
MONGODB_PORT=27017

# RabbitMQ
RABBITMQ_USER=guest
RABBITMQ_PASS=guest

# Redis
REDIS_PASSWORD=

# Grafana
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin
"@ | Out-File -FilePath .env -Encoding UTF8
}

# Create necessary directories
$dirs = @(
    ".\backend\services\xray\models",
    ".\backend\services\knowledge\models",
    ".\backend\services\knowledge\medical_corpus",
    ".\backend\services\knowledge\chroma_db",
    ".\monitoring\grafana\dashboards",
    ".\monitoring\grafana\provisioning",
    ".\monitoring\prometheus",
    ".\logs",
    ".\data\mongodb",
    ".\data\redis",
    ".\config",
    ".\backend\services\xray\logs",
    ".\backend\services\knowledge\logs",
    ".\frontend\build",
    ".\dist"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force
    }
}

# Create Prometheus config if it doesn't exist
if (-not (Test-Path "monitoring/prometheus/prometheus.yml")) {
    Write-Host "Creating Prometheus configuration..."
    @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'services'
    static_configs:
      - targets: ['service-registry:8761', 'mobile-gateway:5000', 'xray-service:8081', 'knowledge-service:8082']
"@ | Out-File -FilePath "monitoring/prometheus/prometheus.yml" -Encoding utf8
}

# Function to check if image exists
function Test-DockerImage {
    param ($imageName)
    return (docker image ls -q $imageName | Measure-Object).Count -gt 0
}

# Function to check if container exists and is running
function Test-DockerContainer {
    param ($containerName)
    $container = docker ps -a --filter "name=$containerName" --format "{{.Status}}"
    return $container -like "Up *"
}

# Build Docker images only if they don't exist
Write-Host "Checking Docker images..."
$services = @(
    @{name="service-registry"; path="backend/registry"},
    @{name="mobile-gateway"; path="backend/gateway"},
    @{name="xray-service"; path="backend/services/xray"},
    @{name="knowledge-service"; path="backend/services/knowledge"}
)

foreach ($service in $services) {
    if (-not (Test-DockerImage "$($service.name):latest")) {
        Write-Host "Building $($service.name)..."
        docker build -t "$($service.name):latest" -f "$($service.path)/Dockerfile" $($service.path)
    } else {
        Write-Host "Image $($service.name):latest already exists, skipping build..."
    }
}

# Build Flutter mobile app
Write-Host "Building Flutter mobile app..."
Push-Location frontend
flutter clean
flutter pub get
flutter build apk --release `
    --dart-define=API_BASE_URL="http://localhost:5000" `
    --dart-define=ENABLE_LOGGING=true

New-Item -ItemType Directory -Force -Path ../dist | Out-Null
Move-Item -Force build/app/outputs/flutter-apk/app-release.apk ../dist/medapp.apk
Pop-Location

# Start development environment if not already running
Write-Host "Checking running containers..."
$needsStart = $false
foreach ($service in $services) {
    if (-not (Test-DockerContainer $service.name)) {
        $needsStart = $true
        break
    }
}

if ($needsStart) {
    Write-Host "Starting development environment..."
    docker-compose up -d
} else {
    Write-Host "All containers are already running..."
}

# Wait for services to be ready
Write-Host "Waiting for services to be ready..."
Start-Sleep -Seconds 30

# Function to check service health
function Test-ServiceHealth {
    param (
        [string]$serviceName,
        [string]$url,
        [int]$maxAttempts = 30,
        [int]$sleepSeconds = 2
    )
    
    Write-Host "Waiting for $serviceName to be ready..."
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "$serviceName is ready!"
                return $true
            }
        }
        catch {
            $attempts++
            if ($attempts -eq $maxAttempts) {
                Write-Host "$serviceName failed to start after $maxAttempts attempts"
                return $false
            }
            Start-Sleep -Seconds $sleepSeconds
        }
    }
    return $false
}

# Wait for core services
$services = @{
    "Service Registry" = "http://localhost:8761/health"
    "Mobile Gateway" = "http://localhost:5000/health"
    "X-Ray Service" = "http://localhost:8081/health"
    "Knowledge Service" = "http://localhost:8082/health"
}

foreach ($service in $services.GetEnumerator()) {
    if (-not (Test-ServiceHealth -serviceName $service.Key -url $service.Value)) {
        Write-Host "Error: $($service.Key) failed to start"
        exit 1
    }
}

# Print access information
Write-Host "`nDeployment complete! Access URLs:"
Write-Host "- Mobile Gateway: http://localhost:5000"
Write-Host "- Service Registry: http://localhost:8761"
Write-Host "- RabbitMQ Management UI: http://localhost:15672 (guest/guest)"
Write-Host "- Prometheus: http://localhost:9090"
Write-Host "- Grafana: http://localhost:3000 (admin/admin)"
Write-Host "- MongoDB: mongodb://localhost:27017 (medapp/medapppass)"
Write-Host "- Flutter dev server: http://localhost:8888"
Write-Host "- Mobile APK: $(Get-Location)/dist/medapp.apk"

# Show logs
Write-Host "`nShowing logs (Ctrl+C to exit)..."
docker-compose logs -f