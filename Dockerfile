FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:1 \
    VNC_GEOMETRY=1366x768 \
    START_CHROMIUM=true \
    VNC_PASSWORD=change-me-now \
    PORT=10000

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    chromium \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    nginx \
    ca-certificates \
    fonts-dejavu \
    fonts-liberation \
    fonts-noto-color-emoji \
    xauth \
    x11-xserver-utils \
    procps \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash --uid 1000 desktop \
    && mkdir -p /var/data /opt/novnc \
    && chown -R desktop:desktop /var/data /home/desktop /opt/novnc

# Keep the browser UI normal (not kiosk mode) and provide a simple landing page.
RUN cp -a /usr/share/novnc/. /opt/novnc/
COPY index.html /opt/novnc/index.html
COPY nginx.conf.template /etc/nginx/nginx.conf.template

COPY xstartup /usr/local/bin/xstartup
COPY start.sh /usr/local/bin/start.sh
RUN chmod 0755 /usr/local/bin/xstartup /usr/local/bin/start.sh

VOLUME ["/var/data"]
EXPOSE 10000
USER desktop
WORKDIR /home/desktop
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/start.sh"]
