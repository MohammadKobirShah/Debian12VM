FROM --platform=linux/amd64 debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    systemd \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    openssl \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox ESR (available in Debian repos)
RUN apt update -y && apt install --no-install-recommends -y \
    firefox-esr \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Install icon theme
RUN apt update -y && apt install --no-install-recommends -y \
    adwaita-icon-theme \
    hicolor-icon-theme \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Create Xauthority file
RUN touch /root/.Xauthority

EXPOSE 5901
EXPOSE 6080

CMD bash -c "\
    vncserver -localhost no \
              -SecurityTypes None \
              -geometry 1024x768 \
              --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new \
                -subj '/C=JP' \
                -x509 \
                -days 365 \
                -nodes \
                -out self.pem \
                -keyout self.pem && \
    websockify -D \
               --web=/usr/share/novnc/ \
               --cert=self.pem \
               6080 localhost:5901 && \
    tail -f /dev/null"
