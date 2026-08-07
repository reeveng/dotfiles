# Sourced by omarchy-menu. The menu still opens on Omarchy's own ten sections
# and still goes deeper and deeper the way it always did; below them sits every
# action in the tree, labelled with the path that leads to it, so a search
# reaches the whole tree at once instead of one level of it.
#
# Actions carry no description by default, because walker matches whatever it
# shows and a sentence of explanation on 230 rows is 230 rows of false matches.
# The eleventh row turns them on when you want to read rather than search.

# Omarchy's browser list is written out by hand and LibreWolf is not on it.
show_setup_default_browser_menu() {
  local current
  local options
  browser_desktop_exists chromium.desktop && options="  Chromium"
  browser_desktop_exists google-chrome.desktop && options="${options:+$options\n}󰊯  Chrome"
  browser_desktop_exists brave-browser.desktop && options="${options:+$options\n}󰖟  Brave"
  browser_desktop_exists brave-origin-beta.desktop && options="${options:+$options\n}󰖟  Brave Origin"
  browser_desktop_exists microsoft-edge.desktop && options="${options:+$options\n}󰇩  Edge"
  browser_desktop_exists firefox.desktop && options="${options:+$options\n}󰈹  Firefox"
  browser_desktop_exists librewolf.desktop && options="${options:+$options\n}󰖟  LibreWolf"
  browser_desktop_exists zen.desktop && options="${options:+$options\n}󰖟  Zen"

  case "$(omarchy-default-browser)" in
  chromium) current="  Chromium" ;;
  chrome) current="󰊯  Chrome" ;;
  brave) current="󰖟  Brave" ;;
  brave-origin) current="󰖟  Brave Origin" ;;
  edge) current="󰇩  Edge" ;;
  firefox) current="󰈹  Firefox" ;;
  librewolf) current="󰖟  LibreWolf" ;;
  zen) current="󰖟  Zen" ;;
  esac

  case $(menu "Default Browser" "$options" "" "$current") in
  *Chromium*) omarchy-default-browser chromium ;;
  *Chrome*) omarchy-default-browser chrome ;;
  *"Brave Origin"*) omarchy-default-browser brave-origin ;;
  *Brave*) omarchy-default-browser brave ;;
  *Edge*) omarchy-default-browser edge ;;
  *Firefox*) omarchy-default-browser firefox ;;
  *LibreWolf*) omarchy-default-browser librewolf ;;
  *Zen*) omarchy-default-browser zen ;;
  *) show_setup_default_menu ;;
  esac
}

OMARCHY_FLAT_SOURCE="${OMARCHY_PATH:-$HOME/.local/share/omarchy}/bin/omarchy-menu"
OMARCHY_FLAT_BUILDER="$HOME/.config/omarchy/extensions/menu-index.py"
OMARCHY_FLAT_HINTS="$HOME/.config/omarchy/extensions/menu-hints.tsv"
OMARCHY_FLAT_INDEX="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/menu-index.tsv"
OMARCHY_FLAT_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu"
OMARCHY_FLAT_LOUD="$OMARCHY_FLAT_STATE/descriptions-on"
OMARCHY_FLAT_FIELD=" · "

omarchy_flat_index() {
  [[ -s $OMARCHY_FLAT_INDEX &&
    $OMARCHY_FLAT_INDEX -nt $OMARCHY_FLAT_SOURCE &&
    $OMARCHY_FLAT_INDEX -nt $OMARCHY_FLAT_BUILDER &&
    $OMARCHY_FLAT_INDEX -nt $OMARCHY_FLAT_HINTS ]] && return 0

  mkdir -p "${OMARCHY_FLAT_INDEX%/*}"
  python3 "$OMARCHY_FLAT_BUILDER" build "$OMARCHY_FLAT_SOURCE" >"$OMARCHY_FLAT_INDEX.new" 2>/dev/null &&
    [[ -s $OMARCHY_FLAT_INDEX.new ]] &&
    mv "$OMARCHY_FLAT_INDEX.new" "$OMARCHY_FLAT_INDEX"
}

omarchy_flat_answer() {
  local option="$1" owner="$2" answer

  # A whole section is entered by name; it asks its own question.
  if [[ $owner == "go_to_menu" ]]; then
    go_to_menu "$option"
    return
  fi

  answer=$(mktemp)
  printf '%s\n' "$option" >"$answer"
  trap 'rm -f "$answer"' EXIT

  # Answer the owning menu's question for it, then hand later questions back,
  # so that backing out of an action lands on the menu it belongs to.
  menu() {
    if [[ -s $answer ]]; then
      cat "$answer"
      : >"$answer"
    else
      omarchy_flat_menu "$@"
    fi
  }

  "$owner"
}

eval "omarchy_flat_menu() $(declare -f menu | tail -n +2)"
eval "omarchy_flat_tree_menu() $(declare -f show_main_menu | tail -n +2)"

show_main_menu() {
  omarchy_flat_index || {
    omarchy_flat_tree_menu
    return
  }

  local described=0 width=700 choice display row
  [[ -f $OMARCHY_FLAT_LOUD ]] && described=1 && width=880

  choice=$(python3 "$OMARCHY_FLAT_BUILDER" render "$OMARCHY_FLAT_INDEX" "$described" |
    omarchy-launch-walker --dmenu --width "$width" --minheight 1 --maxheight 700 -p "Go…" 2>/dev/null)
  [[ -z $choice || $choice == "CNCLD" ]] && exit 0

  display=${choice%%"$OMARCHY_FLAT_FIELD"*}

  if [[ $display == *"Descriptions: "* ]]; then
    mkdir -p "$OMARCHY_FLAT_STATE"
    ((described)) && rm -f "$OMARCHY_FLAT_LOUD" || touch "$OMARCHY_FLAT_LOUD"
    show_main_menu
    return
  fi

  row=$(awk -F'\t' -v want="$display" '$1 == want { print; exit }' "$OMARCHY_FLAT_INDEX")
  [[ -z $row ]] && exit 0

  omarchy_flat_answer "$(cut -f3 <<<"$row")" "$(cut -f2 <<<"$row")"
}
