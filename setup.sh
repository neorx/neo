#!/bin/bash

##
# neo
# ---
# by Francesco Bianco
# bianco@javanile.org
# MIT License
##

set -e

neo_bin=/usr/local/bin/neo
neo_src=https://raw.githubusercontent.com/zionrc/neo/master/neo.sh

echo "Get: ${neo_src} -> ${neo_bin}"
curl --progress-bar -sLo "${neo_bin}" "${neo_src}?ts=$(date +%s)"

echo "Inf: set file permission to ${neo_bin}"
chmod +x ${neo_bin}

echo "Done."
