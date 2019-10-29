# Run Chromium in a container using ProtonVPN
#
# docker run -it --rm \
#         --cpuset-cpus 0 \
#         --memory 512mb \
#         -v /tmp/.X11-unix:/tmp/.X11-unix \
#         -e DISPLAY=unix$DISPLAY \
#         -v $HOME/Downloads:/home/chromium/Downloads \
#         -v $HOME/.config/chromium/:/data \
#         --security-opt seccomp=$HOME/chrome.json \
#         --device /dev/snd \
#         -v /dev/shm:/dev/shm \
#         --name chromium \
#         --device /dev/net/tun \
#         --cap-add=NET_ADMIN \
#         kyokley/proton_chromium
#
# You will want the custom seccomp profile:
# 	wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O ~/chrome.json

# This is based heavily on the work of Jessie Frazelle. She deserves all the credit here.

# Base docker image
FROM debian:stretch
LABEL maintainer "Kevin Yokley <kyokley2@gmail.com>"

ADD https://dl.google.com/linux/direct/google-talkplugin_current_amd64.deb /src/google-talkplugin_current_amd64.deb

# Install Chromium
RUN apt-get update && apt-get install -y \
      chromium \
      chromium-l10n \
      fonts-liberation \
      fonts-roboto \
      hicolor-icon-theme \
      libcanberra-gtk-module \
      libexif-dev \
      libgl1-mesa-dri \
      libgl1-mesa-glx \
      libpango1.0-0 \
      libv4l-0 \
      fonts-symbola \
      openvpn \
      sudo \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/chromium.d/ \
    && /bin/echo -e 'export GOOGLE_API_KEY="AIzaSyCkfPOPZXDKNn8hhgu3JrA62wIgC93d44k"\nexport GOOGLE_DEFAULT_CLIENT_ID="811574891467.apps.googleusercontent.com"\nexport GOOGLE_DEFAULT_CLIENT_SECRET="kdloedMFGdGla2P1zacGjAQh"' > /etc/chromium.d/googleapikeys \
    && dpkg -i '/src/google-talkplugin_current_amd64.deb'

# Add chromium user
RUN groupadd -r chromium && useradd -r -g chromium -G audio,video chromium \
    && mkdir -p /home/chromium/Downloads && chown -R chromium:chromium /home/chromium \
    && mkdir -p /home/chromium/data && chown -R chromium:chromium /home/chromium/data
RUN echo "chromium ALL=(ALL) NOPASSWD: /usr/sbin/openvpn" >> /etc/sudoers

RUN adduser chromium sudo

COPY us-free-02.protonvpn.com.udp1194.ovpn /home/chromium/proton.ovpn
COPY creds.txt /home/chromium/creds.txt
RUN chmod 400 /home/chromium/creds.txt

# Run as non privileged user
USER chromium

ENTRYPOINT ["/bin/bash", "-c", "sudo openvpn --config /home/chromium/proton.ovpn --daemon && \
                                /usr/bin/chromium --user-data-dir=/home/chromium/data" ]
