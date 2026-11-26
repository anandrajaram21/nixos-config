# Media stack setup (saturn)

[← README](../README.md#services-saturn)

Nix only installs and runs the services. Everything below is set once in each
app's web UI and saved under `/var/lib/<app>` on saturn, so it survives
rebuilds; it only needs redoing after a reinstall. Do it in this order: each
step uses something from the ones before. Open every address on a tailnet
device. Apps talk to each other at `127.0.0.1`, since they all run on saturn.
Collect these API keys as you go: Jellyfin, Sonarr, Radarr, Lidarr, slskd.

## 1. Jellyfin: `https://jellyfin.home.anandrajaram.dev`

1. Setup wizard:
   - Pick a display language. **Next**.
   - Create the admin user (username and password). **Next**.
   - **Add Media Library**, three times. For each: choose the content type,
     set the display name, click **+** next to Folders, enter the path, **OK**:
     - Content type **Movies**, name `Movies`, folder `/data/media/movies`
     - Content type **Shows**, name `Shows`, folder `/data/media/tv`
     - Content type **Music**, name `Music`, folder `/data/media/music`
   - Metadata language and country: your choice. **Next**.
   - Remote access: keep **Allow remote connections to this server** ticked;
     untick **Enable automatic port mapping**. **Next**, **Finish**, sign in.
2. **Dashboard → Playback → Transcoding:**
   - Hardware acceleration: **Nvidia NVENC**.
   - Enable hardware decoding for: tick **H264**, **HEVC**, **MPEG2**,
     **VC1**, **VP8**, **VP9**, **HEVC 10bit**. Leave **AV1**, **VP9 10bit**,
     **HEVC RExt 8/10bit** and **HEVC RExt 12bit** unticked (Pascal can't).
   - Tick **Enable hardware encoding**.
   - Tick **Allow encoding in HEVC format**. Leave **Allow encoding in AV1
     format** unticked.
   - Tick **Enable tone mapping**.
   - **Save**.
3. **Dashboard → Networking:**
   - Published server URIs: `all=https://jellyfin.home.anandrajaram.dev`
   - Known proxies: `127.0.0.1`
   - LAN networks: `192.168.0.0/24`
   - **Save**, then restart Jellyfin from **Dashboard → Restart**.
4. **Dashboard → API Keys → +**: app name `arr`, **OK**. Copy the key
   (the **Jellyfin key**).
5. **Dashboard → Plugins → Catalog → LrcLib → Install**, then
   **Dashboard → Restart**.
6. **Dashboard → Libraries → Music → ⋮ → Manage library:**
   - Tick **Prefer non-standard artist tags**.
   - Under **Lyric fetchers**, tick **LrcLib**.
   - **OK**. Then, from the same ⋮ menu, **Scan library** with
     **Replace all metadata** so existing tracks pick up the artist tags.
7. **Dashboard → Scheduled Tasks:**
   - **Download missing lyrics → +**: trigger type **Daily**, time `03:00`, **Add**.
   - **Scan Media Library → +**: **Daily**, `04:00`, **Add** (keep the
     existing interval trigger).

## 2. qBittorrent: `https://qbittorrent.home.anandrajaram.dev`

1. On saturn, get the latest temporary password (each restart prints a new
   one): `journalctl -u qbittorrent | grep -i password | tail -1`.
2. Sign in as `admin` with it.
3. **Tools → Options**, tab by tab, then **Save** at the bottom:
   - **Web UI → Authentication:** set a new username/password. Untick
     **Bypass authentication for clients on localhost** and **Bypass
     authentication for clients in whitelisted IP subnets**.
   - **Downloads → Saving Management:**
     - Default Torrent Management Mode: **Automatic**
     - When Torrent Category changed: **Relocate torrent**
     - When Default Save Path changed: **Relocate affected torrents**
     - When Category Save Path changed: **Relocate affected torrents**
     - Default Save Path: `/data/torrents`
     - Leave **Keep incomplete torrents in** unticked.
   - **Connection:**
     - Port used for incoming connections: `6881`
     - Untick **Use UPnP / NAT-PMP port forwarding from my router**.
   - **BitTorrent → Seeding Limits:**
     - Tick **When ratio reaches**, set `0`.
     - then: **Stop torrent** (not Remove: removing could delete a torrent
       before it's imported).
4. Sign out and back in with the new password.

## 3. Sonarr: `https://sonarr.home.anandrajaram.dev`

1. First open: **Authentication Method: Forms (Login Page)**,
   **Authentication Required: Enabled**, username and password, **Save**.
2. **Settings → Media Management** (click **Show Advanced** at the top):
   - **Episode Naming:** tick **Rename Episodes**.
   - **Importing:** tick **Use Hardlinks instead of Copy**.
   - **Root Folders → Add Root Folder:** `/data/media/tv`, **OK**.
   - **Save Changes**.
3. **Settings → Download Clients → + → qBittorrent:**
   - Name `qBittorrent`, **Enable** ticked.
   - Host `127.0.0.1`, Port `8080`, untick **Use SSL**.
   - Username/Password: your qBittorrent login.
   - Category: `tv`.
   - **Completed Download Handling** (in the same dialog, with Show
     Advanced): tick **Remove Completed** and **Remove Failed**.
   - **Test**, then **Save**.
   - Back on the Download Clients page, **Completed Download Handling:**
     **Enable** ticked. **Save Changes**.
4. **Settings → Connect → + → Emby / Jellyfin:**
   - Name `Jellyfin`, Host `127.0.0.1`, Port `8096`, untick **Use SSL**.
   - API Key: the Jellyfin key.
   - Tick **Update Library**.
   - Notification triggers: tick **On Import**, **On Upgrade**, **On Rename**,
     **On Series Delete**, **On Episode File Delete**.
   - **Test**, then **Save**.
5. **Settings → General → Security:** copy the **API Key** (the **Sonarr key**).

## 4. Radarr: `https://radarr.home.anandrajaram.dev`

Same as Sonarr, with:

- **Movie Naming:** tick **Rename Movies**.
- Root folder `/data/media/movies`.
- qBittorrent category `movies`.
- Connect triggers: **On Import**, **On Upgrade**, **On Rename**, **On Movie
  Delete**, **On Movie File Delete**.
- Copy the API key (the **Radarr key**).

## 5. Lidarr: `https://lidarr.home.anandrajaram.dev`

1. First open: **Forms (Login Page)**, **Enabled**, username and password.
2. **Settings → Media Management** (**Show Advanced**):
   - **Track Naming:** tick **Rename Tracks**. Multi Disc Track Format:
     `{Album Title} ({Release Year})/Disc {medium:00}/{track:00} - {Track Title}`
     (the default would make vinyl sides separate albums in Jellyfin).
   - **Importing:** tick **Use Hardlinks instead of Copy**.
   - **Root Folders → Add Root Folder:** path `/data/media/music`, pick the
     default Quality and Metadata profiles, **Save**.
   - **Save Changes**.
3. **Settings → Download Clients → + → qBittorrent:** Host `127.0.0.1`, Port
   `8080`, your login, Category `music`, tick **Remove Completed** and
   **Remove Failed**. **Test**, **Save**. On the page, **Completed Download
   Handling → Enable** ticked, **Save Changes**.
4. **Settings → Connect → + → Webhook** (Jellyfin rescans music after each
   import; Lidarr's own Emby/Jellyfin connection calls routes Jellyfin no
   longer serves):
   - Get the Music library ID on saturn:
     `curl -s "http://127.0.0.1:8096/Library/VirtualFolders?ApiKey=<jellyfin-key>" | jq -r '.[] | "\(.Name)  \(.ItemId)"'`
   - Name `Jellyfin music rescan`.
   - Tick **On Release Import**, **On Upgrade**, **On Rename**, **On Track
     Retag**, **On Album Delete**.
   - URL: `http://127.0.0.1:8096/Items/<music-id>/Refresh?Recursive=true&ApiKey=<jellyfin-key>`
   - Method: **POST**. **Test**, **Save**.
   - Lidarr only sends this for downloads it tracked; after a Manual Import,
     scan the Music library in Jellyfin by hand.
5. **Settings → General:** copy the API key (the **Lidarr key**).

## 6. Prowlarr: `https://prowlarr.home.anandrajaram.dev`

1. First open: **Forms (Login Page)**, **Enabled**, username and password.
2. **Settings → Indexers → + → FlareSolverr:** Name `FlareSolverr`, Tags
   `flaresolverr`, Host `http://127.0.0.1:8191`. **Test**, **Save**.
3. **Indexers → Add Indexer:** add each tracker with its login. For ones
   behind Cloudflare, add the tag `flaresolverr`. **Test**, **Save**.
4. **Settings → Apps → +**, once each. **Test**, **Save**:

   | App | Prowlarr Server | Server | API Key | Sync Level |
   |---|---|---|---|---|
   | Sonarr | `http://127.0.0.1:9696` | `http://127.0.0.1:8989` | Sonarr key | Full Sync |
   | Radarr | `http://127.0.0.1:9696` | `http://127.0.0.1:7878` | Radarr key | Full Sync |
   | Lidarr | `http://127.0.0.1:9696` | `http://127.0.0.1:8686` | Lidarr key | **Add and Remove Only** |

5. **Indexers → Sync App Indexers.** The indexers appear in all three apps.
6. Music comes from Soulseek first: in **Lidarr → Settings → Indexers**, open
   each indexer Prowlarr added, untick **Enable RSS** and **Enable Automatic
   Search**, keep **Enable Interactive Search**, **Save**. (Add and Remove
   Only stops Prowlarr from switching these back on.)

## 7. Bazarr: `https://bazarr.home.anandrajaram.dev`

1. **Settings → General → Security:** Authentication **Form**, username and
   password. **Save** (top).
2. **Settings → Sonarr:** tick **Enabled**. Address `127.0.0.1`, Port `8989`,
   API Key: Sonarr key, untick **SSL**. **Test**, **Save**.
3. **Settings → Radarr:** same with Port `7878` and the Radarr key.
4. **Settings → Languages:**
   - **Languages Filter:** add your languages.
   - **Languages Profiles → Add New Profile:** name it (e.g. `English`), add
     the languages, **Save**.
   - **Default Settings:** tick **Series** and **Movies**, pick that profile
     for both. **Save**.
5. **Settings → Providers → +:** add providers (OpenSubtitles.com needs a free
   account; Podnapisi needs none). **Save**.

## 8. Seerr: `https://seerr.home.anandrajaram.dev`

1. **Configure Jellyfin:** URL `http://127.0.0.1:8096` (hostname `127.0.0.1`,
   port `8096`, SSL off), any email, your Jellyfin admin username and
   password. **Sign In**.
2. **Sync Libraries**, tick **Movies** and **Shows**, **Continue**.
3. **Add Radarr Server:** tick **Default Server**, name `Radarr`, hostname
   `127.0.0.1`, port `7878`, SSL off, API key: Radarr key. **Test**, then
   Quality Profile (your choice), Root Folder `/data/media/movies`, Minimum
   Availability **Released**. Tick **Enable Scan**. **Add Server**.
4. **Add Sonarr Server:** tick **Default Server**, hostname `127.0.0.1`, port
   `8989`, API key: Sonarr key. **Test**, Quality Profile, Root Folder
   `/data/media/tv`, tick **Season Folders** and **Enable Scan**. **Add Server**.
5. **Finish Setup**.

## 9. slskd: `https://slskd.home.anandrajaram.dev`

1. Make an API key for Soularr (on any machine): `openssl rand -hex 24`.
2. Sign in as `slskd` / `slskd`.
3. **System → Options → Edit.** Add or replace these sections (YAML; keep the
   indentation):

   ```yaml
   soulseek:
     username: <soulseek username>   # a new name creates the account on first login
     password: <soulseek password>
     listen_port: 50300
   directories:
     downloads: /data/slskd/downloads
     incomplete: /data/slskd/incomplete
   shares:
     directories:
       - /data/media/music
   web:
     authentication:
       username: altf4
       password: <new password>
       api_keys:
         soularr:
           key: <the key from step 1>
           role: readwrite
   ```

4. **Save**. If it shows a restart-required banner:
   `sudo systemctl restart podman-slskd`.
5. Sign in again as `altf4`. The header shows it connected to Soulseek; the
   music share is scanned in the background.

## 10. Soularr (no UI)

1. On saturn: `nano /var/lib/soularr/config.ini`, paste the template below,
   and fill in `[Lidarr] api_key` (Lidarr key) and `[Slskd] api_key` (from
   slskd step 1).
2. `sudo systemctl restart podman-soularr`, then watch it with
   `journalctl -u podman-soularr -f`. It reports "No releases wanted" until
   Lidarr has monitored albums. It doesn't start at all until
   `config.ini` exists.

```ini
[Lidarr]
api_key = <lidarr api key>
host_url = http://127.0.0.1:8686
download_dir = /data/slskd/downloads
disable_sync = False

[Slskd]
api_key = <slskd api key>
host_url = http://127.0.0.1:5030
url_base = /
download_dir = /downloads
delete_searches = False
stalled_timeout = 3600
remote_queue_timeout = 300

[Release Settings]
use_selected_lidarr_release = False
use_most_common_tracknum = True
allow_multi_disc = True
accepted_countries = Europe,Japan,United Kingdom,United States,[Worldwide],Australia,Canada
skip_region_check = False
accepted_formats = CD,Digital Media,Vinyl

[Search Settings]
search_timeout = 5000
maximum_peer_queue = 50
minimum_peer_upload_speed = 0
minimum_filename_match_ratio = 0.8
minimum_search_interval = 5
search_retry_wait_hours = 0
allowed_filetypes = flac 16/44.1,flac,mp3 320,mp3
ignored_users =
album_prepend_artist = True
search_type = incrementing_page
number_of_albums_to_grab = 10
title_blacklist =
search_blacklist =
search_source = missing
failed_import_denylist = True
ignore_failed_users = False
failed_user_ignore_hours = 168

[Download Settings]
download_filtering = True
use_extension_whitelist = False
extensions_whitelist = lrc,nfo,txt
rename_download_folders = True

[Logging]
level = INFO
format = [%(levelname)s|%(module)s|L%(lineno)d] %(asctime)s: %(message)s
datefmt = %Y-%m-%dT%H:%M:%S%z
log_to_file = True
log_file = soularr.log
max_bytes = 1048576
backup_count = 3
```

## 11. Test the chain

1. Request a movie in Seerr: it shows in Radarr, downloads in qBittorrent,
   then appears in Jellyfin. Same for a show through Sonarr.
2. Add an artist in Lidarr with a monitored album: within 5 minutes Soularr
   searches Soulseek, the download shows in slskd, Lidarr imports it, and
   Jellyfin rescans.
3. Force a transcode in Jellyfin (play a video at a lower quality): on
   saturn, `nvidia-smi` lists a `jellyfin-ffmpeg` process.
4. On the TV, add the server by address: `http://192.168.0.69:8096`.
