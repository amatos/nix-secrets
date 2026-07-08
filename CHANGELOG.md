# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- `LICENSE.md` — BSD 2-Clause License
- Five backup YubiKey identities added as recipients (`secrets.nix`
  `users`): `age-yubikey-identity-2ab5ff2f.txt`,
  `age-yubikey-identity-49705840.txt`,
  `age-yubikey-identity-7cb1cad0.txt`,
  `age-yubikey-identity-be7a2b66.txt` (new physical keys), and
  `age-yubikey-identity-d43f4e92.txt` (a re-keyed identity for the
  original YubiKey, serial 13125942, moved from slot 1 to slot 2)
- `secrets.nix` — added a plain, non-YubiKey `alberth` recovery key as
  an additional recipient alongside the five YubiKey identities above
- `unifi-backup-ssh-key.age` — SSH private key for connecting to
  unifi.home.matos.cc, consumed by nixie's `modules/nixos/unifi-backup.nix`
  (`nixie.unifiBackup`, enabled on `porkchop`) to scp UniFi's autobackup
  directory to a local backup directory. The matching public key must be
  added to unifi.home.matos.cc's `root` `authorized_keys` separately —
  ragenix only manages the private half
- `secrets.nix` — added `"unifi-backup-ssh-key.age".publicKeys = users ++
  ldapHosts;` (currently just `porkchop`, the only host running the backup)

### Changed

- `secrets.nix` — rotated the primary `alberth` recipient away from
  the original YubiKey (`age-yubikey-identity-9ca1fbf9.txt`) to the
  new recipient set above; all secrets re-encrypted (`ragenix
  --rekey`) accordingly
- All five current YubiKey identities require a PIN once per session
  (`PIN policy: Once`), unlike the retired identity (`PIN policy:
  Never`) — `README.md` updated to reflect this
- `README.md` — Recipients table and identity-stub references synced
  with the new recipient set in `secrets.nix`

### Removed

- `age-yubikey-identity-9ca1fbf9.txt` — retired YubiKey identity stub;
  the same physical key continues on as
  `age-yubikey-identity-d43f4e92.txt` (new slot, new PIN policy)

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
