let
  alberth = "age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y";
  codex = "age1786r092jkepdahryx7t9kru8txuvreh3f2pgtvrv3u5hmjxjjy3st9udnl";
  gammu = "age12vhj5z6zepnz7uyzks23p6rgwa7rudja7ectsrl89zf96nnmfcnq264972";
  porkchop = "age1yegmaunkewrxj3v6lt86nalta0xq5gq7dpcxrggqp8p7nlzdde4qsnq5jz";
  huginn = "age1je5xg9s90g8l0307xpphclxj3fugvkl59ne9yna46lne9fw0wfpq59lzux";

  users = [ alberth ];
  systems = [
    codex
    gammu
    porkchop
    huginn
  ];
  # Hosts that run Syncthing
  syncthingHosts = [
    codex
    gammu
    porkchop
    huginn
  ];
  ldapHosts = [
    porkchop
  ];
in
{
  "github-ssh-key.age".publicKeys = users ++ systems;
  "github-ratelimit.age".publicKeys = users ++ systems;
  "luadns.ini.age".publicKeys = users ++ systems;
  "tailscale-authkey.age".publicKeys = users ++ systems;
  "cachix-authtoken.age".publicKeys = users ++ systems;
  "default-nixos-user-password.age".publicKeys = users ++ systems;
  "syncthing-gui-password.age".publicKeys = users ++ syncthingHosts;
  "smtp-relay-sasl.age".publicKeys = users ++ systems;
  "ldap-admin-password.age".publicKeys = users ++ ldapHosts;
  "ldap-kdc-password.age".publicKeys = users ++ ldapHosts;
  "krb5-master-key.age".publicKeys = users ++ ldapHosts;
  "unifi-api-key.age".publicKeys = users ++ systems;
}
