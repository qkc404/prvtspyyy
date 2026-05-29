#!/bin/bash

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; BLUE='\033[1;34m'
MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

loading() {
    local text="$1"
    local spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0; i<5; i++)); do
        for ((j=0; j<${#spin}; j++)); do
            echo -ne "\r${CYAN}${spin:$j:1} ${text}...${RESET}"
            sleep 0.05
        done
    done
    echo -ne "\r${GREEN}DONE: ${text}${RESET}\n"
}

center_text() {
    local text="$1"
    local cols=$(tput cols)
    local clean=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#clean}
    local pad=$(( (cols - len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%${pad}s%s\n" "" "$text"
}

clear

center_text "${BOLD}${WHITE}VLESS FAST DEPLOYER${RESET}"
center_text "${MAGENTA}MADE BY SAEKA TOJIRP${RESET}"
center_text "${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
center_text "${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"
echo ""

read -r -p "$(echo -e "${CYAN}SERVICE NAME [vless]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-vless}

echo ""
center_text "${CYAN}SELECT PERFORMANCE:${RESET}"
center_text "${YELLOW}1) 1 vCPU / 2Gi RAM${RESET}"
center_text "${YELLOW}2) 2 vCPU / 4Gi RAM${RESET}"
center_text "${YELLOW}3) 4 vCPU / 8Gi RAM${RESET}"
echo ""
read -r -p "$(echo -e "${CYAN}CHOICE [2]: ${RESET}")" PAIR_CHOICE

case "$PAIR_CHOICE" in
    1) CPU="1"; RAM="2Gi" ;;
    3) CPU="4"; RAM="8Gi" ;;
    *) CPU="2"; RAM="4Gi" ;;
esac

echo ""
loading "BUILDING IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" . --quiet > build.log 2>&1
if [ $? -ne 0 ]; then
    center_text "${RED}BUILD FAILED${RESET}"
    tail -n 10 build.log
    exit 1
fi

loading "DEPLOYING TO CLOUD RUN"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed \
  --region us-central1 \
  --cpu "$CPU" \
  --memory "$RAM" \
  --port 8080 \
  --concurrency 1000 \
  --cpu-boost \
  --no-cpu-throttling \
  --timeout 3600 \
  --min-instances 1 \
  --max-instances 4 \
  --allow-unauthenticated \
  --quiet > deploy.log 2>&1

if [ $? -ne 0 ]; then
    center_text "${RED}DEPLOYMENT FAILED${RESET}"
    tail -n 10 deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region us-central1 --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

echo ""
center_text "${GREEN}DEPLOYED SUCCESSFULLY${RESET}"
echo ""
center_text "${CYAN}HOST     ${GREEN}${CLEAN_HOST}${RESET}"
center_text "${CYAN}PORT     ${GREEN}443${RESET}"
center_text "${CYAN}UUID     ${GREEN}saeka${RESET}"
center_text "${CYAN}PATH     ${GREEN}/saeka-vless${RESET}"
center_text "${CYAN}NETWORK  ${GREEN}ws${RESET}"
center_text "${CYAN}SECURITY ${GREEN}tls${RESET}"

rm -f build.log deploy.log
