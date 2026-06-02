#!/bin/sh

set -e

USER="${FTP_USER}"
USER_PASS="$(cat "$FTP_PASSWORD_FILE")"

echo "FTP USER: $USER"

mkdir -p /etc/vsftpd
mkdir -p /srv/vsftpd

echo "Generating PAM configuration..."

cat > /etc/pam.d/vsftpd_inception << EOF
#%PAM-1.0
auth       required     pam_userdb.so db=/etc/vsftpd/virtual_users
account    required     pam_userdb.so db=/etc/vsftpd/virtual_users
EOF

echo "Generating PAM database..."

printf "%s\n%s\n" "$USER" "$USER_PASS" \
    > /etc/vsftpd/virtual_users.txt

/usr/bin/db5.3_load \
    -T \
    -t hash \
    -f /etc/vsftpd/virtual_users.txt \
    /etc/vsftpd/virtual_users.db

rm -f /etc/vsftpd/virtual_users.txt

echo "PAM database generated successfully."

echo "Starting vsftpd..."

exec /usr/sbin/vsftpd /etc/vsftpd.conf