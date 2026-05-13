FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV PORT=10000

# Install lightweight desktop + VNC + noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxde-core \
    lxterminal \
    tigervnc-standalone-server \
    novnc \
    websockify \
    firefox-esr \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    xterm \
    curl \
    wget \
    procps \
    net-tools \
    ca-certificates \
    openssl \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC startup config
RUN mkdir -p /root/.vnc

RUN echo '#!/bin/sh\n\
xrdb $HOME/.Xresources\n\
startlxde &' > /root/.vnc/xstartup && \
chmod +x /root/.vnc/xstartup

# Set VNC password = render
RUN echo "render" | vncpasswd -f > /root/.vnc/passwd && \
chmod 600 /root/.vnc/passwd

# Create SSL cert
RUN openssl req -x509 -nodes -days 3650 \
-subj "/C=US/ST=Cloud/L=Render/O=Docker/CN=localhost" \
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
stdout_logfile=/dev/stdout\n\
stderr_logfile=/dev/stderr\n\
\n\
[program:novnc]\n\
command=/usr/bin/websockify --web=/usr/share/novnc/ --cert=/root/novnc.pem 0.0.0.0:${PORT} localhost:5901\n\
autorestart=true\n\
priority=2\n\
stdout_logfile=/dev/stdout\n\
stderr_logfile=/dev/stderr\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 10000

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
