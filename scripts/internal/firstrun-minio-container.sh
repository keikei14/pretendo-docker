#!/usr/bin/env bash

# shellcheck source=./framework.sh
source "$(dirname "$(realpath "$0")")/framework.sh"
parse_arguments "$@"

if [[ ! -f "$git_base_dir/environment/minio.local.env" ]]; then
    print_error "Missing environment file minio.local.env. Did you run setup-environment.sh?"
    exit 1
fi
source "$git_base_dir/environment/minio.env"
source "$git_base_dir/environment/minio.local.env"

minio_init_script=$(cat "$git_base_dir/scripts/run-in-container/minio-init.sh")

docker compose up -d minio

run_command_until_success "Waiting for MinIO to be ready..." 5 \
    docker compose exec minio mc alias set minio http://minio.pretendo.cc "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

docker compose exec minio sh -c "$minio_init_script"
