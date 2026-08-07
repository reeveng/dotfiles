# Sourced by omarchy-menu. Replaces the main menu with one list holding every
# action in the tree, each labelled with the path that leads to it and what it
# does. Opening the menu shows what you used lately and the sections, so it
# reads like the menu Omarchy ships; typing searches the whole tree at once,
# which is when you already know what you are after.
#
# Picking a section opens Omarchy's own submenu, unchanged.

OMARCHY_FLAT_SOURCE="${OMARCHY_PATH:-$HOME/.local/share/omarchy}/bin/omarchy-menu"
OMARCHY_FLAT_BUILDER="$HOME/.config/omarchy/extensions/menu-index.py"
OMARCHY_FLAT_HINTS="$HOME/.config/omarchy/extensions/menu-hints.tsv"
OMARCHY_FLAT_INDEX="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/menu-index.tsv"
OMARCHY_FLAT_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu"
OMARCHY_FLAT_RECENT="$OMARCHY_FLAT_STATE/recent"
OMARCHY_FLAT_QUIET="$OMARCHY_FLAT_STATE/descriptions-off"
OMARCHY_FLAT_FIELD=" · "
OMARCHY_FLAT_KEEP=8

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

omarchy_flat_remember() {
  local display="$1" kept
  mkdir -p "$OMARCHY_FLAT_STATE"
  kept=$(grep -vxF -- "$display" "$OMARCHY_FLAT_RECENT" 2>/dev/null | head -n "$OMARCHY_FLAT_KEEP")
  printf '%s\n%s\n' "$display" "$kept" | grep -v '^$' >"$OMARCHY_FLAT_RECENT"
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

  local described=1 width=880 choice display row
  [[ -f $OMARCHY_FLAT_QUIET ]] && described=0 && width=520

  choice=$(python3 "$OMARCHY_FLAT_BUILDER" render "$OMARCHY_FLAT_INDEX" "$OMARCHY_FLAT_RECENT" "$described" |
    omarchy-launch-walker --dmenu --width "$width" --minheight 1 --maxheight 700 -p "Go…" 2>/dev/null)
  [[ -z $choice || $choice == "CNCLD" ]] && exit 0

  display=${choice%%"$OMARCHY_FLAT_FIELD"*}

  if [[ $display == *"Descriptions: "* ]]; then
    mkdir -p "$OMARCHY_FLAT_STATE"
    ((described)) && touch "$OMARCHY_FLAT_QUIET" || rm -f "$OMARCHY_FLAT_QUIET"
    show_main_menu
    return
  fi

  row=$(awk -F'\t' -v want="$display" '$1 == want { print; exit }' "$OMARCHY_FLAT_INDEX")
  [[ -z $row ]] && exit 0

  omarchy_flat_remember "$display"
  omarchy_flat_answer "$(cut -f3 <<<"$row")" "$(cut -f2 <<<"$row")"
}
