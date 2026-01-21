#!/bin/bash

if ip link show tun0 up &>/dev/null; then
	echo '{"text":"","class":"connected"}'
else
	echo '{"text":"","class":"disconnected"}'
fi
