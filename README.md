# nix-secrets

Age-encrypted secrets for the [nixie](https://github.com/amatos/nixie) NixOS + nix-darwin configuration.
All files are encrypted with [ragenix](https://github.com/yaxitech/ragenix) and decryptable by the keys
listed in `secrets.nix`.

> **Binary secrets, like Kerberos keytabs, do not belong in this repo.** Git diffs binary files poorly
> and they don't benefit from the same plaintext-editing workflow as the secrets below. Kerberos keytabs
> live in a dedicated repo: [`keytabs.matos.cc`](https://github.com/amatos/keytabs.matos.cc).

## Recipients

| Name | Type | Key |
| --- | --- | --- |
| `alberth` | YubiKey (slot 1) | `age1yubikey1qtpg5lwewq75p68ru0n909uzkqddkhym2mkwp37h2fwkkgfdem05ssa4m6y` |
| `codex` | Host key (`/etc/age/host-key`) | `age1786r092jkepdahryx7t9kru8txuvreh3f2pgtvrv3u5hmjxjjy3st9udnl` |
| `gammu` | Host key (`/etc/age/host-key`) | `age12vhj5z6zepnz7uyzks23p6rgwa7rudja7ectsrl89zf96nnmfcnq264972` |
| `porkchop` | Host key (`/etc/age/host-key`) | `age1yegmaunkewrxj3v6lt86nalta0xq5gq7dpcxrggqp8p7nlzdde4qsnq5jz` |
| `huginn` | Host key (`/etc/age/host-key`) | `age1je5xg9s90g8l0307xpphclxj3fugvkl59ne9yna46lne9fw0wfpq59lzux` |

The YubiKey identity stub is stored in `age-yubikey-identity-9ca1fbf9.txt`. Touch policy is **cached** (one touch valid for 15 seconds); PIN is not required.

## Secrets

| File | Purpose |
| --- | --- |
| `github-ssh-key.age` | SSH key for GitHub access |
| `github-ratelimit.age` | GitHub API token (avoids Nix flake fetch rate limits) |
| `luadns.ini.age` | LuaDNS credentials for certbot DNS-01 challenges |
| `tailscale-authkey.age` | Tailscale auth key for node enrollment |
| `cachix-authtoken.age` | Cachix auth token for binary cache pushes |
| `default-nixos-user-password.age` | Hashed default password for `root`/`nixos`/`alberth` on fresh NixOS hosts |
| `syncthing-gui-password.age` | Syncthing GUI admin password |
| `smtp-relay-sasl.age` | SASL credentials for the outbound SMTP relay |
| `ldap-admin-password.age` | LDAP `cn=admin` bind password (consumed by `nix-kerberos-ldap`) |
| `ldap-kdc-password.age` | KDC LDAP service account password (consumed by `nix-kerberos-ldap`) |
| `krb5-master-key.age` | Kerberos KDC master key (consumed by `nix-kerberos-ldap`) |
| `unifi-api-key.age` | UniFi read-only API token (consumed by `nixie.dyndnsLuadns`) |
| `unifi-backup-ssh-key.age` | SSH private key for unifi.home.matos.cc; scp's UniFi's autobackup dir to porkchop (consumed by `nixie.unifiBackup`) |

---

## Creating a new secret

**Prerequisites:** YubiKey inserted; `ragenix` available (it's in the nixie devShell: `nix develop /path/to/nixie`).

### 1. Declare the secret in `secrets.nix`

Add an entry mapping the new filename to the list of recipient keys that should be able to decrypt it:

```nix
"my-new-secret.age".publicKeys = allKeys;  # or users / systems / a subset
```

### 2. Create (or edit) the encrypted file

```bash
cd /path/to/nix-secrets
ragenix -e my-new-secret.age
```

This opens `$EDITOR`. Paste or type the secret, save, and close. ragenix encrypts the content to all
recipients listed in `secrets.nix` and writes `my-new-secret.age`.

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

When a new host is added to nixie, generate its host key (`nixos-rebuild switch` will create
`/etc/age/host-key` on first activation), then add its public key to `secrets.nix` and rekey all
secrets so the new host can decrypt them:

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
