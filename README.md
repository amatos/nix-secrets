# nix-secrets/README.md

This repository stores secrets required by the `nixie` configuration — both text (e.g. API
tokens, passwords) and binary (Kerberos keytabs). All files are encrypted with
[sops](https://github.com/getsops/sops) (via [sops-nix](https://github.com/Mic92/sops-nix) on
the consuming/nixie side), using [age](https://github.com/FiloSottile/age) as the underlying
crypto backend, and decryptable only by the recipients listed in `.sops.yaml`.

> **Note:** non-credential binary data (large files unrelated to authentication/secrets) should
> still be handled via dedicated tooling, not stored here — this repo is for secrets only,
> regardless of whether they're text or binary.

## Recipients

| Name | Type | Key |
| --- | --- | --- |
| `alberth` | Recovery key (offline, no hardware) | `age1gp5d3tzdpufcrk7f6dkr92xtx2p847k79kxxdp9nn0yjk2qvw34sws84m7` |
| `yubikey_2ab5ff2f` | YubiKey (touch + PIN) | `age1yubikey1qtn8y2ad0vr9ddazfsxy4fmlt64kknhjsll2xvfgekck3n0dc0xjvf5rah6` |
| `yubikey_be7a2b66` | YubiKey (touch + PIN) | `age1yubikey1qgmkn4s840hwg4kfazjn6u4r2nq9utl60chscraq4sqg9jsf0wleu5eldvv` |
| `yubikey_49705840` | YubiKey (touch + PIN) | `age1yubikey1qtkf5924nev2a5vqncdurp729tq6xmdf27y6x95fv7kk5zje5vqr6umpnj8` |
| `yubikey_7cb1cad0` | YubiKey (touch + PIN) | `age1yubikey1q0pmgm34s0ckw8jj9auzlvm5mc6mpxxgc5syu0aw55cqu2hnm7krqrnq60a` |
| `yubikey_b4d67c6f` | YubiKey (touch + PIN) | `age1yubikey1qt9a6xc0nzpe484kzeuw55hsm4shu3ug9j6m4ngtsexqrgptd6zfx596dqn` |
| `yubikey_0634d1c4` | YubiKey (PIN/touch Never — safe for non-interactive use) | `age1yubikey1qv0utu8hcayj3xeppwjuckzmrgd0ltjuq59ffmwd6t9f2m7depa2sl0ne87` |
| `codex_ssh` | codex's SSH host key, converted via `ssh-to-age` | `age1dq4gttszvhkf5j6kcvquggnc7a4vxrwgyk6k4ldxmmpekc7pzupqegqrdm` |
| `gammu_ssh` | gammu's SSH host key, converted via `ssh-to-age` | `age1c2cmluquave5rmzequv7tea7c8zvt37yuml57vcd9qvvlla98qvsww99w0` |
| `porkchop_ssh` | porkchop's SSH host key, converted via `ssh-to-age` | `age1qytulrl6hskztw95hzcjlwgyswzua9v38xrdl56phhctkudc2pxqlekktk` |
| `huginn_ssh` | huginn's SSH host key, converted via `ssh-to-age` | `age1j0plfmmtayqhn4dcce0h7z4fapyra2t22wjwk2e3vz57njf34p7qryg2yg` |
| `muninn_ssh` | muninn's SSH host key, converted via `ssh-to-age` | `age16vynhfk26c2z9tq6xh53skcwm4lqfwx5qr2cwjng3hlgj8hssp9qyncpnm` |

Six YubiKey identity stubs are stored in
`age-yubikey-identity-{2ab5ff2f,49705840,7cb1cad0,b4d67c6f,be7a2b66,0634d1c4}.txt`,
one per physical key. Five require **touch + PIN once per session**; `yubikey_0634d1c4` is
provisioned with both policies set to Never, specifically so scripted/agent commands can decrypt
without a human present — use it for non-interactive `sops`/`age` invocations, not as a
substitute for a real YubiKey when a human is at the keyboard. `alberth`'s recovery key has no
hardware component and is kept offline. (A seventh identity, `yubikey_d43f4e92`, was retired and
removed as a recipient from every secret via `sops updatekeys`; its stub file is gone too.)

Each `*_ssh` recipient is derived from that host's real SSH host key
(`ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`) — there is no separate host identity file or
generation step; sops-nix's `sops-install-secrets` converts the same SSH private key internally
at activation time via `sops.age.sshKeyPaths` and decrypts directly.

## Secrets

Related secrets that share a recipient set are grouped as multiple top-level keys inside one
sops-encrypted YAML file, rather than one file per secret. Binary content (keytabs) keeps the
`.age` extension by convention even though it's sops's binary envelope format, not raw
ragenix/age output.

| File | Purpose |
| --- | --- |
| `fleet-secrets.yaml` | Fleet-wide credentials with no narrower recipient scope (9 keys — see below) |
| `ldap.yaml` | muninn's KDC/LDAP boot-time secrets (consumed by `nix-kerberos-ldap`; 3 keys — see below) |
| `ghostty-themes.yaml` | Commercial Ghostty theme files, deployed to `~/.config/ghostty/themes/` (8 keys — see below) |
| `smtp-relay-sasl.yaml` | SASL credentials for the outbound relay (huginn primary, porkchop backup) |
| `unifi-backup-ssh-key.yaml` | SSH private key for unifi.home.matos.cc; scp's UniFi's autobackup dir to porkchop |
| `builder-codex-ssh-key.yaml` | SSH private key codex uses as a Nix remote-build client against gammu |
| `grafana-secret-key.yaml` | Grafana's `security.secret_key` (porkchop) |
| `keytab-codex.age` | codex's host Kerberos keytab (binary) |
| `keytab-gammu.age` | gammu's host Kerberos keytab (binary) |
| `keytab-huginn.age` | huginn's host Kerberos keytab (binary) |
| `keytab-muninn.age` | muninn's host Kerberos keytab (binary) |
| `keytab-porkchop.age` | porkchop's host Kerberos keytab (binary) |
| `keytab-ldap-muninn.age` | muninn's LDAP SASL/GSSAPI `ldap/` service principal keytab (binary) |

Keys inside the three multi-secret files above:

- **`fleet-secrets.yaml`**: `github-ratelimit`, `github-ssh-key`, `unifi-api-key`,
  `tailscale-authkey`, `cachix-authtoken`, `luadns-ini`, `user-password-alberth`,
  `user-password-nixos`, `syncthing-gui-password`.
- **`ldap.yaml`**: `admin-password`, `kdc-password`, `krb5-master-key`.
- **`ghostty-themes.yaml`**: `alucard`, `blade`, `buffy`, `dracula`, `lincoln`, `morbius`, `pro`,
  `van-helsing`.

---

## Creating a new secret

**Prerequisites:** YubiKey inserted (unless using the non-interactive `yubikey_0634d1c4`
identity); `sops`/`age`/`ssh-to-age` available (they're in nixie's devShell:
`nix develop /path/to/nixie`).

### 1. Confirm (or add) a `.sops.yaml` rule

Check for an existing `path_regex` rule already covering the new filename with the right
recipient scope — the fleet-wide catch-all `.*` rule (last in the file) covers anything without
a narrower match. Add a new rule only if this secret needs a scope no existing rule provides.

### 2. Create (or edit) the encrypted file

```bash
cd /path/to/nix-secrets
sops my-new-secrets.yaml
```

This opens `$EDITOR` on the decrypted plaintext (or a blank document for a new file). Edit as
plain YAML, save, and close. `sops` encrypts the content to every recipient in the matching
`.sops.yaml` rule.

Touch the YubiKey when prompted (the LED will blink), unless using the non-interactive identity.

### 3. Wire the secret into nixie

In the appropriate nixie module (usually `modules/common/` for cross-platform secrets), add a
`sops.secrets` entry:

```nix
sops.secrets.my-new-secret = {
  sopsFile = "${nix-secrets}/my-new-secrets.yaml";
  key = "my-new-secret";  # the YAML key inside the file
  owner = "alberth";      # optional; defaults to root
  mode = "0400";          # optional
};
```

Then reference the decrypted path wherever needed:

```nix
config.sops.secrets.my-new-secret.path
```

which resolves to `/run/secrets/my-new-secret` by default.

### 4. Commit both repos

```bash
# nix-secrets
git add my-new-secrets.yaml .sops.yaml
git commit -m "feat: add my-new-secret"
git push

# nixie — commit the module changes that reference the new secret
```

---

## Updating an existing secret's content

No recipient change needed:

```bash
cd /path/to/nix-secrets
sops fleet-secrets.yaml
```

Edit the value(s) in `$EDITOR`, save, close — `sops` re-encrypts to the same recipients already
declared for that file. Commit as usual.

For a scripted update, decrypt to a temp file, edit the specific key, then encrypt back
**in place** (`sops -e -i <file>`), not via a shell redirect (`sops -e <file> > <file>`) — `sops`
matches `.sops.yaml`'s `path_regex` against the *input* path, so a redirect target isn't seen by
the matcher and can silently pick the wrong recipient rule (usually the fleet-wide catch-all).

## Adding a recipient to an existing secret

1. Add the key to `.sops.yaml`'s `keys:` list (a new `&<host>_ssh` anchor for a new host — see
   "Recipients" above), then reference that anchor from the relevant rule's `key_groups`.
2. Re-encrypt the file's data key for the new recipient set — no need to touch the secret
   content itself:

   ```bash
   sops updatekeys my-new-secrets.yaml
   ```

   Touch the YubiKey when prompted (once per file). Repeat for every file the recipient needs.
3. Commit and push.

## Removing a recipient

1. Delete the key from `.sops.yaml`'s `key_groups` (and its `keys:` anchor, if nothing else
   references it).
2. `sops updatekeys <file>` for each affected file.
3. Commit and push.

**This does not rotate the secret's value** — a removed recipient who already decrypted the file
could have retained a plaintext copy. `sops updatekeys` only changes who can decrypt going
forward; rotate the underlying secret separately if the removal is security-motivated.

---

## Decrypting a secret manually

```bash
sops --decrypt fleet-secrets.yaml
```

or, to pin a specific identity rather than relying on `sops`'s default discovery:

```bash
export SOPS_AGE_KEY_FILE=age-yubikey-identity-2ab5ff2f.txt
sops --decrypt fleet-secrets.yaml
```

Touch the YubiKey when prompted (not needed for `age-yubikey-identity-0634d1c4.txt`, the
non-interactive safe identity — see "Recipients" above). For a binary secret (a keytab),
add `--input-type binary --output-type binary`.

---

## Development shell

A devShell is provided for this repo's own tooling (`nixfmt`, plus the pre-commit hooks below):

```bash
# Enter the dev shell (automatically via direnv, or manually)
nix develop

# Or, if direnv is installed and .envrc is allowed:
cd nix-secrets   # shell loads automatically
```

To activate direnv:

```bash
direnv allow
```

This installs `nixfmt`/`markdownlint-cli2`/`commitlint` pre-commit hooks into `.git/hooks`,
matching nixie's own hook set (`flake.nix`, `.commitlintrc.yaml`, `.markdownlint-cli2.yaml`).
`sops`/`age`/`ssh-to-age` are not included here — they're in nixie's devShell
(`nix develop /path/to/nixie`), per "Creating a new secret" above.

A separate `shell.nix` (classic `nix-shell`, not part of the flake outputs above) provides
`sops`, `age`, `age-plugin-yubikey`, `ssh-to-age`, and `git` for working with sops/age/YubiKey
identities directly in this repo without going through nixie's devShell:

```bash
nix-shell
```
