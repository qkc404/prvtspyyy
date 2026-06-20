#!/bin/bash

# ==========================================
# ADVANCED 404 NOT FOUND DEPLOYER - GCP NATIVE
# ==========================================

BOLD='\033[1m'
RESET='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
GRAY='\033[1;30m'

clear

echo ""
echo -e "  ${BOLD}${WHITE}╭────────────────────────────────────────╮${RESET}"
echo -e "  ${BOLD}${WHITE}│        PRVTSPYYY DEPLOYER (GEN 2)      │${RESET}"
echo -e "  ${BOLD}${WHITE}╰────────────────────────────────────────╯${RESET}"
echo -e "   ${MAGENTA}  DEVELOPED BY SAEKA TOJIRP${RESET}"
echo -e "   ${GREEN}  fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${RED}✖ ERROR: No active GCP project found.${RESET}"
    echo -e "  Please run: ${CYAN}gcloud config set project [YOUR_PROJECT_ID]${RESET}"
    exit 1
fi
echo -e "  ${CYAN}[INIT]${RESET} ACTIVE PROJECT : ${GREEN}${PROJECT_ID}${RESET}"
echo ""

read -r -p "$(echo -e "  ${CYAN}➜ Enter Service Name [default: saeka]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-saeka}

echo ""
echo -e "  ${CYAN}➜ SELECT HARDWARE PROFILE:${RESET}"
echo -e "    ${YELLOW}1)${RESET} BROWSING     ${GRAY}(1 vCPU / 2Gi RAM)${RESET}"
echo -e "    ${YELLOW}2)${RESET} STREAMING    ${GRAY}(2 vCPU / 4Gi RAM)${RESET}"
echo -e "    ${YELLOW}3)${RESET} GAMING       ${GRAY}(4 vCPU / 8Gi RAM)${RESET}"
echo -e "    ${YELLOW}4)${RESET} ULTRA        ${GRAY}(8 vCPU / 16Gi RAM)${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}➜ CHOICE [default: 4]: ${RESET}")" MODE_CHOICE

case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MODE="BROWSING"; MAX_INSTANCES="4";;
    2) CPU="2"; RAM="4Gi"; MODE="STREAMING"; MAX_INSTANCES="4";;
    3) CPU="4"; RAM="8Gi"; MODE="GAMING"; MAX_INSTANCES="4";;
    *) CPU="8"; RAM="16Gi"; MODE="ULTRA"; MAX_INSTANCES="2";;
esac

echo ""
echo -e "  ${CYAN}➜ SELECTED PROFILE: ${GREEN}${MODE} (${CPU} vCPU / ${RAM})${RESET}"
echo ""

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "  ${CYAN}[RUNNING] %c  %s${RESET}" "$spinstr" "$2"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "  ${GREEN}[SUCCESS] ✔  %s${RESET}\n" "$2"
}

echo -e "  ${MAGENTA}▶ STAGE 1: COMPILING CONTAINER IMAGE${RESET}"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --project="$PROJECT_ID" --quiet > build.log 2>&1 &
BUILD_PID=$!
spinner $BUILD_PID "Building to gcr.io/${PROJECT_ID}/${SERVICE_NAME}..."

wait $BUILD_PID
if [ $? -ne 0 ]; then 
    echo -e "  ${RED}✖ BUILD FAILED. Printing recent logs:${RESET}"
    tail -n 15 build.log
    exit 1
fi

echo ""

echo -e "  ${MAGENTA}▶ STAGE 2: DEPLOYING TO CLOUD RUN (GEN 2)${RESET}"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region us-central1 \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 1000 --cpu-boost --no-cpu-throttling \
  --timeout 3600 --min-instances 1 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" --quiet > deploy.log 2>&1 &
DEPLOY_PID=$!
spinner $DEPLOY_PID "Deploying service ${SERVICE_NAME} to us-central1..."

wait $DEPLOY_PID
if [ $? -ne 0 ]; then 
    echo -e "  ${RED}✖ DEPLOYMENT FAILED. Printing recent logs:${RESET}"
    tail -n 15 deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region us-central1 --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

echo ""
echo -e "  ${BOLD}${GREEN}╭────────────────────────────────────────╮${RESET}"
echo -e "  ${BOLD}${GREEN}│      DEPLOYMENT FULLY SUCCESSFUL       │${RESET}"
echo -e "  ${BOLD}${GREEN}╰────────────────────────────────────────╯${RESET}"
echo ""
echo -e "  ${CYAN}▶ URL/HOST  : ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}▶ PORT      : ${GREEN}443${RESET}"
echo -e "  ${CYAN}▶ PASSWORD  : ${GREEN}saeka${RESET}"
echo -e "  ${CYAN}▶ PROTOCOLS : ${GREEN}VLESS / VMESS / TROJAN / SS${RESET}"
echo -e "  ${CYAN}▶ TRANSPORTS: ${GREEN}WS / HTTPUpgrade / XHTTP${RESET}"
echo ""
echo -e "  ${CYAN}▶ PROFILE   : ${YELLOW}${MODE}${RESET}"
echo -e "  ${CYAN}▶ RESOURCES : ${YELLOW}${CPU} vCPU / ${RAM} RAM${RESET}"
echo ""
echo -e "  ${GRAY}Logs saved to: build.log and deploy.log${RESET}"
echo ""
