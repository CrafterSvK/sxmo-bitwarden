## SXMO Bitwarden
Userscript to enable browsing entries in Bitwarden using dmenu

Note: It is little slow due to `bitwarden-cli` and `jq` queries.

Features:
- Viewing/copying usernames/password
- Viewing/copying cards

TODO features:
- [x] Disable notifications
- [ ] Two-step login
- [ ] API key login
- [ ] TOTP
- [ ] Secure notes view/edit
- [ ] Better Identities view
- [ ] PIN Unlocking
- [ ] Optimization

## Installing:
- dependencies: `jq`, `bitwarden-cli`
- install `bitwarden-cli`
- - Archlinux `sudo pacman -S bitwarden-cli`
- - npm `npm install -g @bitwarden/cli`
- copy userscript to `~/.config/sxmo/userscripts/sxmo_bitwarden.sh`