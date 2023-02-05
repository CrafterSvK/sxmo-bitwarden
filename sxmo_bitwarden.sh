#!/bin/sh
# title="$icon_fnd Bitwarden"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

SESSION_TOKEN=""

home() {
  ENTRY="$(
    printf %b "
      Show All\n
      Logout\n
      Close Menu
    " |
      xargs -0 echo |
      sed '/^[[:space:]]*$/d' |
      awk '{$1=$1};1' |
      sxmo_dmenu.sh -p "Search"
  )" || exit 0

  if [ "Close Menu" = "$ENTRY" ]; then
    exit 0
  elif [ "Logout" = "$ENTRY" ]; then
    bw logout
  elif [ "Favorites" = "$ENTRY" ]; then
    favorites
  elif [ "Show All" = "$ENTRY" ]; then
    all
  else
    search "$ENTRY"
  fi
}

all() {
  notify-send "Bitwarden: loading entries"
  ITEMS="$(bw list items --session "$SESSION_TOKEN" | jq ".[].name" | sed -e 's/^"//' -e 's/"$//' | duplicates)"

  if [ "$?" = 1 ]; then
      password_menu
  fi

  while true; do
    ENTRY="$(
      printf %b "
        Go Back\n
        Close Menu\n
        $ITEMS
      " |
        xargs -0 echo |
        sed '/^[[:space:]]*$/d' |
        awk '{$1=$1};1' |
        sxmo_dmenu_with_kb.sh -p "Search"
    )" || exit 0

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    elif [ "Go Back" = "$ENTRY" ]; then
      home
    else
      entry "$ENTRY"
    fi
  done
}

entry() {
  IDX=$(echo "$1" | sed -e -n 's/.*\([0-9]\+\)$/\1/p')
  NAME=$(echo "$1" | sed -e 's/[0-9]\+$//')
  INFO=$(bw list items --session "$SESSION_TOKEN" --search "$NAME")
  USERNAME=$(echo "$INFO" | jq .["$IDX"].login.username | sed -e 's/^"//' -e 's/"$//')
  PASSWORD=$(echo "$INFO" | jq .["$IDX"].login.password | sed -e 's/^"//' -e 's/"$//')

  while true; do
    ENTRY="$(
      printf %b "
        Go Back\n
        Close Menu\n
        $USERNAME\n
        Password
      " |
      xargs -0 echo |
      sed '/^[[:space:]]*$/d' |
      awk '{$1=$1};1' |
      sxmo_dmenu_with_kb.sh -p "$NAME"
    )" || exit 0

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    elif [ "Go Back" = "$ENTRY" ]; then
      all
    elif [ "Password" = "$ENTRY" ]; then
      notify-send "Bitwarden: password copied"

      copy_to_clipboard "$PASSWORD"
    else
      notify-send "Bitwarden: value copied"

      copy_to_clipboard "$ENTRY"
    fi
  done
}

password_menu() {
  EMAIL="$1"
  PROMPT="Password"

  while true; do
    ENTRY="$(
      printf %b "
        Close Menu
      " |
        xargs -0 echo |
        sed '/^[[:space:]]*$/d' |
        awk '{$1=$1};1' |
        sxmo_dmenu_with_kb.sh -p "$PROMPT"
    )" || exit 0

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    else
      notify-send "Bitwarden: Logging in"
      if [ -z "$EMAIL" ]; then
        SESSION_TOKEN=$(bw unlock "$ENTRY" --raw)
      else
        SESSION_TOKEN=$(bw login "$EMAIL" "$ENTRY" --raw)
      fi

      if [ "$?" = "0" ]; then
        home
      else
        notify-send "Bitwarden: Wrong password"
      fi
    fi
  done
}

login() {
  STATUS=$(bw status | jq .status)

  if [ "$STATUS" != '"unauthenticated"' ]; then
    password_menu
  fi

  while true; do
    ENTRY="$(
      printf %b "
        Close Menu
      " |
        xargs -0 echo |
        sed '/^[[:space:]]*$/d' |
        awk '{$1=$1};1' |
        sxmo_dmenu_with_kb.sh -p "Email"
    )" || exit 0

    if [ "Close Menu" = "$ENTRY" ]; then
      exit 0
    else
      password_menu "$ENTRY"
    fi
  done
}

copy_to_clipboard() {
  case "$SXMO_WM" in
    sway)
      wl-copy "$1"
    ;;
    dwm)
      printf %s "$1" | xsel -b -i
    ;;
    esac
}

# marks name with number, we can index later using this number
duplicates() {
  LAST_ENTRY=""
  I=0
  while read line
  do
    if [ "$LAST_ENTRY" = "$line" ]; then
      I=$((I+1))
    else
      I=0
    fi

    echo "$line" "$I"
    LAST_ENTRY="$line"
  done
}

login