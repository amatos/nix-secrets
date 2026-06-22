let
  # YubiKey identity — matches identityPaths in nix-config
  alberth = "age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y";
  codex   = "age1rx38js86awlvzvm99x8qhnhd42cn9ytcudgqzm44u9qk9g79kqhs9jktky";
  gammu   = "age1c2cmluquave5rmzequv7tea7c8zvt37yuml57vcd9qvvlla98qvsww99w0";

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
