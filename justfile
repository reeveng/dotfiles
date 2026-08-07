# Compile packages.nix into the JSON chezmoi reads.
#
# Committing the JSON is what lets a fresh machine install everything without
# having nix already, so run this and commit both whenever packages.nix changes.
packages:
    nix eval --file packages.nix --json \
        --apply 'p: { packages = { inherit (p) enabled groups; }; }' \
        > .chezmoidata/packages.json
    @echo "packages.json rebuilt; run 'chezmoi apply' to catch the machine up."

# Packages this machine has explicitly installed that neither Omarchy nor
# packages.nix accounts for. Anything listed here is something you installed
# by hand and have not written down yet.
drift:
    #!/usr/bin/env bash
    set -euo pipefail
    known=$(
      {
        sed 's/#.*//' ~/.local/share/omarchy/install/omarchy-*.packages \
          | tr -s ' \t' '\n\n'
        nix eval --file packages.nix --raw --apply \
          'p: builtins.concatStringsSep "\n"
                (builtins.concatLists (builtins.attrValues p.groups))'
      } | sed '/^$/d' | sort -u
    )
    comm -23 <(pacman -Qqe | sort -u) <(echo "$known")
