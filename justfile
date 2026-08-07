# Compile packages.nix into the JSON chezmoi reads.
#
# Committing the JSON is what lets a fresh machine install everything without
# having nix already, so run this and commit both whenever packages.nix changes.
packages:
    nix eval --file packages.nix --json \
        --apply 'p: { packages = { inherit (p) enabled groups; }; }' \
        > .chezmoidata/packages.json
    @echo "packages.json rebuilt; run 'chezmoi apply' to catch the machine up."

# Crop the screensaver logo to its own ink.
#
# tte centres what it is given, and it counts leading blank columns and rows as
# part of the text while stripping trailing ones. Padding on the left therefore
# pushes the logo right by half that padding. Transcoding an image keeps
# whatever margin the image had, so run this after
# `omarchy branding screensaver image`.
logo path="~/.config/omarchy/branding/screensaver.txt":
    #!/usr/bin/env bash
    set -euo pipefail
    file={{ path }}
    awk '
      { line[NR] = $0
        for (i = 1; i <= length($0); i++)
          if (substr($0, i, 1) != " ") {
            if (!minc || i < minc) minc = i
            if (i > maxc) maxc = i
            if (!minr) minr = NR
            maxr = NR
          }
      }
      END {
        if (!minr) exit
        for (r = minr; r <= maxr; r++) {
          out = substr(line[r], minc, maxc - minc + 1)
          sub(/[ \t]+$/, "", out)
          print out
        }
      }
    ' "$file" > "$file.cropped"
    mv "$file.cropped" "$file"
    awk 'END { print "logo is now " NR " rows" }' "$file"

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
