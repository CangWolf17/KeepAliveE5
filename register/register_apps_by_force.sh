#!/usr/bin/env bash

APP_NAME='E5_ALIVE'
PERMISSIONS_FILE='./required-resource-accesses.json'
CONFIG_PATH='../config'

jq() {
    echo "$1" |
        python3 -c "import sys, json; print(json.load(sys.stdin)$2)"
}

register_app() {
    config_file="$CONFIG_PATH/app$1.json"
    reply_uri="http://localhost:1000$1/"
    username=$2
    password=$3

    # install cli
    [ "$(command -v az)" ] || apt install -y azure-cli
    # curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    # separate multiple accounts
    export AZURE_CONFIG_DIR=/tmp/az-cli/$1
    mkdir -p "$AZURE_CONFIG_DIR"
    # clear account if exists
    # az account clear

    # login
    ret="$(az login \
        --allow-no-subscriptions \
        -u "$username" \
        -p "$password" 2>/dev/null)"
    # tenant_id="$(jq "$ret" "[0]['tenantId']")"

    # delete the existing app
    ret=$(az ad app list --display-name "$APP_NAME")
    [ "$ret" != "[]" ] && {
        az ad app delete --id "$(jq "$ret" "[0]['appId']")"
    }

    # create a new app
    # --identifier-uris api://e5.app \
    ret="$(az ad app create \
        --display-name "$APP_NAME" \
        --reply-urls "$reply_uri" \
        --available-to-other-tenants true \
        --required-resource-accesses "@$PERMISSIONS_FILE")"

    app_id="$(jq "$ret" "['appId']")"
    user_id="$(jq "$(az ad user list)" "[0]['objectId']")"

    # wait azure system to refresh
    sleep 20

    # set owner
    az ad app owner add \
        --id "$app_id" \
        --owner-object-id "$user_id"

    # grant admin consent
    az ad app permission admin-consent --id "$app_id"

    # generate client secret
    ret="$(az ad app credential reset \
        --id "$app_id" \
        --years 100)"
    client_secret="$(jq "$ret" "['password']")"

    # wait azure system to refresh
    sleep 60

    # save app details
    cat >"$config_file" <<EOF
{
    "username": "$username",
    "password": "$password",
    "client_id": "$app_id",
    "client_secret": "$client_secret",
    "redirect_uri": "$reply_uri"
}
EOF
}

get_refresh_token() {
    config_file="$CONFIG_PATH/app$1.json"

    node server.js "$config_file" &
    node client.js "$config_file"
}

handle_single_account() {
    register_app "$@"
    get_refresh_token "$1"
}

[ "$USER" ] && [ "$PASSWD" ] && {
    [ -d "$CONFIG_PATH" ] || mkdir -p "$CONFIG_PATH"

    mapfile -t users < <(echo -e "$USER")
    mapfile -t passwords < <(echo -e "$PASSWD")

    for ((i = 0; i < "${#users[@]}"; i++)); do
        handle_single_account "$i" "${users[$i]}" "${passwords[$i]}" &
    done

    wait
    exit
}

echo "未设置账号密码，无法执行应用注册"
exit 1
