set -e

USER="${FT_USER}"
USER_PASS_FILE="${FTP_PASSWORD_FILE}"

echo -e "${USER}\\${USER_PASS_FILE}" >> /etc/vsftpd/virtual_users.txt
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db

/usr/sbin/vsftpd /etc/vsftpd.conf 