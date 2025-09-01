#!/bin/env bash
set -euo pipefail

HB_PREFIX="${HB_PREFIX:-/homebridge}"
HB_Z2M_MQTT_USER="${HB_Z2M_MQTT_USER:-}"
HB_Z2M_MQTT_PASS="${HB_Z2M_MQTT_PASS:-}"

CONFIG_PATH="${HB_PREFIX}/config.json"

# Ensure config file exists with minimal structure (don’t touch if it already exists)
if [ ! -f "${CONFIG_PATH}" ]; then
  cat > "${CONFIG_PATH}" <<'JSON'
{
  "bridge": {
    "name": "Homebridge",
    "username": "CC:22:3D:E3:CE:30",
    "port": 51826,
    "pin": "031-45-154"
  },
  "accessories": [],
  "platforms": []
}
JSON
fi

# Make sure platforms array exists
if ! jq -e 'has("platforms") and (.platforms|type=="array")' "${CONFIG_PATH}" >/dev/null; then
  tmp="$(mktemp)"
  jq '.platforms = []' "${CONFIG_PATH}" > "${tmp}" && mv "${tmp}" "${CONFIG_PATH}"
fi

# Non-destructive merge for the z2m platform
HB_Z2M_CLEAR_CREDS="${HB_Z2M_CLEAR_CREDS:-false}"

tmp="$(mktemp)"
jq \
  --arg server "${HB_Z2M_MQTT_URL}" \
  --arg base   "${HB_Z2M_BASE_TOPIC}" \
  --arg user   "${HB_Z2M_MQTT_USER}" \
  --arg pass   "${HB_Z2M_MQTT_PASS}" \
  --arg clear  "${HB_Z2M_CLEAR_CREDS}" '
  # Ensure platforms array exists
  (.platforms //= []) |

  # If zigbee2mqtt exists, edit in place; otherwise append a minimal one
  .platforms = (
    if (.platforms | map(.platform) | index("zigbee2mqtt")) != null then
      .platforms
      | map(
          if .platform == "zigbee2mqtt" then
            .mqtt = (.mqtt // {}) |
            .mqtt.server = $server |
            .mqtt.base_topic = $base |
            # username/password: set if provided; optionally clear if requested
            (if ($user != "") then (.mqtt.username = $user)
             elif ($clear == "true") then (del(.mqtt.username))
             else . end) |
            (if ($pass != "") then (.mqtt.password = $pass)
             elif ($clear == "true") then (del(.mqtt.password))
             else . end)
          else . end
        )
    else
      .platforms + [
        {
          platform: "zigbee2mqtt",
          mqtt: (
            { server: $server, base_topic: $base } +
            (if $user != "" then { username: $user } else {} end) +
            (if $pass != "" then { password: $pass } else {} end)
          )
        }
      ]
    end
  )
' "${CONFIG_PATH}" > "${tmp}" && mv "${tmp}" "${CONFIG_PATH}"

HB_Z2M_NAME="${HB_Z2M_NAME:-homebridge-z2m}"
HB_Z2M_VERSION="${HB_Z2M_VERSION:-latest}"

is_plugin_installed() {
  # 1) Prefer npm’s dependency graph (works when package.json exists)
  if npm ls --prefix "${HB_PREFIX}" --depth=0 --json ${HB_Z2M_NAME} 2>/dev/null \
      | jq -e '.dependencies["${HB_Z2M_NAME}"].version? != null' >/dev/null; then
    return 0
  fi

  # 2) Fallback: resolve via Node module loader (works even without package.json)
  NODE_PATH="${HB_PREFIX}/node_modules" node -e '
    try { require.resolve("${HB_Z2M_NAME}/package.json"); process.exit(0); }
    catch (e) { process.exit(1); }
  ' >/dev/null 2>&1
}

# Ensure plugin is present
if ! is_plugin_installed; then
  echo "[entrypoint] Installing ${HB_Z2M_NAME}@${HB_Z2M_VERSION}."
  npm install --unsafe-perm --no-audit --no-fund --no-package-lock \
    --prefix "${HB_PREFIX}" "${HB_Z2M_NAME}@${HB_Z2M_VERSION}"
fi

# Hand off to the original image init
exec /init
