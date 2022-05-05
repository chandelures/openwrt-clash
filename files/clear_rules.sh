#!/bin/sh

. "/lib/functions.sh"

CONF="clash"
IPTABLES="/usr/sbin/iptables"

config_load "$CONF"

clear_route_rules() {
    local tproxy_mark
    config_get tproxy_mark "global" "tproxy_mark" "1"

    ip rule del fwmark "$tproxy_mark" table 100 2>/dev/null
    ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null
}

clear_chains() {
    $IPTABLES -t mangle -D PREROUTING -j CLASH 2>/dev/null
    $IPTABLES -t mangle -D OUTPUT -j CLASH_LOCAL 2>/dev/null
    $IPTABLES -t mangle -F CLASH 2>/dev/null
    $IPTABLES -t mangle -F CLASH_LOCAL 2>/dev/null
    $IPTABLES -t mangle -X CLASH 2>/dev/null
    $IPTABLES -t mangle -X CLASH_LOCAL 2>/dev/null
}

main() {
    clear_route_rules
    clear_chains
}

main
