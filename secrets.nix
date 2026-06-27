let
  # YubiKey identity — matches identityPaths in nix-config
  alberth = "age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y";
  codex = "age1786r092jkepdahryx7t9kru8txuvreh3f2pgtvrv3u5hmjxjjy3st9udnl";
  gammu = "age12vhj5z6zepnz7uyzks23p6rgwa7rudja7ectsrl89zf96nnmfcnq264972";
  porkchop = "age1yegmaunkewrxj3v6lt86nalta0xq5gq7dpcxrggqp8p7nlzdde4qsnq5jz";

  users = [ alberth ];
  systems = [
    codex
    gammu
  ];
in
{
  "github-ssh-key.age".publicKeys = users ++ systems;
  "github-ratelimit.age".publicKeys = users ++ systems;
  "luadns.ini.age".publicKeys = users ++ systems;
  "tailscale-authkey.age".publicKeys = users ++ systems;
  "cachix-authtoken.age".publicKeys = users ++ systems;
  "default-nixos-user-password.age".publicKeys = users ++ systems;
}
