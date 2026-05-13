FROM --platform=linux/amd64 debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080

# Install lightweight desktop + VNC + noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxde-core \
    lxterminal \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    firefox-esr \
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xterm \
    nano \
    vim \
    curl \
    wget \
    git \
    net-tools \
    procps \
    ca-certificates \
    openssl \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC directory
RUN mkdir -p /root/.vnc

# Configure LXDE startup
RUN echo '#!/bin/sh\n\
export XKL_XMODMAP_DISABLE=1\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startlxde &' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Set VNC password: changeme
RUN echo "changeme" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create SSL certificate for noVNC
RUN openssl req -x509 -nodes -days 3650 \
    -subj "/C=US/ST=Cloud/L=Container/O=Docker/CN=localhost" \
    -newkey rsa:2048 \
    -keyout /root/novnc.pem \
    -out /root/novnc.pem

# Supervisor config
RUN mkdir -p /etc/supervisor/conf.d

RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:vnc]\n\
command=/usr/bin/vncserver :1 -geometry 1280x720 -depth 24 -rfbauth /root/.vnc/passwd\n\
autorestart=true\n\
priority=1\n\
\n\
[program:novnc]\n\
command=/usr/bin/websockify --web=/usr/share/novnc/ --cert=/root/novnc.pem 6080 localhost:5901\n\
autorestart=true\n\
priority=2\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 5901
EXPOSE 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
