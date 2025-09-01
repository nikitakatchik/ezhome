# ezhome
#### Simple Homebridge + Zigbee Setup

### Instructions

1. Add `ZIGBEE_SERIAL_PORT` variable to `.env` (`ls /dev/serial/by-id/*igbee*`).
2. Add `ZIGBEE_SERIAL_ADAPTER` variable to `.env` (check [official guidance](https://www.zigbee2mqtt.io/guide/adapters/)).
3. Invoke `docker compose up -d`.
