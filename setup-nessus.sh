#!/bin/sh
/opt/nessus/sbin/nessuscli fetch --register-offline /tmp/nessus.license
curl 'https://localhost:8834/users' -H 'Content-Type: application/json' --data-binary '{"username":"admin","password":"admin1","permissions":128}' --insecure
/opt/nessus/sbin/nessuscli lsuser