# agenix secret registry
#
# Each attribute key matches an encrypted file that lives in the
# nix-secrets repo (github:amatos/nix-secrets).  The value lists the
# age recipients that can decrypt it — typically the host SSH host key
# and/or a personal age key.
#
# Workflow:
#   1. Add the public key(s) below.
#   2. Add the secret name and its recipients here.
#   3. Run: agenix -e secrets/<name>.age   (inside the nix-secrets repo)
#   4. Commit & push the nix-secrets repo.
#   5. Reference the secret in your host config via age.secrets.<name>.
#
# See https://github.com/ryantm/agenix for full docs.

let
  # ── personal age key ──────────────────────────────────────────────────────
  # Generate with: age-keygen
  alberth = "age1252r27y35ckgtn9ut42j8x7az8mk6y28j0efgxcd0k0h09g46djspfz2lw";
  yubikey0634d1c4 = "age1yubikey1qv0utu8hcayj3xeppwjuckzmrgd0ltjuq59ffmwd6t9f2m7depa2sl0ne87";
  yubikey2ab5ff2f = "age1yubikey1qtn8y2ad0vr9ddazfsxy4fmlt64kknhjsll2xvfgekck3n0dc0xjvf5rah6";
  yubikeybe7a2b66 = "age1yubikey1qgmkn4s840hwg4kfazjn6u4r2nq9utl60chscraq4sqg9jsf0wleu5eldvv";
  yubikey49705840 = "age1yubikey1qtkf5924nev2a5vqncdurp729tq6xmdf27y6x95fv7kk5zje5vqr6umpnj8";
  yubikey7cb1cad0 = "age1yubikey1q0pmgm34s0ckw8jj9auzlvm5mc6mpxxgc5syu0aw55cqu2hnm7krqrnq60a";
  yubikeyb4d67c6f = "age1yubikey1qt9a6xc0nzpe484kzeuw55hsm4shu3ug9j6m4ngtsexqrgptd6zfx596dqn";

  # ── host SSH keys (age can use ed25519 SSH keys directly) ─────────────────
  # Use the raw "ssh-ed25519 AAAA..." public key text (e.g. from
  # /etc/ssh/ssh_host_ed25519_key.pub), NOT an ssh-to-age-converted bech32
  # string: `age -i <sshkey>` only matches the ssh-ed25519-typed stanza that
  # results from encrypting to the raw key text. Encrypting to the converted
  # bech32 form produces a generic X25519 stanza that age's SSH identity
  # matching never recognizes, so it silently fails to decrypt at runtime.
  # exampleHost = "ssh-ed25519 AAAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  codex = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII/ZypHOYRSYn7VyKOqg14V/cclBs9PrApCTT9x4ygr";
  muninn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnw8CzTXukohE1iQu3LBAJlpAxJWGCLfOpRcWWK8Frg";
  huginn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP2lcyzbIlMHZ0cbz6VP6IDoHduNCG2RAB+1grAcmS51";

  allHosts = [
    codex
    muninn
    huginn
  ];

  allYubikeys = [
    yubikey2ab5ff2f
    yubikey0634d1c4
    yubikeybe7a2b66
    yubikey49705840
    yubikey7cb1cad0
    yubikeyb4d67c6f
  ];

  allKeys = [ alberth ] ++ allHosts ++ allYubikeys;

in
{
  # ── secrets ───────────────────────────────────────────────────────────────
  # "example-password.age".publicKeys = [ alberth ] ++ allHosts;
  "services/certbot-luadns.age".publicKeys = allKeys;
  "services/github-ratelimit.age".publicKeys = allKeys;
  "services/smtp-relay-sasl-fastmail.age".publicKeys = allKeys;
  "services/syncthing-gui-password.age".publicKeys = allKeys;
  "services/syncthing-gui-userid.age".publicKeys = allKeys;
  "services/tailscale-authkey.age".publicKeys = allKeys;
  "services/dyndns-luadns.age".publicKeys = allKeys;
  "services/unifi-api.age".publicKeys = allKeys;
  "ssh/github-ssh-key.age".publicKeys = allKeys;
  "users/alberth-password.age".publicKeys = allKeys;
  "users/nixos-password.age".publicKeys = allKeys;
}
