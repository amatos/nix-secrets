# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- `unifi-backup-ssh-key.age` — SSH private key for connecting to
  unifi.home.matos.cc, consumed by nixie's `modules/nixos/unifi-backup.nix`
  (`nixie.unifiBackup`, enabled on `porkchop`) to scp UniFi's autobackup
  directory to a local backup directory. The matching public key must be
  added to unifi.home.matos.cc's `root` `authorized_keys` separately —
  ragenix only manages the private half
- `secrets.nix` — added `"unifi-backup-ssh-key.age".publicKeys = users ++
  ldapHosts;` (currently just `porkchop`, the only host running the backup)

## 26.07.01

### Removed

- `keytab-codex.age`, `keytab-gammu.age`, `keytab-porkchop.age`,
  `keytab-ldap-porkchop.age` — moved to the dedicated
  `keytabs-matos-cc` repo; binary secrets no longer belong here

### Added

- `README.md` — note that binary secrets (e.g. Kerberos keytabs) belong
  in a dedicated repo instead of this one, with a pointer to
  `keytabs-matos-cc`
- `CLAUDE.md` — project directives covering the create/wire/commit/rekey
  workflow for text secrets, and the rule that binary secrets belong in
  `keytabs-matos-cc` instead
- `secrets.nix` — added `huginn` host age key as a recipient
- `unifi-api-key.age` — UniFi read-only API token for `nixie.dyndnsLuadns`

### Changed

- `README.md` — Secrets table updated to list only the files actually
  present in this repo (keytab entries removed)
- `README.md` — Recipients table was missing `huginn`, Secrets table was
  missing `unifi-api-key.age`; both added to match `secrets.nix`
