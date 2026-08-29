# Non-secret personal identity info for alberth — not age-encrypted, since
# none of this is sensitive (email, name, GitHub id, GPG key fingerprint are
# all public). Lives here so nix-dendrites and nix-home can share one source
# of truth instead of duplicating these values in each repo.
#
# Consume via the nix-secrets flake input, e.g.:
#   let user = import "${inputs.nix-secrets}/users/alberth.nix"; in ...
{
  fullName = "Alberth Matos";
  email = "alberth@matos.cc";
  githubUsername = "amatos";
  gpgSigningKey = "5FC8FE1141FA769594E91E48F41BDBF6171A3BB4";
}
