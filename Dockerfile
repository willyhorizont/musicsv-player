FROM debian:trixie-slim

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    ffmpeg \
    mpv \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade yt-dlp --break-system-packages \
    && yt-dlp --rm-cache-dir

COPY musicsv-player.sh /usr/local/bin/playmusicsv
RUN chmod +x /usr/local/bin/playmusicsv
