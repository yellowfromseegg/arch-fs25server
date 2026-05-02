#!/bin/bash
# Alternative setup: download FS25 via SteamCMD instead of the Giants installer.
# Requires STEAM_USER and STEAM_PASS environment variables.
# Set STEAM_GUARD_CODE if Steam Guard (email or authenticator) is enabled on the account.
# The FS25 dedicated server Steam App ID can be overridden with STEAM_APP_ID.

NOCOLOR='\033[0;0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

# App ID for Farming Simulator 25 Dedicated Server on Steam.
# Verify at: https://store.steampowered.com/app/2300320
STEAM_APP_ID="${STEAM_APP_ID:-2300320}"

GAME_DIR="/opt/fs25/game/Farming Simulator 2025"
CONFIG_DIR="/opt/fs25/config/FarmingSimulator2025"

# Validate credentials
if [ -z "$STEAM_USER" ] || [ -z "$STEAM_PASS" ]; then
  echo -e "${RED}ERROR: STEAM_USER and STEAM_PASS must be set as environment variables.${NOCOLOR}"
  echo -e "${YELLOW}Add them to your docker-compose.yml under the 'environment:' section.${NOCOLOR}"
  exec sleep 30
  exit 1
fi

if ! command -v steamcmd &>/dev/null; then
  echo -e "${RED}ERROR: steamcmd not found. The image may not have been built with SteamCMD support.${NOCOLOR}"
  exec sleep 30
  exit 1
fi

echo -e "${GREEN}INFO: Starting FS25 download via SteamCMD (App ID: ${STEAM_APP_ID})...${NOCOLOR}"

if [ -n "$STEAM_GUARD_CODE" ]; then
  echo -e "${YELLOW}INFO: Using provided Steam Guard code.${NOCOLOR}"
else
  echo -e "${YELLOW}INFO: No STEAM_GUARD_CODE set. If your account has Steam Guard enabled you will be prompted below.${NOCOLOR}"
fi

mkdir -p "$GAME_DIR"

# Build SteamCMD argument list
STEAMCMD_ARGS=(
  +force_install_dir "$GAME_DIR"
  +login "$STEAM_USER" "$STEAM_PASS"
)

if [ -n "$STEAM_GUARD_CODE" ]; then
  STEAMCMD_ARGS+=(+set_steam_guard_code "$STEAM_GUARD_CODE")
fi

STEAMCMD_ARGS+=(+app_update "$STEAM_APP_ID" validate +quit)

steamcmd "${STEAMCMD_ARGS[@]}"
STEAMCMD_EXIT=$?

if [ $STEAMCMD_EXIT -ne 0 ]; then
  echo -e "${RED}ERROR: SteamCMD exited with code ${STEAMCMD_EXIT}.${NOCOLOR}"
  echo -e "${YELLOW}Possible causes:${NOCOLOR}"
  echo -e "${YELLOW}  - Wrong credentials (check STEAM_USER / STEAM_PASS)${NOCOLOR}"
  echo -e "${YELLOW}  - Steam Guard code required (set STEAM_GUARD_CODE env var)${NOCOLOR}"
  echo -e "${YELLOW}  - You do not own FS25 on this Steam account${NOCOLOR}"
  echo -e "${YELLOW}  - Wrong App ID (current: ${STEAM_APP_ID}, override with STEAM_APP_ID env var)${NOCOLOR}"
  exec sleep 30
  exit 1
fi

echo -e "${GREEN}INFO: FS25 downloaded successfully via Steam!${NOCOLOR}"

# Copy VERSION file so the server knows which version is installed
if [ -f "$GAME_DIR/VERSION" ]; then
  mkdir -p "$CONFIG_DIR"
  cp "$GAME_DIR/VERSION" "$CONFIG_DIR/"
  echo -e "${GREEN}INFO: VERSION file copied to ${CONFIG_DIR}.${NOCOLOR}"
fi

# Source Wine init and symlinks (same as regular setup)
. /usr/local/bin/wine_init.sh
. /usr/local/bin/wine_symlinks.sh

# Config setup
. /usr/local/bin/copy_server_config.sh

echo -e "${GREEN}INFO: Steam download complete.${NOCOLOR}"
echo -e "${YELLOW}INFO: Next step: the game executable still needs to run once so FS25 generates its license files.${NOCOLOR}"
echo -e "${YELLOW}INFO: Run the regular 'Setup' desktop shortcut to complete server configuration.${NOCOLOR}"

echo -e "${YELLOW}INFO: Closing this window in 30 seconds...${NOCOLOR}"
exec sleep 30
