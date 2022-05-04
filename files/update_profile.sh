#/bin/sh

# REQUIRE CURL

profile=$1
CONF="clash"
CURL="curl"

msg() {
	logger -p daemon.info -st "$CONF[$$]" "$*"
}

(opkg list-installed | grep "curl" >/dev/null) || { msg "Update profile from url require cURL with SSL support."; return 1;}
[ -z "$profile" ] && { msg "Missing profile name."; return 1;}

. "/lib/functions.sh"

config_load "$CONF"

config_get type "$profile" "type"

[ "$type" == "Static" ] && { msg "Static type profile can't be updated."; return 1;}

config_get url "$profile" "url"

$CURL -sL \
    -o "/etc/clash/profiles/$profile.yaml" \
    $url

if [ "$?" != 0 ]; then
    msg "Update profile $profile failed, url gave an unexpected response."
    return 1
fi

msg "Update profile $profile finished."

return 0
