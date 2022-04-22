#!/bin/sh

. "/lib/functions.sh"
. "/lib/functions/network.sh"

CONF="clash"
IPTABLES="/usr/sbin/iptables"

config_load "$CONF"

config_get tproxy_port "global" "tproxy_port"
config_get tproxy_mark "global" "tproxy_mark" "1"
config_get_bool udp_tproxy_enabled "global" "udp_tproxy_enabled"
config_get dns_mode "global" "dns_mode"
config_get fake_ip_range "global" "fake_ip_range"

create_chains() {
	$IPTABLES -t mangle -N CLASH 2>/dev/null
	$IPTABLES -t mangle -N CLASH_LOCAL 2>/dev/null
}

bypass_addresses() {
	cat <<-EOF
		0.0.0.0/8
		10.0.0.0/8
		100.64.0.0/10
		127.0.0.0/8
		169.254.0.0/16
		172.16.0.0/12
		192.0.0.0/24
		192.0.2.0/24
		198.18.0.1/16
		192.31.196.0/24
		192.52.193.0/24
		192.88.99.0/24
		192.168.0.0/16
		192.175.48.0/24
		198.51.100.0/24
		203.0.113.0/24
		224.0.0.0/4
		255.255.255.255
	EOF
}

iptables_bypass() {
	local chain=$1

	local net_if net_addr
	network_find_wan net_if
	network_get_ipaddr net_addr $net_if
	$IPTABLES -t mangle -A "$chain" -d "$net_addr" -j RETURN

	for addr in $(bypass_addresses); do
		if [ "$dns_mode" == "fake-ip" ]; then
			[ "$addr" != "$fake_ip_range" ] && $IPTABLES -t mangle -A "$chain" -d "$addr" -j RETURN
		else
			$IPTABLES -t mangle -A "$chain" -d "$addr" -j RETURN
		fi
	done
}

tproxy_rules() {
	iptables_bypass "CLASH"
	if [ "$udp_tproxy_enabled" -eq "1" ]; then
		$IPTABLES -t mangle -A CLASH -p udp -j TPROXY \
			--on-ip 127.0.0.1 --on-port "$tproxy_port" \
			--tproxy-mark "$tproxy_mark"
	else
		$IPTABLES -t mangle -I CLASH -p udp -j RETURN
	fi
	$IPTABLES -t mangle -A CLASH -p tcp -j TPROXY \
		--on-ip 127.0.0.1 --on-port "$tproxy_port" \
		--tproxy-mark "$tproxy_mark"
	$IPTABLES -t mangle -A PREROUTING -j CLASH
}

local_rules() {
	iptables_bypass "CLASH_LOCAL"
	$IPTABLES -t mangle -I CLASH_LOCAL -m owner --uid-owner "clash" -j RETURN
	if [ "$udp_tproxy_enabled" -eq "1" ]; then
		$IPTABLES -t mangle -A CLASH_LOCAL -p udp -j MARK \
			--set-mark "$tproxy_mark"
	else
		$IPTABLES -t mangle -I CLASH_LOCAL -p udp -j RETURN
	fi
	$IPTABLES -t mangle -A CLASH_LOCAL -p tcp -j MARK \
		--set-mark "$tproxy_mark"
	$IPTABLES -t mangle -A OUTPUT -j CLASH_LOCAL
}

main() {
	create_chains
	tproxy_rules
	[ -x "/sbin/ujail" ] && (opkg list-installed | grep "iptables-mod-extra" >/dev/null) && local_rules
}

main
