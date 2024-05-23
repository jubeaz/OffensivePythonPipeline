#!/bin/bash

# Inspired from: https://github.com/ropnop/impacket_static_binaries
# Impacket Linux build script source: https://github.com/ropnop/impacket_static_binaries/blob/master/build_scripts/build_linux.sh

# This script is intended to be run in the cdrx/pyinstaller-linux:latest Docker image
[[ ! -f /.dockerenv ]] && echo "Do not run this script outside of the docker image!" && exit 1

set -euo pipefail

# Normalize working dir
ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
cd "${ROOT}"

cd /host_build/impacket-SecureAuthCorp/
cat <<EOF > protocol_client.txt
# START PATCH FOR PYINSTALLER
#    from impacket.examples.ntlmrelayx.clients import PROTOCOL_CLIENTS
#    from impacket.examples.ntlmrelayx.attacks import PROTOCOL_ATTACKS

    for x in PROTOCOL_CLIENTS.keys():
        logging.info('Protocol Client %s loaded..' % x)
# END PATCH FOR PYINSTALLER
EOF

cat <<EOF > imports.txt
from impacket.examples.ntlmrelayx.servers.socksserver import SOCKS
# START PATCH FOR PYINSTALLER
from impacket.examples.ntlmrelayx.clients.dcsyncclient import DCSYNCRelayClient
from impacket.examples.ntlmrelayx.clients.httprelayclient import HTTPRelayClient,HTTPSRelayClient
from impacket.examples.ntlmrelayx.clients.rpcrelayclient import RPCRelayClient
from impacket.examples.ntlmrelayx.clients.smbrelayclient import SMBRelayClient
from impacket.examples.ntlmrelayx.clients.smtprelayclient import SMTPRelayClient
from impacket.examples.ntlmrelayx.clients.ldaprelayclient import LDAPRelayClient,LDAPSRelayClient
from impacket.examples.ntlmrelayx.clients.mssqlrelayclient import MSSQLRelayClient
from impacket.examples.ntlmrelayx.clients.imaprelayclient import IMAPRelayClient,IMAPSRelayClient
from impacket.examples.ntlmrelayx.attacks.dcsyncattack import DCSYNCAttack
from impacket.examples.ntlmrelayx.attacks.httpattack import HTTPAttack
from impacket.examples.ntlmrelayx.attacks.httpattacks import adcsattack
from impacket.examples.ntlmrelayx.attacks.ldapattack import LDAPAttack
from impacket.examples.ntlmrelayx.attacks.mssqlattack import MSSQLAttack
from impacket.examples.ntlmrelayx.attacks.smbattack import SMBAttack
from impacket.examples.ntlmrelayx.attacks.imapattack import IMAPAttack
from impacket.examples.ntlmrelayx.attacks.rpcattack import RPCAttack

PROTOCOL_ATTACKS = {"DCSYNC":DCSYNCAttack, "HTTP":HTTPAttack, "HTTPS":adcsattack ,"IMAP":IMAPAttack,"IMAPS":IMAPAttack,"SMB":SMBAttack,"RPC":RPCAttack,"MSSQL":MSSQLAttack,"LDAP":LDAPAttack, "LDAPS":LDAPAttack}
PROTOCOL_CLIENTS = {"DCSYNC":DCSYNCRelayClient, "HTTP":HTTPRelayClient, "HTTPS":HTTPSRelayClient, "SMTP":SMTPRelayClient, "LDAPS":LDAPSRelayClient, "IMAP":IMAPRelayClient, "IMAPS":IMAPSRelayClient, "SMB":SMBRelayClient,"RPC":RPCRelayClient,"MSSQL":MSSQLRelayClient,"LDAP":LDAPRelayClient}
# END PATCH FOR PYINSTALLER
EOF
[[ ! -f /host_build/impacket-SecureAuthCorp/ntlmrelayx.py.ori ]] && echo "Saving ntlmrelayx.py" && cp /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py /host_build/impacket-SecureAuthCorp/ntlmrelayx.py.ori

cat protocol_client.txt
echo "Patching ntlmrelayx" 
cp /host_build/impacket-SecureAuthCorp/ntlmrelayx.py.ori /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py 
sed -i '/from impacket.examples.ntlmrelayx.attacks import PROTOCOL_ATTACKS/d' /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py
awk '/    from impacket.examples.ntlmrelayx.clients import PROTOCOL_CLIENTS/{system("cat protocol_client.txt");next}1' /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py > /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx-patched.py
awk '/from impacket.examples.ntlmrelayx.servers.socksserver import SOCKS/{system("cat imports.txt");next}1' /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx-patched.py > /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py
cp /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py  /host_build/impacket-SecureAuthCorp/ntlmrelayx-patched.py 
rm /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx-patched.py

#PYTHON_LIB_PATH=/usr/local/lib/python3.8
PYTHON_LIB_PATH=/sed/to/set/proper/path
if [ ! -d "$PYTHON_LIB_PATH" ]; then
    echo "$PYTHON_LIB_PATH does not exist quitting"
    exist
fi

# Install impacket
cd /host_build/impacket-SecureAuthCorp/
pip install .

# Hardcode UTF-8 in shells.
sed -r -i.bak 's/sys\.std(in|out)\.encoding/"UTF-8"/g' /host_build/impacket-SecureAuthCorp/examples/*exec.py  


#pyinstaller --path "/usr/local/lib/python3.8/site-packages/impacket","/usr/local/lib/python3.8/site-packages","/usr/local/lib/python3.8" --hidden-import=impacket.examples.utils --specpath /tmp/spec --workpath /tmp/build --distpath /tmp/out --clean -F /host_build/impacket-SecureAuthCorp/examples/ntlmrelayx.py
# Create standalone executables
for i in /host_build/impacket-SecureAuthCorp/examples/*.py
do
    pyinstaller --path "$PYTHON_LIB_PATH/site-packages/impacket","$PYTHON_LIB_PATH/site-packages","$PYTHON_LIB_PATH" --hidden-import=impacket.examples.utils --specpath /tmp/spec --workpath /tmp/build --distpath /tmp/out --clean -F $i
done

# Rename binaries and move
mkdir -p /host_build/impacket
find /tmp/out/ -type f -exec mv {} {}_linux \;
mv /tmp/out/*_linux /host_build/impacket/

# Restore backup file
for fn in /host_build/impacket-SecureAuthCorp/examples/*.bak; do mv -f "${fn}" "${fn%%.bak}"; done

