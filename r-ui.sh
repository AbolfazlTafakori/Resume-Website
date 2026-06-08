#!/bin/bash
# ============================================================
#  Resume Website -- Management CLI
#  Usage: r-ui
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SERVICE_FILE='/etc/systemd/system/resume-api.service'
NGINX_MAIN='/etc/nginx/sites-available/resume-main'
NGINX_ADMIN='/etc/nginx/sites-available/resume-admin'

[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

# ── helpers ──────────────────────────────────────────────────
get_env()  { grep -oP "(?<=Environment=${1}=).*" "$SERVICE_FILE" 2>/dev/null | head -1; }
set_env()  { local k=$1 v=$2; sed -i "s|Environment=${k}=.*|Environment=${k}=${v}|" "$SERVICE_FILE"; }
get_main_domain()  { grep -oP '(?<=server_name )\S+(?=;)' "$NGINX_MAIN"  2>/dev/null | head -1; }
get_admin_domain() { grep -oP '(?<=server_name )\S+(?=;)' "$NGINX_ADMIN" 2>/dev/null | head -1; }

pause() { echo ""; read -rp "  (Press Enter to continue...)" _; }

header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo '  +-----------------------------------------+'
    echo '  |       Resume Website  --  r-ui          |'
    echo '  +-----------------------------------------+'
    echo -e "${NC}"
}

show_status() {
    local svc col
    svc=$(systemctl is-active resume-api 2>/dev/null)
    col="${GREEN}" && [[ "$svc" != 'active' ]] && col="${RED}"
    echo -e "  ${DIM}API service  :${NC} ${col}${svc}${NC}"
    echo -e "  ${DIM}Main site    :${NC} ${CYAN}https://$(get_main_domain)${NC}"
    echo -e "  ${DIM}Admin panel  :${NC} ${CYAN}https://$(get_admin_domain)${NC}"
    echo -e "  ${DIM}Admin user   :${NC} $(get_env ADMIN_USERNAME)"
    echo ""
}

# ══════════════════════════════════════════════
#  MENU: Domains
# ══════════════════════════════════════════════
menu_domains() {
    while true; do
        header
        echo -e "  ${BOLD}Domain Management${NC}"
        echo ""
        local main_d admin_d
        main_d=$(get_main_domain)
        admin_d=$(get_admin_domain)
        echo -e "  Main site domain : ${CYAN}${main_d}${NC}"
        echo -e "  Admin panel domain: ${CYAN}${admin_d}${NC}"
        echo ""
        echo "  [1] Change main site domain"
        echo "  [2] Change admin panel domain"
        echo "  [3] Re-issue SSL certificates"
        echo "  [0] Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1)
            read -rp "  New main site domain: " new_d
            [[ -z "$new_d" ]] && continue
            sed -i "s/server_name ${main_d}/server_name ${new_d}/" "$NGINX_MAIN"
            sed -i "s|https://${main_d}|https://${new_d}|g" "$SERVICE_FILE"
            systemctl daemon-reload
            nginx -t && systemctl reload nginx
            certbot --nginx -d "$new_d" --non-interactive --agree-tos \
                --email "admin@${new_d}" --redirect 2>/dev/null \
                && echo -e "  ${GREEN}Done: domain updated + SSL issued${NC}" \
                || echo -e "  ${YELLOW}Domain updated but SSL failed (check DNS)${NC}"
            pause ;;
        2)
            read -rp "  New admin panel domain: " new_d
            [[ -z "$new_d" ]] && continue
            sed -i "s/server_name ${admin_d}/server_name ${new_d}/" "$NGINX_ADMIN"
            sed -i "s|https://${admin_d}|https://${new_d}|g" "$SERVICE_FILE"
            systemctl daemon-reload
            nginx -t && systemctl reload nginx
            certbot --nginx -d "$new_d" --non-interactive --agree-tos \
                --email "admin@${new_d}" --redirect 2>/dev/null \
                && echo -e "  ${GREEN}Done: domain updated + SSL issued${NC}" \
                || echo -e "  ${YELLOW}Domain updated but SSL failed (check DNS)${NC}"
            pause ;;
        3)
            certbot --nginx -d "$main_d" -d "$admin_d" \
                --non-interactive --agree-tos \
                --email "admin@${main_d}" --redirect 2>/dev/null \
                && echo -e "  ${GREEN}SSL certificates renewed${NC}" \
                || echo -e "  ${YELLOW}SSL renewal failed -- check DNS${NC}"
            pause ;;
        0) break ;;
        esac
    done
}

# ══════════════════════════════════════════════
#  MENU: Admin Credentials
# ══════════════════════════════════════════════
menu_credentials() {
    while true; do
        header
        echo -e "  ${BOLD}Admin Credentials${NC}"
        echo ""
        echo -e "  Current username: ${CYAN}$(get_env ADMIN_USERNAME)${NC}"
        echo -e "  Current password: ${DIM}(hidden)${NC}"
        echo ""
        echo "  [1] Change username"
        echo "  [2] Change password"
        echo "  [3] Change both"
        echo "  [0] Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1)
            read -rp "  New username (min 3 chars): " new_u
            [[ ${#new_u} -lt 3 ]] && echo -e "  ${RED}Too short${NC}" && pause && continue
            set_env ADMIN_USERNAME "$new_u"
            systemctl daemon-reload && systemctl restart resume-api
            echo -e "  ${GREEN}Username changed to: ${new_u}${NC}"
            pause ;;
        2)
            while true; do
                read -rsp "  New password (min 8 chars): " new_p; echo
                [[ ${#new_p} -lt 8 ]] && echo -e "  ${RED}Too short${NC}" && continue
                read -rsp "  Confirm password: " new_p2; echo
                [[ "$new_p" == "$new_p2" ]] && break
                echo -e "  ${RED}Passwords do not match${NC}"
            done
            set_env ADMIN_PASSWORD "$new_p"
            systemctl daemon-reload && systemctl restart resume-api
            echo -e "  ${GREEN}Password changed${NC}"
            pause ;;
        3)
            read -rp "  New username (min 3 chars): " new_u
            [[ ${#new_u} -lt 3 ]] && echo -e "  ${RED}Too short${NC}" && pause && continue
            while true; do
                read -rsp "  New password (min 8 chars): " new_p; echo
                [[ ${#new_p} -lt 8 ]] && echo -e "  ${RED}Too short${NC}" && continue
                read -rsp "  Confirm password: " new_p2; echo
                [[ "$new_p" == "$new_p2" ]] && break
                echo -e "  ${RED}Passwords do not match${NC}"
            done
            set_env ADMIN_USERNAME "$new_u"
            set_env ADMIN_PASSWORD "$new_p"
            systemctl daemon-reload && systemctl restart resume-api
            echo -e "  ${GREEN}Username and password updated${NC}"
            pause ;;
        0) break ;;
        esac
    done
}

# ══════════════════════════════════════════════
#  MENU: Service
# ══════════════════════════════════════════════
menu_service() {
    while true; do
        header
        echo -e "  ${BOLD}Service Management${NC}"
        echo ""
        show_status
        echo "  [1] Restart API service"
        echo "  [2] Stop API service"
        echo "  [3] Start API service"
        echo "  [4] Live logs  (Ctrl+C to exit)"
        echo "  [5] Last 50 log lines"
        echo "  [0] Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1) systemctl restart resume-api && echo -e "  ${GREEN}Restarted${NC}"; pause ;;
        2) systemctl stop   resume-api && echo -e "  ${YELLOW}Stopped${NC}";   pause ;;
        3) systemctl start  resume-api && echo -e "  ${GREEN}Started${NC}";    pause ;;
        4) journalctl -u resume-api -f ;;
        5) journalctl -u resume-api -n 50 --no-pager; pause ;;
        0) break ;;
        esac
    done
}

# ══════════════════════════════════════════════
#  MAIN MENU
# ══════════════════════════════════════════════
while true; do
    header
    show_status
    echo -e "  ${BOLD}Main Menu${NC}"
    echo ""
    echo "  [1]  Domain management"
    echo "  [2]  Admin credentials  (username / password)"
    echo "  [3]  Service management  (restart / logs)"
    echo "  [0]  Exit"
    echo ""
    read -rp "  Choice: " choice
    case $choice in
    1) menu_domains ;;
    2) menu_credentials ;;
    3) menu_service ;;
    0) echo ""; exit 0 ;;
    esac
done
