# MusiCSV Player

![MusiCSV-Player Screenshot 1](https://github.com/willyhorizont/musiCSV-Player/blob/main/screenshot-1.png)![MusiCSV-Player Screenshot 2](https://github.com/willyhorizont/musiCSV-Player/blob/main/screenshot-2.png)  

No more storing songs in mp3s, no more storing songs playlists in cloud services, just store it as plain old CSV-like text files and stream your music.  

## Installation/Updates (Desktop x86) * [Docker](https://docker.com) required
```bash
docker rmi willyhorizont/musicv-player

sed -i '/alias musicsv=/d' ~/.bashrc && echo "alias musicsv='export PYTHONDONTWRITEBYTECODE=1; \$HOME/musicsv-player/run.sh \$HOME/musicsv-player/musicsv-player.py'" >> ~/.bashrc
source ~/.bashrc

rm -rf "$HOME/musicsv-player" && git clone https://github.com/willyhorizont/musicsv-player.git

mkdir -p "$HOME/Music/musicsv-playlist"
cp -f "$HOME/musicsv-player/"*.csv "$HOME/Music/musicsv-playlist/"

musicsv "$HOME/Music/musicsv-playlist/example.csv" --rptall --shuf
```

## Installation/Updates (Termux)
```bash
pkg update -y && pkg upgrade -y
pkg install -y --reinstall git python python-pip libexpat ffmpeg mpv nodejs socat netcat-openbsd
rm -rf ~/.cache/pip
pip install --upgrade --force-reinstall --break-system-packages yt-dlp
yt-dlp --rm-cache-dir
termux-setup-storage
sed -i '/volume-keys =/d' ~/.termux/termux.properties && echo "volume-keys = volume" >> ~/.termux/termux.properties
termux-reload-settings

sed -i '/alias musicsv=/d' ~/.bashrc && echo "alias musicsv='export PYTHONDONTWRITEBYTECODE=1; \$HOME/musicsv-player/musicsv-player.py'" >> ~/.bashrc
source ~/.bashrc

rm -rf "$HOME/musicsv-player" && git clone https://github.com/willyhorizont/musicsv-player.git

mkdir -p "$HOME/storage/music/musicsv-playlist"
cp -f "$HOME/musicsv-player/"*.csv "$HOME/storage/music/musicsv-playlist/"

musicsv "$HOME/storage/music/musicsv-playlist/example.csv" --rptall --shuf
```

## Usage
```bash
musicsv "$HOME/Music/your-playlist.csv" --loop --shuffle
```

---
**Great projects behind this:**  
* [ffmpeg](https://github.com/ffmpeg/ffmpeg)  
* [mpv](https://github.com/mpv-player/mpv)  
* [yt-dlp](https://github.com/yt-dlp/yt-dlp)  
