FROM phasecorex/user-python:3.8-slim

RUN set -eux; \
    # Install dependencies
    apt-get update; \
    apt-get install -y --no-install-recommends \
        # Red-DiscordBot required
        git \
        # ssh repo support
        openssh-client \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    # Set up all three config locations
    mkdir -p /root/.config/Red-DiscordBot; \
    ln -s /data/config.json /root/.config/Red-DiscordBot/config.json; \
    mkdir -p /usr/local/share/Red-DiscordBot; \
    ln -s /data/config.json /usr/local/share/Red-DiscordBot/config.json; \
    mkdir -p /config/.config/Red-DiscordBot; \
    ln -s /data/config.json /config/.config/Red-DiscordBot/config.json

VOLUME /data

COPY root/ /

CMD ["start-redbot.sh"]

ARG PIP_REDBOT_VERSION=Red-DiscordBot

RUN set -eux; \
    # Install requested version
    python -m pip install -U "${PIP_REDBOT_VERSION}"
