let
  # YubiKey identity — matches identityPaths in nix-config
  alberth = "age1yubikey1qvqh2pk2pnzdf5mlrzeeseyf9axnz2l7g0mzum8ex5kg08euf8sh2mxv69q";
  codex   = "age1rx38js86awlvzvm99x8qhnhd42cn9ytcudgqzm44u9qk9g79kqhs9jktky";

  users = [ alberth ];
  systems = [
    codex
  ];
in
{
  "github-ssh-key.age".publicKeys = users ++ systems;
  "github-ratelimit.age".publicKeys = users ++ systems;
  "luadns.ini.age".publicKeys = users;
}
