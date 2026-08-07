# Every package this machine has beyond what Omarchy installs for itself.
#
# This is the file to edit. `just packages` compiles it to
# .chezmoidata/packages.json, which chezmoi reads and the installer follows;
# `chezmoi apply` then makes the machine match. Both files are committed, so a
# fresh machine can install everything without needing nix first, which matters
# because nix is itself in the list.
#
# Removing a name here does not remove the package. Say `yay -Rns` for that.

rec {
  # The groups this machine wants. A machine that wants others says so in its
  # own ~/.config/chezmoi/chezmoi.toml, which outranks this file:
  #
  #   [data.packages]
  #     enabled = ["browsers", "cli", "dev", "shell"]
  enabled = [
    "browsers"
    "cli"
    "desktop"
    "dev"
    "fonts"
    "media"
    "net"
    "shell"
  ];

  groups = {
    # Web browsers. All three are here; a leaner machine can drop the group
    # and use whatever Omarchy shipped.
    browsers = [
      "brave-bin"
      "firefox-bin"
      "librewolf-bin"
    ];

    # Terminal tools that make a shell worth sitting in.
    cli = [
      "downgrade"
      "git-filter-repo"
      "htop"
      "nano"
      "ncdu"
      "openbsd-netcat"
      "openssh"
      "patchelf"
      "squashfs-tools"
      "tree"
      "vim"
      "watchman-bin"
      "wget"
      "xdg-utils"
    ];

    # The desktop past Hyprland itself: launcher, clipboard, screenshots,
    # session restore, and the KDE pieces that fill the gaps.
    desktop = [
      "cliphist"
      "dolphin"
      "dunst"
      "freerdp"
      "hyprshot"
      "hyprsession"
      "konsole"
      "pavucontrol"
      "polkit-kde-agent"
      "walker"
      "wl-clip-persist"
      "wofi"
    ] ++ elephantProviders;

    # Languages, build systems, containers, editors, agents.
    dev = [
      "chezmoi"
      "dbeaver"
      "distrobox"
      "jujutsu"
      "just"
      "kitty"
      "libc++"
      "libc++abi"
      "llama.cpp-vulkan-bin"
      "meson"
      "neovide-bin"
      "ninja"
      "nix"
      "nvm"
      "opencode"
      "podman"
      "rust-wasm"
      "scdoc"
      "uv"
    ];

    fonts = [
      "noto-fonts-extra"
      "ttf-cascadia-mono-nerd"
      "ttf-inconsolata-lgc-nerd"
    ];

    # Playing, tagging, recording and looking at things.
    media = [
      "alsa-plugins"
      "alsa-tools"
      "beets"
      "faad2"
      "lightningview"
      "lmms"
      "oculante"
      "opusfile"
      "rsgain"
      "wf-recorder"
      "wl-screenrec"
      "yt-dlp"
    ];

    net = [ "tailscale" ];

    shell = [
      "direnv"
      "nix-zsh-completions"
      "omarchy-keyring"
      "omarchy-zsh"
      "thefuck"
      "zsh"
      "zsh-autocomplete"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
    ];

    # -------------------------------------------------------------------
    # Groups below are not in `enabled`. They belong to this machine's metal
    # rather than to its taste, and installing them elsewhere is at best
    # wasted disk. They stay written down so that rebuilding *this* machine
    # is one edit away.
    # -------------------------------------------------------------------

    # Kernel, firmware, boot, radios, sensors. An AMD laptop's answer, not a
    # portable one.
    hardware = [
      "amd-ucode"
      "bluez"
      "bluez-utils"
      "clinfo"
      "efibootmgr"
      "fprintd"
      "hwinfo"
      "lib32-vulkan-radeon"
      "linux-lts"
      "linux-lts-headers"
      "lshw"
      "mesa-utils"
      "opencl-amd"
      "opencl-mesa"
      "python-pylspci"
      "radeontop"
      "smartmontools"
      "switcheroo-control"
      "usbutils"
      "vulkan-nouveau"
      "vulkan-tools"
      "wireless_tools"
      "wpa_supplicant"
    ] ++ xorgDrivers;

    # The Brother DCP-7030 on this desk.
    printing = [
      "brother-dcp7030"
      "brscan-skey"
    ];

    # DaVinci Resolve wants libraries Arch stopped shipping years ago. See
    # ~/Documents/projects/davinci-resolve for the rest of that story.
    video-editing = [
      "apr"
      "apr-util"
      "gtk2"
      "lib32-libpng12"
      "lib32-libstdc++5"
      "libpng12"
      "libxcrypt-compat"
      "qt5-multimedia"
      "qt5-quickcontrols2"
      "qt5-websockets"
    ];

    # Marked explicit at some point, but really other packages' dependencies.
    # Kept so that `pacman -Qqe` and this file agree; safe to drop if you ever
    # mark them back as dependencies.
    incidental = [
      "fcft"
      "python-distro"
      "ruby-listen"
      "tllist"
      "webkitgtk-6.0"
    ];
  };

  # Walker's backend ships one package per source it can search.
  elephantProviders = map (p: "elephant-${p}") [
    "bluetooth"
    "calc"
    "clipboard"
    "desktopapplications"
    "files"
    "menus"
    "providerlist"
    "runner"
    "symbols"
    "todo"
    "unicode"
    "websearch"
  ] ++ [ "elephant" ];

  xorgDrivers = [
    "xf86-video-amdgpu"
    "xf86-video-ati"
    "xf86-video-nouveau"
    "xorg-server"
    "xorg-xinit"
    "xorg-xrandr"
  ];
}
