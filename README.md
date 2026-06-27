# nix-secrets

Age-encrypted secrets for the [nixie](https://github.com/amatos/nixie) NixOS + nix-darwin configuration. All files are encrypted with [ragenix](https://github.com/yaxitech/ragenix) and decryptable by the keys listed in `secrets.nix`.

## Recipients

| Name | Type | Key |
|---|---|---|
| `alberth` | YubiKey (slot 1) | `age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y` |
| `codex` | Host key (`/etc/age/host-key`) | `age1rx38js86awlvzvm99x8qhnhd42cn9ytcudgqzm44u9qk9g79kqhs9jktky` |
| `gammu` | Host key (`/etc/age/host-key`) | `age1c2cmluquave5rmzequv7tea7c8zvt37yuml57vcd9qvvlla98qvsww99w0` |
| `porkchop` | Host key (`/etc/age/host-key`) | `age1yegmaunkewrxj3v6lt86nalta0xq5gq7dpcxrggqp8p7nlzdde4qsnq5jz` |

The YubiKey identity stub is stored in `age-yubikey-identity-9ca1fbf9.txt`. Touch policy is **cached** (one touch valid for 15 seconds); PIN is not required.

## Secrets

| File | Purpose |
|---|---|
| `github-ssh-key.age` | SSH key for GitHub access |
| `github-ratelimit.age` | GitHub API token (avoids Nix flake fetch rate limits) |
| `luadns.ini.age` | LuaDNS credentials for certbot DNS-01 challenges |

---

## Creating a new secret

**Prerequisites:** YubiKey inserted; `ragenix` available (it's in the nixie devShell: `nix develop /path/to/nixie`).

### 1. Declare the secret in `secrets.nix`

Add an entry mapping the new filename to the list of recipient keys that should be able to decrypt it:

```nix
"my-new-secret.age".publicKeys = allKeys;  # or users / systems / a custom subset
```

### 2. Create (or edit) the encrypted file

```bash
cd /path/to/nix-secrets
ragenix -e my-new-secret.age
```

This opens `$EDITOR`. Paste or type the secret, save, and close. ragenix encrypts the content to all recipients listed in `secrets.nix` and writes `my-new-secret.age`.

Touch the YubiKey when prompted (the LED will blink).

### 3. Wire the secret into nixie

In the appropriate nixie module (usually `modules/common/` for cross-platform secrets), add an `age.secrets` entry:

```nix
age.secrets.my-new-secret = {
  file = "${nix-secrets}/my-new-secret.age";
  owner = "alberth";   # optional; defaults to root
  mode = "0400";       # optional
};
```

Then reference the decrypted path wherever needed:

```nix
config.age.secrets.my-new-secret.path
```

### 4. Commit both repos

```bash
# nix-secrets
git add my-new-secret.age secrets.nix
git commit -m "feat: add my-new-secret"
git push

# nixie — commit the module changes that reference the new secret
```

---

## Rekeying secrets (after adding a new host)

When a new host is added to nixie, generate its host key (`nixos-rebuild switch` will create `/etc/age/host-key` on first activation), then add its public key to `secrets.nix` and rekey all secrets so the new host can decrypt them:

### 1. Get the new host's public key

On the new host after first activation:

```bash
age-keygen -y /etc/age/host-key
```

### 2. Add it to `secrets.nix`

```nix
let
  newhostname = "age1...";   # paste public key here
  systems = [ codex gammu newhostname ];
in ...
```

### 3. Rekey all secrets

```bash
cd /path/to/nix-secrets
ragenix --rekey
```

Touch the YubiKey when prompted (once per secret file).

### 4. Commit

```bash
git add -A
git commit -m "chore: rekey secrets for newhostname"
git push
```

---

## Decrypting a secret manually

```bash
age --decrypt \
  -i age-yubikey-identity-9ca1fbf9.txt \
  github-ssh-key.age
```

Touch the YubiKey when prompted.
