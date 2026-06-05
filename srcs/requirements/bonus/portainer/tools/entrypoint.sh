#!/bin/sh

chown -R root:root /data

exec /portainer \
    --admin-password-file /run/secrets/portainer_password