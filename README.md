# nix-secrets

Age-encrypted secrets for the `nix-dendrites` NixOS + nix-darwin configuration.
Secrets are encrypted with [ragenix](https://github.com/yaxitech/ragenix) and
decrypted at activation time on the target host.

## Layout

- `secrets.nix` — the registry. Defines age recipients (my personal key,
  YubiKey identities, host SSH keys) and, for each `*.age` file, which
  recipients it's encrypted to.
- `age-yubikey-identity-*.txt` — YubiKey age identities. Each corresponds to a
  physical YubiKey; used to decrypt when editing a secret.
- `users/<name>-password.age` — per-user login password hashes, consumed by
  `hosts/nixos-common` in `nix-dendrites`.
- `users/<name>.nix` — non-secret per-user identity data (full name, email,
  GitHub id, GPG signing key), shared between `nix-dendrites` and `nix-home`
  so it isn't duplicated in each repo. Not age-encrypted since none of it is
  actually sensitive.
- Other secrets live at the repo root (or a topic subdirectory), referenced by
  path from `secrets.nix` and from the consuming host/module config.

## Prerequisites

- No local install needed — run `ragenix` via
  `nix run github:yaxitech/ragenix -- ...`, or a nix development
  shell (`nix develop`).
- A YubiKey plugged in (for `age-yubikey-identity-*.txt` identities), or
  my personal age private key.
- Run all commands from inside this repo, so `ragenix` picks up `secrets.nix`.

## Adding a new secret

1. If the recipient (a new host or key) doesn't already exist, add its public
   key to `secrets.nix`.
2. Register the new secret's filename and recipients in `secrets.nix`:

   ```nix
   "my-secret.age".publicKeys = [ alberth ] ++ allHosts;
   ```
  
3. Create/edit the encrypted file:

   ```bash
   nix run github:yaxitech/ragenix -- -e my-secret.age -i age-yubikey-identity-<your-key-id>.txt
   ```

   This opens `$EDITOR` on the decrypted contents (touch the YubiKey when
   prompted). Save and quit — ragenix re-encrypts to every recipient listed
   in step 2.
4. Commit and push both the `secrets.nix` change and the new `.age` file.
5. Reference it from the consuming host config:

   ```nix
   age.secrets.my-secret.file = "${inputs.nix-secrets}/my-secret.age";
   ```

   and use `config.age.secrets.my-secret.path` wherever the decrypted path is
   needed at runtime.

## Adding a user login password (NixOS only)

NixOS logins are set from a **password hash**, never the plaintext password,
decrypted at activation into `hashedPasswordFile`. This does not apply to
nix-darwin — macOS manages its own login passwords via Open Directory, outside
of Nix, so there's nothing to wire up there.

1. In `nix-dendrites`, add `passwordSecret = "<name>-password";` to the user's
   data file (`users/<name>.nix`).
2. Register the secret in `secrets.nix`:

   ```nix
   "users/<name>-password.age".publicKeys = allKeys;
   ```

3. Generate the hash and store it in one step (the plaintext password is read
   directly from the terminal and never touches disk or shell history — only
   the resulting hash does, briefly, in an owner-only temp file):

   ```bash
   umask 077 && tmp=$(mktemp) && nix run nixpkgs#mkpasswd -- -m sha-512 > \
     "$tmp" && EDITOR="cp $tmp" nix run github:yaxitech/ragenix -- \
       -e users/<name>-password.age -i age-yubikey-identity-<your-key-id>.txt; \
     rm -f "$tmp"
   ```

4. Commit and push. `hosts/nixos-common/default.nix` in `nix-dendrites`
   automatically wires `age.secrets.<name>-password` and
   `users.users.<name>.hashedPasswordFile` for any user with a `passwordSecret`
   attribute — no further changes needed there.

## Notes

- Prefer `mkpasswd -m sha-512` (SHA-512-crypt) over `yescrypt` unless you have
  a specific reason otherwise — it's the more universally supported crypt(3)
  format.
- Never commit plaintext secrets or unencrypted password hashes outside of
  `.age` files.
