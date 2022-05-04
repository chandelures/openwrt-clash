#!/bin/sh
IPTABLES=iptables

$IPTABLES -t mangle -D PREROUTING -j CLASH 2>/dev/null
$IPTABLES -t mangle -D OUTPUT -j CLASH_LOCAL 2>/dev/null
$IPTABLES -t mangle -F CLASH 2>/dev/null
$IPTABLES -t mangle -F CLASH_LOCAL 2>/dev/null
$IPTABLES -t mangle -X CLASH 2>/dev/null
$IPTABLES -t mangle -X CLASH_LOCAL 2>/dev/null
