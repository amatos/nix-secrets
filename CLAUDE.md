# nix-secrets — project directives

## Agent conventions

Any message prefixed with `question:` is a purely theoretical/discussion
request. Treat it as a request for information, reasoning, or discussion
only — **never** as an instruction to perform an action (no file edits,
commits, deployments, or other side effects), regardless of how the rest
of the phrasing reads.

## What this is

nix-secrets holds sops-encrypted **text** secrets (SSH keys, tokens, passwords, `.ini`
credentials) for the [nixie](https://github.com/amatos/nixie) NixOS + nix-darwin
configuration. It is a plain git repo, not a flake (`flake = false` in nixie's
`flake.nix`), referenced there as the `nix-secrets` input.

All files are encrypted with [sops](https://github.com/getsops/sops) (via
[sops-nix](https://github.com/Mic92/sops-nix) on the consuming/nixie side), using
[age](https://github.com/FiloSottile/age) as the underlying crypto backend, and
decryptable only by the recipients declared in `.sops.yaml`.

**Binary secrets do not belong here.** Git diffs binary files poorly and they don't
share this repo's plaintext-editing workflow. Kerberos keytabs live in the dedicated
[`nix-keytabs-matos-cc`](https://github.com/amatos/nix-keytabs-matos-cc) repo instead. If a new
binary secret type is needed, create another dedicated repo following that pattern —
don't add it here.

---

## Layout

```text
.sops.yaml                # recipients (who can decrypt what) — path_regex rules
age-yubikey-identity-*.txt # YubiKey identity stubs, not the keys
*.yaml                     # sops-encrypted multi-key text secrets, one file
                            # per subsystem/group (fleet-secrets.yaml,
                            # ldap.yaml, ghostty-themes.yaml, ...)
keytab-*.age                # sops-encrypted binary Kerberos keytabs (still
                             # named .age by convention — see
                             # nix-keytabs-matos-cc for the rest of this type)
```

Unlike the old per-file-per-secret layout, sops's native multi-key YAML documents mean related
secrets that share a recipient set live together in one file (e.g. `fleet-secrets.yaml` holds
`github-ratelimit`, `tailscale-authkey`, `cachix-authtoken`, ... as top-level keys) rather than
one `.age` file per secret. Check whether an existing file already covers the right recipient
scope before creating a new one.

## Recipients

Defined in `.sops.yaml`'s `keys:` list as YAML anchors, referenced from each rule's
`key_groups`:

- `alberth` — an offline recovery key, no hardware.
- Seven YubiKey identities (`yubikey_d43f4e92`, `yubikey_2ab5ff2f`, `yubikey_be7a2b66`,
  `yubikey_49705840`, `yubikey_7cb1cad0`, `yubikey_b4d67c6f`, `yubikey_0634d1c4`). Six require a
  touch + PIN each session; `yubikey_0634d1c4` is provisioned with PIN policy **Never** and touch
  policy **Never** specifically so it can decrypt non-interactively (scripted/agent use) — treat
  it as a safe default identity for command-line `sops`/`age` invocations that can't prompt for a
  touch, but not as a substitute for the others when a human is actually present.
- One `*<host>_ssh` anchor per nixie host that needs to decrypt at activation time (`codex_ssh`,
  `gammu_ssh`, `porkchop_ssh`, `huginn_ssh`, `muninn_ssh`, ...) — each is that host's real SSH
  host key (`/etc/ssh/ssh_host_ed25519_key.pub`) converted to age's X25519 form via `ssh-to-age`.
  This **must** be the converted `age1...` string, not the raw `ssh-ed25519 AAAA...` public key —
  sops-nix's `sops-install-secrets` converts the SSH private key internally and matches against
  the converted form; a raw SSH key string only works with unrelated `age -R`/`-i sshkey` CLI
  paths, not the real nixie deploy path. There is no separate host identity file or generation
  step anymore — the SSH host key doubles as the decryption identity directly, since
  `sops.age.sshKeyPaths` (sops-nix's option for this) defaults to the host's SSH host key
  whenever `services.openssh.enable` is true, which every nixie host already sets.

The seven YubiKey identity stubs are stored in
`age-yubikey-identity-{2ab5ff2f,49705840,7cb1cad0,b4d67c6f,be7a2b66,d43f4e92,0634d1c4}.txt`, one
per physical key (these are stub/pointer files for `age-plugin-yubikey`, not the private keys
themselves). `alberth`'s recovery key has no hardware component and is kept offline.

---

## Creating a new secret

**Prerequisites:** YubiKey inserted (unless using the non-interactive `yubikey_0634d1c4`
identity); `sops`/`age`/`ssh-to-age` available (they're in nixie's devShell:
`nix develop /path/to/nixie`).

1. **Confirm (or add) a `.sops.yaml` rule** covering the target filename — check for an existing
   `path_regex` rule with the right recipient scope before inventing a new one. If this secret
   needs its own narrower recipient set, add a new rule (keep the fleet-wide catch-all `.*` rule
   last — sops uses first-matching-rule-wins).

2. **Create (or edit) the encrypted file:**

   ```bash
   cd /path/to/nix-secrets
   sops my-new-secrets.yaml
   ```

   This opens `$EDITOR` on the decrypted plaintext (or a blank document for a new file). Edit as
   plain YAML (one top-level key per secret if grouping several together), save, close. `sops`
   re-encrypts to every recipient in the matching `.sops.yaml` rule. Touch the YubiKey when
   prompted (LED blinks), unless using the non-interactive identity.

3. **Wire it into nixie** — in the appropriate nixie module (usually `modules/common/` for
   cross-platform secrets), add a `sops.secrets` entry:

   ```nix
   sops.secrets.my-new-secret = {
     sopsFile = "${nix-secrets}/my-new-secrets.yaml";
     key = "my-new-secret";  # the YAML key inside the file
     owner = "alberth";      # optional; defaults to root
     mode = "0400";          # optional
   };
   ```

   Reference the decrypted path elsewhere as `config.sops.secrets.my-new-secret.path`
   (`/run/secrets/my-new-secret` by default). See nixie's `CLAUDE.md` ("Wiring an external
   secrets repo into nixie") for the full pattern, including adding the input/specialArgs if this
   is the first secret nixie consumes from this repo.

4. **Commit both repos:**

   ```bash
   # nix-secrets
   git add my-new-secrets.yaml .sops.yaml
   git commit -S -m "feat: add my-new-secret"
   git push

   # nixie — commit the module changes that reference the new secret
   ```

---

## Updating an existing secret's content

No recipient change needed — just re-open and re-encrypt in place:

```bash
cd /path/to/nix-secrets
sops fleet-secrets.yaml
```

Edit the value(s), save, close. `sops` re-encrypts to the same recipients already in
`.sops.yaml`. Commit as usual.

For a scripted/non-interactive update (e.g. rotating a token programmatically), decrypt to a
temp file, edit the specific key, then encrypt back in place — `sops -e -i <file>` after
overwriting the plaintext, **not** a shell redirect (`sops -e <file> > <file>`), since `sops`
matches `.sops.yaml`'s `path_regex` against the *input* path — a redirect target isn't seen by
the matcher and can silently pick the wrong (usually the fleet-wide catch-all) recipient rule.

---

## Adding a recipient to an existing secret

1. Add the new key to `.sops.yaml`'s `keys:` list (a new `&<host>_ssh` anchor for a new host, per
   "Recipients" above), then reference that anchor from the relevant rule's `key_groups`.
2. Re-encrypt the affected file's data key for the new recipient set — this does **not** require
   decrypting/re-encrypting the actual secret content:

   ```bash
   sops updatekeys my-new-secrets.yaml
   ```

   Touch the YubiKey when prompted (once per file). Repeat for every file the new recipient needs.
3. Commit and push.

## Removing a recipient

Same mechanism, reversed:

1. Delete the key from `.sops.yaml`'s `key_groups` (and the `keys:` anchor, if nothing else
   references it).
2. `sops updatekeys <file>` for each affected file.
3. Commit and push.

**This does not rotate the secret's value.** A removed recipient who already decrypted the file
could have retained a plaintext copy — `sops updatekeys` only changes who can decrypt *future*
copies of the file. If the removal is security-motivated (e.g. offboarding, key compromise),
rotate the underlying secret value separately.

---

## Decrypting a secret manually

```bash
sops --decrypt fleet-secrets.yaml
```

Uses whichever age identity file(s) `sops` finds via `SOPS_AGE_KEY_FILE`/`age`'s default identity
discovery, or pass one explicitly:

```bash
export SOPS_AGE_KEY_FILE=age-yubikey-identity-d43f4e92.txt
sops --decrypt fleet-secrets.yaml
```

Touch the YubiKey when prompted (skip for `age-yubikey-identity-0634d1c4.txt`, the
non-interactive safe identity — see "Recipients" above). For a binary secret (a keytab), add
`--input-type binary --output-type binary`.

---

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `chore:`, etc.), matching nixie's style, enforced by the same
  commitlint/markdownlint-cli2/nixfmt pre-commit hooks as nixie (`flake.nix`,
  `.commitlintrc.yaml`) — run `nix develop` once to install them.
- All commits must be GPG-signed (`git commit -S`), matching nixie's requirement.
  Enforced in CI by the `verify-signed-commits` job in `.github/workflows/ci.yml`.
- Never commit decrypted plaintext (`.gitignore` excludes `*.dec`) — double-check before
  `git add -A` after manual decryption for debugging.
- Keep `README.md`'s Recipients and Secrets tables in sync with `.sops.yaml` and the
  files actually present whenever either changes.

## Releases

Releases use CalVer, matching nixie: `yy.mm.release` (e.g. `26.07.01`).

- The release counter resets to `01` at the start of each new month.
- Tags are GPG-signed: `git tag -s yy.mm.release -m "Release yy.mm.release"`.
- Before tagging, check the highest existing tag for the month:
  `git tag --list 'yy.mm.*' | sort`
- Combine all changes since the last release into a single `CHANGELOG.md`
  entry named after the tagged version.

## Before making changes

1. Check whether the secret is binary — if so it belongs in `nix-keytabs-matos-cc`
   (or another dedicated repo), not here.
2. Check `.sops.yaml` before adding a new rule/anchor — the recipient scope you need
   (the YubiKey identities, a specific host's `*_ssh` anchor, the fleet-wide catch-all, ...) may
   already exist.
3. After adding, updating, or re-keying a secret, update the corresponding nixie module in the
   same change set so the two repos don't drift.
