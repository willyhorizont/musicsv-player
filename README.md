# MusiCSV Player

No more storing songs in mp3s, no more storing songs playlists in cloud services, just store it as plain old CSV-like text files and stream your music.  

## Requirements

This project runs inside a container environment using **Docker**. All system dependencies (like `mpv`, `ffmpeg`, `yt-dlp`, and `Node.js`) are packaged neatly inside the container, keeping your host machine completely clean.

* **[Docker](https://docker.com)** — Containerization platform to build and run the player environment.

## Installation

### 1. Set Up the Project Directory
Clone or download this project, then make sure you are working in your root project folder:
```bash
cd ~/musicsv-player
```

### 2. Add Alias to Host Machine
Add the alias to your `~/.bashrc` file so you can summon the player instantly from any folder on your host machine:

```bash
echo "alias playmusicsv=\"\$HOME/musicsv-player/run.sh\"" >> ~/.bashrc
```

Apply the changes immediately by reloading your shell configuration:
```bash
source ~/.bashrc
```

## Termux User
```bash
git clone https://github.com/willyhorizont/musicsv-player.git
pkg update -y && pkg upgrade -y
pkg install -y --reinstall python python-pip libexpat ffmpeg mpv nodejs
rm -rf ~/.cache/pip
pip install --upgrade --reinstall yt-dlp --break-system-packages
yt-dlp --rm-cache-dir
termux-setup-storage
echo "alias playmusicsv=\"\$HOME/musicsv-player/musicsv-player.sh\"" >> ~/.bashrc
source ~/.bashrc
playmusicsv --playlist="$HOME/musicsv-player/example.csv"
```

## Usage

*Note: When executing the player for the very first time, Docker will automatically download the lightweight `debian:trixie-slim` base image and prepare your environment. This step will happen invisibly behind the scenes.*

### 1. Run the Included Example Playlist
You can test the player immediately using the example playlist provided in the root of this project:
```bash
playmusicsv --playlist='./example.csv'
```

### 2. Provide Text Argument Directly:
```bash
playmusicsv \
'NYIDAM SARI                ; Lala Atila, Ageng Music Official                 ' \
'Rondo Kempling             ; Lala Widy, Ageng Music, Global Musik Era Digital ' \
'Sotya                      ; Lala Atila, Ageng Music, Global Musik Era Digital' \
'Lali Janjine               ; Deni Kristiani, Langgeng Music Digital           ' \
'Yen Ing Tawang Ono Lintang ; Ina Alah Alah, Langgeng Music Digital            ' \
'SOTYA                      ; KURNIA RAHMA, Mahesa Official                    ' \
'Ireng Manis                ; Intan Chacha, Langgeng Music Digital             ' \
#
```

### 3. Provide Path to `.csv` File:
Create your own file named `your-playlist.csv` using semicolons (`;`) as the separator column:
```text
NYIDAM SARI                ; Lala Atila, Ageng Music Official
Rondo Kempling             ; Lala Widy, Ageng Music, Global Musik Era Digital
Sotya                      ; Lala Atila, Ageng Music, Global Musik Era Digital
Lali Janjine               ; Deni Kristiani, Langgeng Music Digital
Yen Ing Tawang Ono Lintang ; Ina Alah Alah, Langgeng Music Digital
SOTYA                      ; KURNIA RAHMA, Mahesa Official
Ireng Manis                ; Intan Chacha, Langgeng Music Digital
```

Then run the player from any directory using your custom playlist path (supports absolute and dynamic relative locations mapped seamlessly from host to container):
```bash
playmusicsv --playlist="$HOME/Music/your-playlist.csv"
```

## Controls
Manage your playback smoothly right inside your terminal:
* **`q`** — Skip to the **Next** track.
* **`Ctrl + C`** — Jump back to the **Previous** track.
* **`ESC`** — **Exit** the player safely.

---
**Great projects behind this:**  
* [ffmpeg](https://github.com/ffmpeg/ffmpeg)  
* [mpv-player](https://github.com/mpv-player/mpv)  
* [yt-dlp](https://github.com/yt-dlp/yt-dlp)  
