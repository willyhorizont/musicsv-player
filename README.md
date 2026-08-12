# MusiCSV Player

No more storing songs in mp3s, no more storing songs playlists in cloud services, just store it as plain old CSV-like text files and stream your music.  

## Requirements

This project is OS-agnostic and will work on any Linux environment (including Termux on Android) as long as you have the following dependencies installed:

* **[mpv](https://github.com)** — The core media player.
* **[ffmpeg](https://github.com)** — Multimedia framework backend for handling audio streams.
* **[yt-dlp](https://github.com)** — YouTube extraction tool (Keep this updated!).
* **[Node.js](https://nodejs.org)** — Required by `yt-dlp` as an external JavaScript runtime extractor.

### Quick Installation Commands:

<details>
<summary><b>Click to expand installation command for your OS</b></summary>

* **Fedora KDE**: `sudo dnf upgrade --refresh -y && sudo dnf install python3 ffmpeg mpv nodejs -y && pip install --upgrade yt-dlp`
* **Debian**: `sudo apt update && sudo apt upgrade -y && sudo apt install python3 python3-pip ffmpeg mpv nodejs -y && pip install --upgrade yt-dlp --break-system-packages`
* **Termux**: `pkg update && pkg install python ffmpeg mpv nodejs -y && pip install --upgrade yt-dlp && termux-setup-storage`
</details>

## Installation

1. Open your shell configuration file using `nano`:
   ```bash
   nano ~/.bashrc
   ```

2. Copy the complete code from `./musicsv-player.sh` and paste it at the very bottom of the file.

3. Save and Exit `nano` using this exact button sequence:
   * Press **`Ctrl + O`** (to write changes)
   * Press **`Enter`** (to confirm the file name)
   * Press **`Ctrl + X`** (to exit the editor safely)

4. Reload your terminal configuration to apply the changes immediately:
   ```bash
   source ~/.bashrc
   ```

## Usage

### 1. Run the Included Example Playlist
You can test the player immediately using the example playlist provided in the root of this project:
```bash
play_musicsv --playlist='./example.musicsv'
```

### 2. Provide Text Argument Directly:
```bash
play_musicsv \
'| NYIDAM SARI                | Lala Atila, Ageng Music Official                  |' \
'| Rondo Kempling             | Lala Widy, Ageng Music, Global Musik Era Digital  |' \
'| Sotya                      | Lala Atila, Ageng Music, Global Musik Era Digital |' \
'| Lali Janjine               | Deni Kristiani, Langgeng Music Digital            |' \
'| Yen Ing Tawang Ono Lintang | Ina Alah Alah, Langgeng Music Digital             |' \
'| SOTYA                      | KURNIA RAHMA, Mahesa Official                     |' \
'| Ireng Manis                | Intan Chacha, Langgeng Music Digital              |' \
#
```

### 3. Provide Path to Custom `.musicsv` File:
Create your own file named `your-playlist.musicsv`:
```text
'| NYIDAM SARI                | Lala Atila, Ageng Music Official                  |' \
'| Rondo Kempling             | Lala Widy, Ageng Music, Global Musik Era Digital  |' \
'| Sotya                      | Lala Atila, Ageng Music, Global Musik Era Digital |' \
'| Lali Janjine               | Deni Kristiani, Langgeng Music Digital            |' \
'| Yen Ing Tawang Ono Lintang | Ina Alah Alah, Langgeng Music Digital             |' \
'| SOTYA                      | KURNIA RAHMA, Mahesa Official                     |' \
'| Ireng Manis                | Intan Chacha, Langgeng Music Digital              |' \
```

Then run the player with your custom playlist path:
```bash
play_musicsv --playlist='/path/to/your-playlist.musicsv'
```

### 4. Provide Path to `.csv` File:
Create your own file named `your-playlist.csv`:
```text
NYIDAM SARI                | Lala Atila, Ageng Music Official
Rondo Kempling             | Lala Widy, Ageng Music, Global Musik Era Digital
Sotya                      | Lala Atila, Ageng Music, Global Musik Era Digital
Lali Janjine               | Deni Kristiani, Langgeng Music Digital
Yen Ing Tawang Ono Lintang | Ina Alah Alah, Langgeng Music Digital
SOTYA                      | KURNIA RAHMA, Mahesa Official
Ireng Manis                | Intan Chacha, Langgeng Music Digital
```

Then run the player with your custom playlist path:
```bash
play_musicsv --playlist='/path/to/your-playlist.csv'
```

---
**Great projects behind this:**  
* [ffmpeg](https://github.com/ffmpeg/ffmpeg)  
* [mpv-player](https://github.com/mpv-player/mpv)  
* [yt-dlp](https://github.com/yt-dlp/yt-dlp)  
