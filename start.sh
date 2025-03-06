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
    "./monitoring/grafana/dashboards"
    "./monitoring/grafana/provisioning"
    "./monitoring/prometheus"
    "./logs"
    "./data/mongodb"
    "./data/redis"
    "./config"
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
      - targets: ['service-registry:8761', 'mobile-gateway:5000']
EOF
fi

# Build Docker images
echo "Building Docker images..."
services=(
    "service-registry:backend/registry"
    "mobile-gateway:backend/gateway"
)

for service in "${services[@]}"; do
    IFS=':' read -r name path <<< "$service"
    echo "Building $name..."
    docker build -t "$name:latest" -f "$path/Dockerfile" "$path"
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

# Start development environment
echo "Starting development environment..."
docker-compose up -d

# Wait for core services
declare -A services=(
    ["Service Registry"]="http://localhost:8761/health"
    ["Mobile Gateway"]="http://localhost:5000/health"
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