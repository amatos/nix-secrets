{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  buildInputs = [
    rage
    age
    age-plugin-yubikey
    git
  ];
}
