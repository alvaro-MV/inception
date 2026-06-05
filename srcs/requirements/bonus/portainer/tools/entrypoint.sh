#!/bin/sh

ch

exec /portainer \
    --admin-password-file "$(cat "$PORTAINER_PASSWORD")"