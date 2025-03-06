#!/bin/bash
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check service health
check_service_health() {
    local service_name=$1
    local url=$2
    local max_attempts=${3:-30}
    local sleep_seconds=${4:-2}
    local attempts=0

    echo "Waiting for $service_name to be ready..."
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -s -f "$url" > /dev/null; then
            echo "$service_name is ready!"
            return 0
        fi
        
        attempts=$((attempts + 1))
        if [ $attempts -eq $max_attempts ]; then
            echo "$service_name failed to start after $max_attempts attempts"
            return 1
        fi
        sleep $sleep_seconds
    done
    return 1
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Check prerequisites
echo "Checking prerequisites..."
prerequisites=("docker" "docker-compose" "flutter")
for tool in "${prerequisites[@]}"; do
    if ! command_exists "$tool"; then
        echo "Error: $tool is required but not found in PATH"
        exit 1
    fi
done

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating default .env file..."
    cat > .env << EOF
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
EOF
fi

# Create necessary directories
dirs=(
    "./backend/services/xray/models"
    "./backend/services/knowledge/models"
    "./backend/services/knowledge/medical_corpus"
    "./backend/services/knowledge/chroma_db"
    "./monitoring/grafana/dashboards"
    "./monitoring/grafana/provisioning"
    "./monitoring/prometheus"
    "./logs"
    "./data/mongodb"
    "./data/redis"
    "./config"
    "./backend/services/xray/logs"
    "./backend/services/knowledge/logs"
    "./frontend/build"
    "./dist"
)

for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Create Prometheus config if it doesn't exist
if [ ! -f "monitoring/prometheus/prometheus.yml" ]; then
    echo "Creating Prometheus configuration..."
    cat > monitoring/prometheus/prometheus.yml << EOF
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
EOF
fi

# Function to check if Docker image exists
image_exists() {
    docker image inspect "$1" >/dev/null 2>&1
}

# Build Docker images only if they don't exist
echo "Checking Docker images..."
services=(
    "service-registry:backend/registry"
    "mobile-gateway:backend/gateway"
    "xray-service:backend/services/xray"
    "knowledge-service:backend/services/knowledge"
)

for service in "${services[@]}"; do
    IFS=':' read -r name path <<< "$service"
    if ! image_exists "$name:latest"; then
        echo "Building $name..."
        docker build -t "$name:latest" -f "$path/Dockerfile" "$path"
    else
        echo "Image $name:latest already exists, skipping build..."
    fi
done

# Build Flutter mobile app
echo "Building Flutter mobile app..."
pushd frontend
flutter clean
flutter pub get
flutter build apk --release \
    --dart-define=API_BASE_URL="http://localhost:5000" \
    --dart-define=ENABLE_LOGGING=true

mkdir -p ../dist
mv build/app/outputs/flutter-apk/app-release.apk ../dist/medapp.apk
popd

# Check if containers are running
containers_running() {
    for service in "$@"; do
        if ! docker ps --filter "name=$service" --filter "status=running" --format "{{.Names}}" | grep -q "^$service$"; then
            return 1
        fi
    done
    return 0
}

if ! containers_running "service-registry" "mobile-gateway" "xray-service" "knowledge-service"; then
    echo "Starting development environment..."
    docker-compose up -d
else
    echo "All containers are already running..."
fi

# Wait for services
echo "Waiting for services to be ready..."
sleep 30

# Wait for core services
declare -A services=(
    ["Service Registry"]="http://localhost:8761/health"
    ["Mobile Gateway"]="http://localhost:5000/health"
    ["X-Ray Service"]="http://localhost:8081/health"
    ["Knowledge Service"]="http://localhost:8082/health"
)

for service in "${!services[@]}"; do
    if ! check_service_health "$service" "${services[$service]}"; then
        echo "Error: $service failed to start"
        exit 1
    fi
done

# Print access information
echo -e "\nDeployment complete! Access URLs:"
echo "- Mobile Gateway: http://localhost:5000"
echo "- Service Registry: http://localhost:8761"
echo "- RabbitMQ Management UI: http://localhost:15672 (guest/guest)"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- MongoDB: mongodb://localhost:27017 (medapp/medapppass)"
echo "- Flutter dev server: http://localhost:8888"
echo "- Mobile APK: $(pwd)/dist/medapp.apk"

# Show logs
echo -e "\nShowing logs (Ctrl+C to exit)..."
docker-compose logs -f