#!/bin/bash

# Inspired from: https://github.com/ropnop/impacket_static_binaries

# This script is intended to be run in the cdrx/pyinstaller-linux:latest Docker image
[[ ! -f /.dockerenv ]] && echo "Do not run this script outside of the docker image!" && exit 1

set -euo pipefail

# Normalize working dir
ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
cd "${ROOT}"

python -m pip install --upgrade pip

# Install Responder / MultiRelay dependencies.

# Updates the directory in which Responder loads its Responder.conf file.
cp -r /host_build/Responder /Responder
cd /Responder
sed -i "s/os.path.dirname(__file__)/'.'/" settings.py
pip install -r ./requirements.txt

# Create standalone binaries.
pyinstaller --specpath /tmp/spec --workpath /tmp/build --distpath /tmp/out --clean -F /Responder/Responder.py
pyinstaller --specpath /tmp/spec --workpath /tmp/build --distpath /tmp/out --clean -F /Responder/tools/MultiRelay.py

# Export the compiled binaries and Responder default configuration file.
mv /tmp/out/Responder /host_build/Responder_linux
mv /tmp/out/MultiRelay /host_build/MultiRelay_linux
cp /Responder/Responder.conf /host_build/Responder.conf