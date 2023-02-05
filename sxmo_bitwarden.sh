#!/bin/sh
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

HISTORY_FILE="$XDG_CACHE_HOME"/sxmo/bitwardenhistory.tsv
FAVORITES_FILE="$XDG_CACHE_HOME"/sxmo/bitwardenfavorites.tsv

SESSION_TOKEN=""

home() {
  while true; do
    ENTRY="$(
      printf %b "
        Favorites
        Logout
        Close Menu
      " | sxmo_dmenu_with_kb.sh -p "Search"
    )"

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    elif [ "Logout" = "$ENTRY" ]; then
      bw logout
    elif [ "Favorites" = "$ENTRY" ]; then
      favorites
    else
      search "$ENTRY"
    fi
  done
}

search() {
  SEARCHED_TERM="$1"

  while true; do
  ENTRY="$(
    printf %b "
      Change Search
      Close Menu
    " | sxmo_dmenu_with_kb.sh -p "Search"
  )"

  if [ "Close Menu" = "$ENTRY" ]; then
    exit 2
  elif [ "Change Search" = "$ENTRY" ]; then
    search
  fi
  done
}

favorites() {

}

entry() {
  exit 0
}

password_menu() {
  EMAIL="$1"

  while true; do
    ENTRY="$(
      printf %b "
        Close Menu
      " | sxmo_dmenu_with_kb.sh -p "Password"
    )"

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    else
      while true; do
        SESSION_TOKEN=$(bw login "$EMAIL" "$ENTRY")

        if [ "$?" = "0" ]; then
          break
        fi
      done

      home
    fi
  done
}

login() {
  while true; do
    ENTRY="$(
      printf %b "
        Close Menu
      " | sxmo_dmenu_with_kb.sh -p "Bitwarden email"
    )" || exit 0

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    else
      password_menu $ENTRY
    fi
  done
}

login