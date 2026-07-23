let
  alberth = "age1gp5d3tzdpufcrk7f6dkr92xtx2p847k79kxxdp9nn0yjk2qvw34sws84m7";
  yubikey0634d1c4 = "age1yubikey1qv0utu8hcayj3xeppwjuckzmrgd0ltjuq59ffmwd6t9f2m7depa2sl0ne87";
  yubikey2ab5ff2f = "age1yubikey1qtn8y2ad0vr9ddazfsxy4fmlt64kknhjsll2xvfgekck3n0dc0xjvf5rah6";
  yubikeybe7a2b66 = "age1yubikey1qgmkn4s840hwg4kfazjn6u4r2nq9utl60chscraq4sqg9jsf0wleu5eldvv";
  yubikey49705840 = "age1yubikey1qtkf5924nev2a5vqncdurp729tq6xmdf27y6x95fv7kk5zje5vqr6umpnj8";
  yubikey7cb1cad0 = "age1yubikey1q0pmgm34s0ckw8jj9auzlvm5mc6mpxxgc5syu0aw55cqu2hnm7krqrnq60a";
  yubikeyb4d67c6f = "age1yubikey1qt9a6xc0nzpe484kzeuw55hsm4shu3ug9j6m4ngtsexqrgptd6zfx596dqn";

  users = [
    alberth
    yubikey2ab5ff2f
    yubikey0634d1c4
    yubikeybe7a2b66
    yubikey49705840
    yubikey7cb1cad0
    yubikeyb4d67c6f
  ];
in
# No secrets currently declared — ldap/*.age (the last group here) was
# deleted once ldap.yaml (sops-encrypted, consolidated in Step 13) fully
# replaced it (SOPS_MIGRATION.md Step 27, after Phase 5's real cutover
# validated the replacement live on muninn). The per-host age keys
# (codex/gammu/porkchop/huginn/muninn) this group used are gone too — every
# other group had already migrated off them in earlier phases. `users` kept
# for whenever a new ragenix-only secret needs this repo again.
{ }
