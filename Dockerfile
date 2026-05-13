FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV PORT=10000

# Install lightweight desktop + VNC + noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxde-core \
    lxterminal \
    openbox \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    firefox-esr \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    xterm \
    supervisor \
    curl \
    wget \
    git \
    nano \
    procps \
    net-tools \
    ca-certificates \
    openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC directory
RUN mkdir -p /root/.vnc

# Create LXDE startup script
RUN printf '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xrdb $HOME/.Xresources\n\
startlxde &\n' > /root/.vnc/xstartup && \
chmod +x /root/.vnc/xstartup

# Set VNC password = render
RUN echo "render" | /usr/bin/vncpasswd -f > /root/.vnc/passwd && \
chmod 600 /root/.vnc/passwd

# Generate SSL certificate for noVNC
RUN openssl req -x509 -nodes -days 3650 \
    -subj "/C=US/ST=Cloud/L=Render/O=Docker/CN=localhost" \
    -newkey rsa:2048 \
    -keyout /root/novnc.pem \
    -out /root/novnc.pem

# Write a startup wrapper so websockify reads $PORT at runtime
RUN mkdir -p /etc/supervisor/conf.d

# Use cat + heredoc — no printf percent-sign issues
RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/dev/null
pidfile=/tmp/supervisord.pid

[program:vnc]
command=/usr/bin/vncserver :1 -geometry 1280x720 -depth 24 -rfbauth /root/.vnc/passwd
autorestart=true
priority=1
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:novnc]
command=/bin/sh -c '/usr/bin/websockify --web=/usr/share/novnc/ --cert=/root/novnc.pem 0.0.0.0:${PORT} localhost:5901'
autorestart=true
priority=2
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

EXPOSE 10000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
