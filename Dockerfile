FROM debian:bookworm

# Install SSH server
RUN apt-get update && apt-get install -y \
    systemd systemd-sysv dbus \
    openssh-server \
    python3 python3-dev python3-venv git curl cron socat \
    build-essential libcrypt-dev libc-dev \
    nano \
    && apt-get clean

WORKDIR /opt/chatmail

# Clone Chatmail relay scripts
RUN git clone https://github.com/chatmail/relay.git . \
    && ./scripts/initenv.sh

# Allow root SSH with no password
RUN echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config \
    && echo 'PubkeyAuthentication no' >> /etc/ssh/sshd_config

# Set empty root password (makes SSH accept any password or none)
RUN passwd -d root

# Enable services under systemd
RUN systemctl enable ssh
RUN systemctl enable cron

# Expose ports.
# 80 for acme to get certificate
# 3478 turn/stun
# 3340 iroh-relay ?
# 443 - https/smtp/imap
# 993/143 - imap
# 25/587/465 - smtp

EXPOSE 25 80 143 443 465 587 993 3340 3478

CMD ["/sbin/init"]
