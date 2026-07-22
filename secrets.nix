let
  alberth = "age1gp5d3tzdpufcrk7f6dkr92xtx2p847k79kxxdp9nn0yjk2qvw34sws84m7";
  yubikeyd43f4e92 = "age1yubikey1qdxkz5rs00du7y4284ehlkktq0h93wsqszwegjrx97scqs8ptq3f6kws7sq";
  yubikey2ab5ff2f = "age1yubikey1qtn8y2ad0vr9ddazfsxy4fmlt64kknhjsll2xvfgekck3n0dc0xjvf5rah6";
  yubikeybe7a2b66 = "age1yubikey1qgmkn4s840hwg4kfazjn6u4r2nq9utl60chscraq4sqg9jsf0wleu5eldvv";
  yubikey49705840 = "age1yubikey1qtkf5924nev2a5vqncdurp729tq6xmdf27y6x95fv7kk5zje5vqr6umpnj8";
  yubikey7cb1cad0 = "age1yubikey1q0pmgm34s0ckw8jj9auzlvm5mc6mpxxgc5syu0aw55cqu2hnm7krqrnq60a";
  yubikeyb4d67c6f = "age1yubikey1qt9a6xc0nzpe484kzeuw55hsm4shu3ug9j6m4ngtsexqrgptd6zfx596dqn";
  codex = "age1yl42nc3qmtper3vt7am3f2u6f2afp7scu2nqxfqjlw4qn64qeaqq20xkcc";
  gammu = "age12vhj5z6zepnz7uyzks23p6rgwa7rudja7ectsrl89zf96nnmfcnq264972";
  porkchop = "age1yegmaunkewrxj3v6lt86nalta0xq5gq7dpcxrggqp8p7nlzdde4qsnq5jz";
  huginn = "age1je5xg9s90g8l0307xpphclxj3fugvkl59ne9yna46lne9fw0wfpq59lzux";
  muninn = "age1hryy6kdlt3ufej07r9rp2g8x8pm0e6ndgdyke6jdq95uchnjdghqprayh9";

  users = [
    alberth
    yubikey2ab5ff2f
    yubikeyd43f4e92
    yubikeybe7a2b66
    yubikey49705840
    yubikey7cb1cad0
    yubikeyb4d67c6f
  ];
  systems = [
    codex
    gammu
    porkchop
    huginn
    muninn
  ];
  # Hosts that run Syncthing
  syncthingHosts = [
    codex
    gammu
    porkchop
    huginn
    muninn
  ];
  # ldap/*.age secrets — needed by every host currently running the KDC/LDAP
  # server role. muninn is now the sole KDC/LDAP host — porkchop was dropped
  # after Stage 4 of the migration in nixie's ARCHITECTURE.md §10.
  ldapHosts = [
    muninn
  ];
  # unifi/backup-ssh-key.age — split out from ldapHosts, since unifi-backup
  # runs on porkchop for reasons unrelated to whether it also hosts LDAP.
  unifiBackupHosts = [
    porkchop
  ];
  # Hosts that provide SMTP smarthost/relay services — huginn (primary) and
  # porkchop (backup), per Stage 5/6 of nixie's ARCHITECTURE.md §10.
  smtpSmartRelays = [
    porkchop
    huginn
  ];
  # Hosts that act as a Nix remote-build client (i.e. need the SSH private
  # key for a remote builder). Not the builder itself — gammu only needs the
  # (non-secret) public key, inlined directly in nixie.
  remoteBuildHosts = [
    codex
  ];
  # Hosts that run Grafana (Stage 7b of nixie's ARCHITECTURE.md §10 —
  # centralized log review UI on top of the porkchop syslog receiver).
  grafanaHosts = [
    porkchop
  ];
in
{
  "github/ssh-key.age".publicKeys = users ++ systems;
  "github/ratelimit.age".publicKeys = users ++ systems;
  "luadns.ini.age".publicKeys = users ++ systems;
  "tailscale-authkey.age".publicKeys = users ++ systems;
  "cachix-authtoken.age".publicKeys = users ++ systems;
  "default-nixos-user-password.age".publicKeys = users ++ systems;
  "syncthing-gui-password.age".publicKeys = users ++ syncthingHosts;
  "smtp-relay-sasl.age".publicKeys = users ++ smtpSmartRelays;
  "ldap/admin-password.age".publicKeys = users ++ ldapHosts;
  "ldap/kdc-password.age".publicKeys = users ++ ldapHosts;
  "ldap/krb5-master-key.age".publicKeys = users ++ ldapHosts;
  "unifi/api-key.age".publicKeys = users ++ systems;
  "unifi/backup-ssh-key.age".publicKeys = users ++ unifiBackupHosts;
  "builder/codex-ssh-key.age".publicKeys = users ++ remoteBuildHosts;
  "grafana-secret-key.age".publicKeys = users ++ grafanaHosts;
  "ghostty-themes/alucard.age".publicKeys = users ++ systems;
  "ghostty-themes/blade.age".publicKeys = users ++ systems;
  "ghostty-themes/buffy.age".publicKeys = users ++ systems;
  "ghostty-themes/dracula.age".publicKeys = users ++ systems;
  "ghostty-themes/lincoln.age".publicKeys = users ++ systems;
  "ghostty-themes/morbius.age".publicKeys = users ++ systems;
  "ghostty-themes/pro.age".publicKeys = users ++ systems;
  "ghostty-themes/van-helsing.age".publicKeys = users ++ systems;
  "users/alberth.age".publicKeys = users ++ systems;
  "users/nixos.age".publicKeys = users ++ systems;
}
