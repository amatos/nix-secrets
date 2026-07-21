# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

---

## 26.07.07

### Added

- `secrets.nix` — added `builder/codex-ssh-key.age`, an SSH private key
  letting codex (aarch64-darwin) connect to gammu's `remotebuild` user as
  a remote `x86_64-linux` builder, needed since nix-darwin's own
  `nix.buildMachines` is inert under Determinate.
- `secrets.nix` — added the `muninn` recipient key.

### Changed

- `secrets.nix` — scoped `smtp-relay-sasl.age` to a new `smtpSmartRelays`
  group (previously the broad `users`+`systems` group granted every host
  decrypt access regardless of whether it ran the relay); all secrets
  re-encrypted (`ragenix --rekey`) accordingly.
- `secrets.nix` — added `muninn` to `ldapHosts` (Stage 2 of nixie's
  porkchop service realignment, ARCHITECTURE.md §10) and split
  `unifi/backup-ssh-key.age` out into its own `unifiBackupHosts` group —
  it had been piggybacking on `ldapHosts` only because porkchop happened
  to be in both; all secrets re-encrypted (`ragenix --rekey`) accordingly.
- `secrets.nix` — dropped porkchop from `ldapHosts` (Stage 4: its
  Kerberos+LDAP role is decommissioned, muninn is now the sole entry) and
  revoked its decrypt access to `ldap/admin-password.age`,
  `ldap/kdc-password.age`, `ldap/krb5-master-key.age` (`ragenix --rekey`).
- `secrets.nix` — added huginn to `smtpSmartRelays` (Stage 5: huginn is
  now the primary SMTP relay, porkchop the backup) and granted it decrypt
  access to `smtp-relay-sasl.age` (`ragenix --rekey`).

### Fixed

- `README.md` — Recipients table had codex's pre-rotation age key (no
  longer matching `secrets.nix`) and was missing a row for muninn.

---

## 26.07.06

### Added

- `.github/workflows/ci.yml` — new CI, `verify-signed-commits` job fails the
  build if any commit in a push/PR has no GPG signature (`git log
  --pretty=%G?`).

### Changed

- `CLAUDE.md` "Conventions" — now requires GPG-signed commits, matching
  nixie's requirement (previously only release tags were documented as
  signed), and documents the new CI enforcement; example `git commit`
  commands updated to `git commit -S`.

---

## 26.07.05

### Added

- `shell.nix` — classic `nix-shell` environment (`rage`, `age`,
  `age-plugin-yubikey`, `git`) for working with age/YubiKey identities
  directly in this repo; documented in README "Development shell".
- `users/alberth.age`, `users/nixos.age` — login passwords for the
  `alberth` and `nixos` user accounts.

### Fixed

- README "Recipients" table was missing `yubikeyb4d67c6f`, added in
  755ba83 but never reflected in the docs.

### Changed

- `flake.nix` — dropped the unused `self` function arg flagged by nixd.
- Grouped related secrets into subdirectories: `github-ssh-key.age` →
  `github/ssh-key.age`, `github-ratelimit.age` → `github/ratelimit.age`,
  `unifi-api-key.age` → `unifi/api-key.age`, `unifi-backup-ssh-key.age` →
  `unifi/backup-ssh-key.age`, `ldap-admin-password.age` →
  `ldap/admin-password.age`, `ldap-kdc-password.age` →
  `ldap/kdc-password.age`, `krb5-master-key.age` →
  `ldap/krb5-master-key.age`. Matches the `ghostty-themes/` convention:
  group once a subsystem has 2+ related files, leave singletons flat.
  Consumers in `nixie` and `nix-kerberos-ldap` updated accordingly.

---

## 26.07.04

### Added

- `.envrc` (`use flake`) — direnv now loads the devShell automatically on
  `cd`; documented in README "Development shell".

---

## 26.07.03

### Changed

- `secrets.nix` — rotated the `codex` host recipient key; all secrets
  re-encrypted (`ragenix --rekey`) accordingly

---

## 26.07.02

### Added

- `age-yubikey-identity-b4d67c6f.txt` — YubiKey identity for `b4d67c6f`
- `flake.nix`/`flake.lock` — pre-commit tooling only (`nixpkgs`,
  `pre-commit-hooks`), no system builds; same `nixfmt`/`markdownlint-cli2`/
  `commitlint` hook set as nixie, installed via `nix develop`
- `.commitlintrc.yaml` — copied from nixie so the new `commitlint` hook has
  rules to enforce
- `.gitignore` — added `/.direnv`, `/result`, `/.pre-commit-config.yaml`,
  `/.claude`, matching nixie's, now that this repo has its own Nix dev
  tooling to generate them
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

- `flake.nix` — dropped `x86_64-darwin` from `supportedSystems`; that
  platform/architecture combination is being deprecated
- `secrets.nix` — rotated the primary `alberth` recipient away from
  the original YubiKey (`age-yubikey-identity-9ca1fbf9.txt`) to the
  new recipient set above; all secrets re-encrypted (`ragenix
  --rekey`) accordingly
- All five current YubiKey identities require a PIN once per session
  (`PIN policy: Once`), unlike the retired identity (`PIN policy:
  Never`) — `README.md` updated to reflect this
- `README.md` — Recipients table and identity-stub references synced
  with the new recipient set in `secrets.nix`
- `README.md` — reflowed the intro paragraph and warning list, and added
  a blank line before "## Recipients"; pre-existing formatting the new
  `markdownlint-cli2` hook now catches
- `CLAUDE.md` — Conventions note updated: commit messages are now
  actually enforced by the new commitlint hook, not just followed by
  convention
- `CLAUDE.md` — `Layout` section referenced the retired
  `age-yubikey-identity-9ca1fbf9.txt` stub (removed below); replaced with
  the `age-yubikey-identity-*.txt` glob so it doesn't go stale on the next
  key rotation, matching `keytabs-matos-cc/CLAUDE.md`'s existing pattern

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
