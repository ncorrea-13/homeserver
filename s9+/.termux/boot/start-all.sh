#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd
proot-distro login debian -- bash -c "service cron start && /root/ntfy-start.sh"
