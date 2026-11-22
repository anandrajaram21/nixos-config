{ ... }:

{
  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.secrets.github_ssh_key.owner = "altf4";
}
