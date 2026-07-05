# nix-secrets — project directives

## Agent conventions

Any message prefixed with `question:` is a purely theoretical/discussion
request. Treat it as a request for information, reasoning, or discussion
only — **never** as an instruction to perform an action (no file edits,
commits, deployments, or other side effects), regardless of how the rest
of the phrasing reads.

## What this is

nix-secrets holds age-encrypted **text** secrets (SSH keys, tokens, passwords, `.ini`
credentials) for the [nixie](https://github.com/amatos/nixie) NixOS + nix-darwin
configuration. It is a plain git repo, not a flake (`flake = false` in nixie's
`flake.nix`), referenced there as the `nix-secrets` input.

All files are encrypted with [ragenix](https://github.com/yaxitech/ragenix) and
decryptable by the recipients declared in `secrets.nix`.

**Binary secrets do not belong here.** Git diffs binary files poorly and they don't
share this repo's plaintext-editing workflow. Kerberos keytabs live in the dedicated
[`keytabs-matos-cc`](https://github.com/amatos/keytabs-matos-cc) repo instead. If a new
binary secret type is needed, create another dedicated repo following that pattern —
don't add it here.

---

## Layout

```text
secrets.nix                          # ragenix recipients (who can decrypt what)
age-yubikey-identity-9ca1fbf9.txt    # YubiKey identity stub, not the key
*.age                                # age-encrypted secret files
```

## Recipients

Defined in `secrets.nix`: `alberth` (an offline recovery key, no hardware),
five backup YubiKey identities (`yubikeyd43f4e92`, `yubikey2ab5ff2f`,
`yubikeybe7a2b66`, `yubikey49705840`, `yubikey7cb1cad0`), plus a host age key
per nixie host that needs to decrypt at activation time (`codex`, `gammu`,
`porkchop`, ...). Host keys live at `/etc/age/host-key` on each host,
generated on first activation by nixie's `modules/common/age-host-key.nix`.

The YubiKeys' touch policy is **cached** (one touch valid for 15 seconds);
a PIN is required once per session for each YubiKey.

---

## Creating a new secret

**Prerequisites:** YubiKey inserted; `ragenix` available (it's in the nixie devShell:
`nix develop /path/to/nixie`).

1. **Declare it in `secrets.nix`** — map the new filename to the recipient keys that
   should decrypt it:

   ```nix
   "my-new-secret.age".publicKeys = allKeys;  # or users / systems / a subset
   ```

2. **Create (or edit) the encrypted file:**

   ```bash
   cd /path/to/nix-secrets
   ragenix -e my-new-secret.age
   ```

   This opens `$EDITOR`. Paste or type the secret, save, close. ragenix encrypts to
   every recipient listed in `secrets.nix` and writes `my-new-secret.age`. Touch the
   YubiKey when prompted (LED blinks).

3. **Wire it into nixie** — in the appropriate nixie module (usually `modules/common/`
   for cross-platform secrets), add an `age.secrets` entry:

   ```nix
   age.secrets.my-new-secret = {
     file = "${nix-secrets}/my-new-secret.age";
     owner = "alberth";   # optional; defaults to root
     mode = "0400";       # optional
   };
   ```

   Reference the decrypted path elsewhere as `config.age.secrets.my-new-secret.path`.
   See nixie's `CLAUDE.md` ("Wiring an external secrets repo into nixie") for the full
   pattern, including adding the input/specialArgs if this is the first secret nixie
   consumes from this repo.

4. **Commit both repos:**

   ```bash
   # nix-secrets
   git add my-new-secret.age secrets.nix
   git commit -m "feat: add my-new-secret"
   git push

   # nixie — commit the module changes that reference the new secret
   ```

---

## Rekeying secrets (after adding a new host)

1. On the new host, after first activation, get its public key:

   ```bash
   age-keygen -y /etc/age/host-key
   ```

2. Add it to `secrets.nix`:

   ```nix
   let
     newhostname = "age1...";   # paste public key here
     systems = [ codex gammu newhostname ];
   in ...
   ```

3. Rekey all secrets:

   ```bash
   cd /path/to/nix-secrets
   ragenix --rekey
   ```

   Touch the YubiKey when prompted (once per secret file).

4. Commit:

   ```bash
   git add -A
   git commit -m "chore: rekey secrets for newhostname"
   git push
   ```

---

## Decrypting a secret manually

```bash
age --decrypt \
  -i age-yubikey-identity-d43f4e92.txt \
  github-ssh-key.age
```

Touch the YubiKey when prompted.

---

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `chore:`, etc.), matching nixie's style, even though this repo has
  no commitlint enforcement of its own.
- Never commit decrypted plaintext (`.gitignore` excludes `*.dec`) — double-check before
  `git add -A` after manual decryption for debugging.
- Keep `README.md`'s Recipients and Secrets tables in sync with `secrets.nix` and the
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

1. Check whether the secret is binary — if so it belongs in `keytabs-matos-cc`
   (or another dedicated repo), not here.
2. Check `secrets.nix` before adding a new recipient group — the subset you need
   (`users`, `systems`, `ldapHosts`, `syncthingHosts`, ...) may already exist.
3. After adding or rekeying a secret, update the corresponding nixie module in the
   same change set so the two repos don't drift.
