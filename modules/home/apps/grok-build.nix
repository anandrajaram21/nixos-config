# Scope: Home Manager (Grok Build config, merged into ~/.grok/config.toml on every switch; app in system/apps/grok-build.nix) | Used by: mercury, saturn
{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cliproxyUrl = osConfig.cliproxy.url;
  keyFile = osConfig.sops.secrets.cliproxyapi_api_key.path;

  authHelper = pkgs.writeShellScript "grok-cliproxy-auth" ''
    exec ${lib.getExe' pkgs.coreutils "tr"} -d '\r\n' < ${lib.escapeShellArg keyFile}
  '';

  patchFile = (pkgs.formats.toml { }).generate "grok-cliproxy.toml" {
    auth = {
      auth_provider_command = toString authHelper;
      auth_provider_label = "CLIProxyAPI";
    };
    endpoints = {
      models_base_url = "${cliproxyUrl}/v1";
      models_list_url = "${cliproxyUrl}/v1/models";
    };
  };

  python = pkgs.python3.withPackages (p: [ p.tomlkit ]);
  mergeToml = pkgs.writeScript "merge-grok-config.py" ''
    #!${lib.getExe python}
    import pathlib
    import sys
    import tomlkit

    target = pathlib.Path(sys.argv[1])
    patch = tomlkit.parse(pathlib.Path(sys.argv[2]).read_text())
    doc = tomlkit.parse(target.read_text()) if target.exists() and target.stat().st_size else tomlkit.document()

    for section, values in patch.items():
        table = doc.setdefault(section, tomlkit.table())
        for key, value in values.items():
            table[key] = value

    target.parent.mkdir(parents=True, exist_ok=True)
    tmp = target.with_suffix(".toml.tmp")
    tmp.write_text(tomlkit.dumps(doc))
    tmp.replace(target)
  '';
in
{
  home.activation.grokBuildSettings = lib.mkIf (cliproxyUrl != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -v DRY_RUN ]]; then
        ${mergeToml} "$HOME/.grok/config.toml" ${patchFile}
      fi
    ''
  );
}
