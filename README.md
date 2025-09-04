# ezhome
#### Simple Homebridge + Zigbee Setup

### Instructions

1. Add the following variables to `.env` in the same directory as `docker-compose.yml`
```bash
ZIGBEE_AUTH_TOKEN=${YOUR_WEB_ACCESS_PASSWORD}
ZIGBEE_SERIAL_ADAPTER=${ZIGBEE_ADAPTER} # check official guidance https://www.zigbee2mqtt.io/guide/adapters
ZIGBEE_SERIAL_PORT=/dev/serial/by-id/${ZIGBEE_DEVICE}
```

2. Invoke `docker compose up -d`.

Homebridge will be available at `http://${DOCKER_HOST}:8581`.

Zigbee2MQTT will be available at `http://${DOCKER_HOST}:8080`.
