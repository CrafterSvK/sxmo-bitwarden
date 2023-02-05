#!/bin/sh
# title="$icon_fnd Bitwarden"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# config
NOTIFICATION=1

SESSION_TOKEN=""

home() {
    ENTRY="$(
      grep . <<EOF | sxmo_dmenu_with_kb.sh -p "Home"
Logins
Cards
Identities
Secure notes
Logout
Close Menu
EOF
)"

  case "$ENTRY" in
    "Close Menu")
      exit 0
    ;;
    "Logout")
      bw logout
    ;;
    "Logins")
      all 1
    ;;
    "Cards")
      all 3
    ;;
    "Identities")
      all 4
    ;;
    "Secure notes")
      all 2
    ;;
    "Sync")
      [ $NOTIFICATION ] && notify-send "Bitwarden: synchronizing"
      bw sync
    ;;
    *)
      # search "$ENTRY" fixme: should search for everything? slow
    ;;
  esac
}

all() {
  case $1 in
    "1")
      TYPE_NAME="Logins"
      entry="login_entry"
    ;;
    "2")
      TYPE_NAME="Identities"
      entry="identity_entry"
    ;;
    "3")
      TYPE_NAME="Cards"
      entry="card_entry"
      ;;
    "4")
      TYPE_NAME="Notes"
      entry="note_entry"
      ;;
    *)
      home
      ;;
  esac

  [ $NOTIFICATION ] && notify-send "Bitwarden: loading $TYPE_NAME"
  ITEMS="$(bw list items --session "$SESSION_TOKEN" --nointeraction |
          jq ".[] | select(.type == $1) | .name" |
          sed -e 's/^"//' -e 's/"$//' |
          duplicates)"

  if [ "$?" = 1 ]; then
      [ $NOTIFICATION ] && notify-send "Bitwarden: password required"
      password_menu
  fi

  while true; do
    ENTRY="$(
      grep . <<EOF | sxmo_dmenu_with_kb.sh -p $TYPE_NAME
Go Back
Close Menu
$ITEMS
EOF
)"
    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      "Go Back")
        home
      ;;
      *)
        eval '"$entry" "$ENTRY"'
      ;;
    esac
  done
}

login_entry() {
  IDX=$(echo "$1" | sed -n -e 's/.*\(\ \([0-9]\+\)\)$/\2/p')
  NAME=$(echo "$1" | sed -e 's/[0-9]\+$//')
  INFO=$(bw list items --session "$SESSION_TOKEN" --nointeraction  --search "$NAME" |
        jq "[.[] | select(.type == 1)] | .[$IDX].login")
  USERNAME=$(echo "$INFO" | jq .username | sed -e 's/^"//' -e 's/"$//')
  PASSWORD=$(echo "$INFO" | jq .password | sed -e 's/^"//' -e 's/"$//')

  while true; do
    ENTRY="$(
      grep . <<EOF | sxmo_dmenu_with_kb.sh -p "$NAME"
Go Back
Close Menu
"$USERNAME"
Password
EOF
)"

    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      "Go Back")
        all_logins
      ;;
      "Password")
        [ $NOTIFICATION ] && notify-send "Bitwarden: password copied"
        copy_to_clipboard "$PASSWORD"
      ;;
      *)
        [ $NOTIFICATION ] && notify-send "Bitwarden: value copied"

        copy_to_clipboard "$ENTRY"
      ;;
    esac
  done
}

identity_entry() {
  IDX=$(echo "$1" | sed -n -e 's/.*\(\ \([0-9]\+\)\)$/\2/p')
  NAME=$(echo "$1" | sed -e 's/[0-9]\+$//')
  INFO=$(bw list items --session "$SESSION_TOKEN" --nointeraction  --search "$NAME" |
        jq "[.[] | select(.type == 4)] | .[$IDX]")

  PHONE=$(echo "$INFO" | jq .phone | sed -e 's/^"//' -e 's/"$//')
  PASSPORT=$(echo "$INFO" | jq .passportNumber | sed -e 's/^"//' -e 's/"$//')

  while true; do
  ENTRY="$(
    grep . <<EOF | sxmo_dmenu_with_kb.sh -p "$NAME"
Go Back
Close Menu
[ -z $PHONE] && $PHONE
[ -z $PASSPORT] && $PASSPORT
EOF
)"
    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      "Go Back")
        all_logins
      ;;
      *)
        [ $NOTIFICATION ] && notify-send "Bitwarden: value copied"

        copy_to_clipboard "$ENTRY"
      ;;
    esac
  done
}

card_entry() {
  IDX=$(echo "$1" | sed -n -e 's/.*\(\ \([0-9]\+\)\)$/\2/p')
  NAME=$(echo "$1" | sed -e 's/[0-9]\+$//')
  INFO=$(bw list items --session "$SESSION_TOKEN" --nointeraction  --search "$NAME" |
        jq "[.[] | select(.type == 3)] | .[$IDX].card")

  CARDHOLDER=$(echo "$INFO" | jq .cardholderName | sed -e 's/^"//' -e 's/"$//' -e 's/^null$//')
  NUMBER=$(echo "$INFO" | jq .number | sed -e 's/^"//' -e 's/"$//' -e 's/^null$//')
  MONTH=$(echo "$INFO" | jq .expMonth | sed -e 's/^"//' -e 's/"$//' -e 's/^null$//')
  YEAR=$(echo "$INFO" | jq .expYear | sed -e 's/^"//' -e 's/"$//' -e 's/^null$//')
  CVC=$(echo "$INFO" | jq .code | sed -e 's/^"//' -e 's/"$//' -e 's/^null$//')

  while true; do
  ENTRY="$(
    grep . <<EOF | sxmo_dmenu_with_kb.sh -p "$NAME"
Go Back
Close Menu
$([ -n "$CARDHOLDER" ] && echo "$CARDHOLDER")
$([ -n "$NUMBER" ] && echo "$NUMBER")
$([ -n "$YEAR" ] && [ -n "$MONTH" ] && echo "$MONTH/$YEAR")
$([ -n "$CVC" ] && echo "CVC")
EOF
)"
    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      "Go Back")
        all 3
      ;;
      "CVC")
        [ $NOTIFICATION ] && notify-send "Bitwarden: CVC copied"

        copy_to_clipboard "$CVC"
      ;;
      *)
        [ $NOTIFICATION ] && notify-send "Bitwarden: value copied"

        copy_to_clipboard "$ENTRY"
      ;;
    esac
  done
}

password_menu() {
  EMAIL="$1"
  PROMPT="Password"

  while true; do
    ENTRY="$(
      grep . <<EOF | sxmo_dmenu_with_kb.sh -p "$PROMPT"
Close Menu
$([ -z "$1" ] && echo "Logout")
$([ -n "$1" ] && echo "Go Back")
EOF
)"

    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      "Go Back")
        login
      ;;
      "Logout")
        bw logout
        login
      ;;
      *)
        [ $NOTIFICATION ] && notify-send "Bitwarden: Logging in"
        if [ -z "$1" ]; then
          SESSION_TOKEN=$(bw unlock "$ENTRY" --raw --nointeraction)
        else
          SESSION_TOKEN=$(bw login "$EMAIL" "$ENTRY" --raw --nointeraction)
        fi

        if [ "$?" = "0" ]; then
          home
        else
          [ $NOTIFICATION ] && notify-send "Bitwarden: Wrong password"
        fi
      ;;
    esac
  done
}

login() {
  STATUS=$(bw status | jq .status)

  if [ "$STATUS" != '"unauthenticated"' ]; then
    password_menu
  fi

  while true; do
    ENTRY="$(
      grep . <<EOF | sxmo_dmenu_with_kb.sh -p "Email"
Close Menu
EOF
    )"

    case "$ENTRY" in
      "Close Menu")
        exit 0
      ;;
      *)
        password_menu "$ENTRY"
      ;;
    esac
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