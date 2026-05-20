FROM --platform=linux/amd64 debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    NOVNC_PORT=6080 \
    VNC_RESOLUTION=1280x720 \
    VNC_PASSWORD=changeme

RUN apt-get update && apt-get install -y --no-install-recommends \
    lxde-core lxterminal tigervnc-standalone-server tigervnc-common \
    novnc websockify firefox-esr dbus-x11 x11-xserver-utils \
    x11-utils x11-apps xterm nano vim curl wget git net-tools \
    procps ca-certificates openssl supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.vnc /var/log/supervisor && \
    echo '#!/bin/bash\nexport XKL_XMODMAP_DISABLE=1\nexport XDG_CURRENT_DESKTOP="LXDE"\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startlxde &' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup && \
    echo "${VNC_PASSWORD}" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

RUN openssl req -x509 -nodes -days 3650 \
    -subj "/C=US/ST=State/L=City/O=Org/CN=localhost" \
    -newkey rsa:2048 -keyout /root/novnc.pem -out /root/novnc.pem && \
    chmod 600 /root/novnc.pem

RUN echo '[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
\n\
[program:xvnc]\n\
command=/usr/bin/Xvnc :1 -desktop "Desktop" -geometry %(ENV_VNC_RESOLUTION)s -depth 24 -rfbport %(ENV_VNC_PORT)s -SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd -AlwaysShared -localhost no\n\
autorestart=true\n\
stdout_logfile=/dev/fd/1\n\
stdout_logfile_maxbytes=0\n\
redirect_stderr=true\n\
priority=1\n\
\n\
[program:lxde]\n\
command=/bin/bash /root/.vnc/xstartup\n\
autorestart=true\n\
stdout_logfile=/dev/fd/1\n\
stdout_logfile_maxbytes=0\n\
redirect_stderr=true\n\
priority=2\n\
startsecs=5\n\
\n\
[program:novnc]\n\
command=/usr/bin/websockify --web=/usr/share/novnc/ --cert=/root/novnc.pem %(ENV_NOVNC_PORT)s localhost:%(ENV_VNC_PORT)s\n\
autorestart=true\n\
stdout_logfile=/dev/fd/1\n\
stdout_logfile_maxbytes=0\n\
redirect_stderr=true\n\
priority=3\n\
startsecs=5' > /etc/supervisor/conf.d/supervisord.conf

RUN echo '#!/bin/bash\nrm -rf /tmp/.X1-lock /tmp/.X11-unix\nexec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 6080

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:6080/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
