# Scope: NixOS system (Soularr container: fills Lidarr's wanted albums from Soulseek through slskd; no web UI) | Used by: saturn
{ config, ... }:

let
  data = config.media.dataDir;
  state = "/var/lib/soularr";
in
{
  virtualisation.podman.enable = true;

  virtualisation.oci-containers.containers.soularr = {
    image = "docker.io/mrusse08/soularr:latest";
    user = "1000:${toString config.users.groups.media.gid}";
    environment = {
      TZ = config.time.timeZone;
      SCRIPT_INTERVAL = "300";
      WEBUI_ENABLED = "false";
    };
    volumes = [
      "${state}:/data"
      "${config.sops.templates."soularr.ini".path}:/data/config.ini:ro"
      "${data}/slskd/downloads:/downloads"
    ];
    extraOptions = [ "--network=host" ];
  };

  systemd.tmpfiles.rules = [ "d ${state} 0750 1000 media -" ];
  systemd.services.podman-soularr.unitConfig.RequiresMountsFor = [ data ];
  # Restart on switch when the template or its encrypted secrets change.
  systemd.services.podman-soularr.restartTriggers = [
    config.sops.templates."soularr.ini".content
  ]
  ++ map (s: builtins.hashFile "sha256" config.sops.secrets.${s}.sopsFile) [
    "lidarr_api_key"
    "slskd_api_key"
  ];

  # Lidarr imports the same folder Soularr sees as /downloads.
  sops.templates."soularr.ini" = {
    owner = "altf4";
    content = ''
      [Lidarr]
      api_key = ${config.sops.placeholder.lidarr_api_key}
      host_url = http://127.0.0.1:8686
      download_dir = ${data}/slskd/downloads
      disable_sync = False

      [Slskd]
      api_key = ${config.sops.placeholder.slskd_api_key}
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
    '';
  };
}
