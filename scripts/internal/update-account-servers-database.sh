#!/usr/bin/env bash

# shellcheck source=./framework.sh
source "$(dirname "$(realpath "$0")")/framework.sh"
parse_arguments "$@"

create_server_script=$(cat "$git_base_dir/scripts/run-in-container/update-account-servers-database.js")

if [[ ! -f "$git_base_dir/.env" ]]; then
    print_error "Missing .env file. Did you run setup-environment.sh?"
    exit 1
fi
source "$git_base_dir/.env"

necessary_environment_files=("friends" "miiverse-api" "wiiu-chat" "super-mario-maker" "pokemon-gen7")
for environment in "${necessary_environment_files[@]}"; do
    if [[ ! -f "$git_base_dir/environment/$environment.local.env" ]]; then
        print_error "Missing environment file $environment.local.env. Did you run setup-environment.sh?"
        exit 1
    fi
    source "$git_base_dir/environment/$environment.env"
    source "$git_base_dir/environment/$environment.local.env"
done

docker compose up -d account

docker compose exec -e SERVER_IP="$SERVER_IP" \
    -e FRIENDS_PORT="$PN_FRIENDS_AUTHENTICATION_SERVER_PORT" \
    -e FRIENDS_AES_KEY="$PN_FRIENDS_CONFIG_AES_KEY" \
    -e MIIVERSE_AES_KEY="$PN_MIIVERSE_API_CONFIG_AES_KEY" \
    -e WIIU_CHAT_PORT="$PN_WIIU_CHAT_AUTHENTICATION_SERVER_PORT" \
    -e SMM_PORT="$PN_SMM_AUTHENTICATION_SERVER_PORT" \
    -e POKEGEN7_PORT="$PN_POKEGEN7_AUTHENTICATION_SERVER_PORT" \
    account node -e "$create_server_script"
