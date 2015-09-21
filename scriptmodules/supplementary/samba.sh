#!/usr/bin/env bash

# This file is part of RetroPie.
# 
# (c) Copyright 2012-2015  Florian Müller (contact@petrockblock.com)
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="samba"
rp_module_desc="Configure Samba ROM Shares"
rp_module_menus="3+configure"
rp_module_flags="nobin"

function depends_samba() {
    getDepends samba
}

function remove_share_samba() {
    local name="$1"
    [[ -z "$name" || ! -f /etc/samba/smb.conf ]] && return
    sed -i "/^\[$name\]/,/^force user/d" /etc/samba/smb.conf
}

function add_share_samba() {
    local name="$1"
    local path="$2"
    [[ -z "name" || -z "$path" ]] && return
    remove_share_samba "$name"
    cat >>/etc/samba/smb.conf <<_EOF_
[$1]
comment = $name
path = "$path"
writeable = yes
guest ok = yes
create mask = 0644
directory mask = 0755
force user = $user
_EOF_
}

function restart_samba() {
    service samba restart
}

function install_shares_samba() {
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
    add_share_samba "roms" "$romdir"
    add_share_samba "bios" "$home/RetroPie/BIOS"
    add_share_samba "configs" "$configdir"
    add_share_samba "splashscreens" "$datadir/splashscreens"
    restart_samba_samba
}

function remove_shares_samba() {
    local name
    for name in roms bios configs splashscreens; do
        remove_share_samba "$name"
    done
}

function remove_samba() {
    apt-get remove -y samba
}

function configure_samba() {
    while true; do
        local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option" 22 76 16)
        local options=(
            1 "Install RetroPie Samba shares"
            2 "Remove RetroPie Samba shares"
            3 "Manually edit /etc/samba/smb.conf"
            4 "Restart Samba service"
            5 "Remove Samba service"
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case $choice in
                1)
                    rp_callModule "$md_id" depends
                    rp_callModule "$md_id" install_shares
                    printMsgs "dialog" "Enabled shares"
                    ;;
                2)
                    rp_callModule "$md_id" remove_shares
                    printMsgs "dialog" "Removed shares"
                    ;;
                3)
                    editFile /etc/samba/smb.conf
                    ;;
                4)
                    rp_callModule "$md_id" restart
                    ;;
                5)
                    rp_callModule "$md_id" remove
                    printMsgs "dialog" "Removed Samba service"
                    ;;
            esac
        else
            break
        fi
    done
}
