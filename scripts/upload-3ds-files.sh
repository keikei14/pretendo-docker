#!/usr/bin/env bash

# shellcheck source=./internal/framework.sh
source "$(dirname "$(realpath "$0")")/internal/framework.sh"
set_description "This uploads required files from console-files to your 3DS to connect to your Pretendo server."
add_option "-r --reset" "should_reset" "Reset the Juxt certificate to Pretendo's instead of using the mitmproxy certificate"
parse_arguments "$@"

if [[ ! -f "$git_base_dir/.env" ]]; then
    print_error "Missing .env file. Did you run setup-environment.sh?"
    exit 1
fi
source "$git_base_dir/.env"
if [[ -z "${DS_IP:-}" ]]; then
    print_warning "Missing environment variable DS_IP. Did you specify a 3DS IP address when you ran setup-environment.sh?"
    print_info "Continuing without automatic FTP upload."
fi

cd "$git_base_dir/console-files"

if [[ -z "$should_reset" ]]; then
    docker compose up -d mitmproxy-pretendo

    run_command_until_success "docker compose exec mitmproxy-pretendo ls /home/mitmproxy/.mitmproxy/mitmproxy-ca-cert.pem" \
        "Waiting for mitmproxy to generate a certificate..." 4

    # Get the current certificate
    docker compose cp mitmproxy-pretendo:/home/mitmproxy/.mitmproxy/mitmproxy-ca-cert.pem ./mitmproxy-ca-cert.pem
else
    print_info "Reset the Juxt certificate."
fi

# Upload the required files
if [[ -n "${DS_IP:-}" ]]; then
    if [[ -z "$should_reset" ]]; then
        tnftp -u "ftp://user:pass@$DS_IP:5000/3ds/juxt-prod.pem" ./mitmproxy-ca-cert.pem
        tnftp -u "ftp://user:pass@$DS_IP:5000/gm9/scripts/FriendsAccountSwitcher.gm9" ./FriendsAccountSwitcher.gm9
        tnftp -u "ftp://user:pass@$DS_IP:5000/3ds/ResetFriendsTestAccount.3dsx" ./ResetFriendsTestAccount.3dsx
    else
        tnftp -u "ftp://user:pass@$DS_IP:5000/3ds/juxt-prod.pem" ./juxt-prod.pem
    fi
    print_success "Successfully uploaded the required files to your 3DS."
else
    print_warning "The required files were not uploaded to your 3DS because you did not set an IP address."
fi
