let
  # YubiKey identity — matches identityPaths in nix-config
  alberth = "age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y";
  codex = "age1rx38js86awlvzvm99x8qhnhd42cn9ytcudgqzm44u9qk9g79kqhs9jktky";
  gammu = "age12vhj5z6zepnz7uyzks23p6rgwa7rudja7ectsrl89zf96nnmfcnq264972";

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
}
