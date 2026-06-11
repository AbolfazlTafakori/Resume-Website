#!/bin/bash
# ============================================================
#  Resume Website — Management CLI  (r-ui)
#  Usage: r-ui
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SERVICE_FILE='/etc/systemd/system/resume-api.service'
NGINX_MAIN='/etc/nginx/sites-available/resume-main'
NGINX_ADMIN='/etc/nginx/sites-available/resume-admin'
INSTALL_DIR='/opt/resume-website'
PUBLISH_DIR="${INSTALL_DIR}/publish"
DATA_DIR="${INSTALL_DIR}/data"
FRONTEND_DIR="${INSTALL_DIR}/Frontend"

[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

# ── helpers ──────────────────────────────────────────────────
get_env()        { grep -oP "(?<=Environment=${1}=).*" "$SERVICE_FILE" 2>/dev/null | head -1; }
set_env()        { sed -i "s|Environment=${1}=.*|Environment=${1}=${2}|" "$SERVICE_FILE"; }
get_main_domain()  { grep -oP '(?<=server_name )\S+(?=;)' "$NGINX_MAIN"  2>/dev/null | head -1; }
get_admin_domain() { grep -oP '(?<=server_name )\S+(?=;)' "$NGINX_ADMIN" 2>/dev/null | head -1; }

pause() { echo ""; read -rp "$(echo -e "  ${DIM}Press Enter to continue...${NC}")" _; }

svc_status() {
    local s; s=$(systemctl is-active resume-api 2>/dev/null)
    if [[ "$s" == "active" ]]; then echo -e "${GREEN}● running${NC}"
    else echo -e "${RED}● ${s}${NC}"; fi
}

header() {
    clear
    echo ""
    echo -e "  ${BOLD}${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${BOLD}${CYAN}│${NC}              ${BOLD}Resume Website  ·  r-ui${NC}               ${BOLD}${CYAN}│${NC}"
    echo -e "  ${BOLD}${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_status() {
    local main_d admin_d
    main_d=$(get_main_domain)
    admin_d=$(get_admin_domain)
    echo -e "  ${DIM}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC}  API      $(svc_status)"
    echo -e "  ${DIM}│${NC}  Website  ${CYAN}https://${main_d}${NC}"
    echo -e "  ${DIM}│${NC}  Admin    ${CYAN}https://${admin_d}${NC}"
    echo -e "  ${DIM}│${NC}  User     $(get_env ADMIN_USERNAME)"
    echo -e "  ${DIM}└──────────────────────────────────────────────────┘${NC}"
    echo ""
}

section() {
    echo -e "\n  ${BOLD}${BLUE}▸ $1${NC}"
    echo -e "  ${DIM}────────────────────────────────────────${NC}"
}

ok()   { echo -e "\n  ${GREEN}✓  $1${NC}"; }
fail() { echo -e "\n  ${RED}✗  $1${NC}"; }
info() { echo -e "  ${CYAN}·  $1${NC}"; }
warn() { echo -e "  ${YELLOW}!  $1${NC}"; }

# ══════════════════════════════════════════════
#  MENU: Domains
# ══════════════════════════════════════════════
menu_domains() {
    while true; do
        header
        section "Domain Management"
        echo ""
        echo -e "    Main site  : ${CYAN}$(get_main_domain)${NC}"
        echo -e "    Admin panel: ${CYAN}$(get_admin_domain)${NC}"
        echo ""
        echo "    [1]  Change main site domain"
        echo "    [2]  Change admin panel domain"
        echo "    [3]  Re-issue SSL certificates"
        echo "    [0]  ← Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1)
            local main_d; main_d=$(get_main_domain)
            read -rp "  New main site domain: " new_d
            [[ -z "$new_d" ]] && continue
            sed -i "s/server_name ${main_d}/server_name ${new_d}/" "$NGINX_MAIN"
            sed -i "s|https://${main_d}|https://${new_d}|g" "$SERVICE_FILE"
            systemctl daemon-reload
            nginx -t && systemctl reload nginx
            certbot --nginx -d "$new_d" --non-interactive --agree-tos \
                --email "admin@${new_d}" --redirect 2>/dev/null \
                && ok "Domain updated + SSL issued" \
                || warn "Domain updated — SSL failed (check DNS)"
            pause ;;
        2)
            local admin_d; admin_d=$(get_admin_domain)
            read -rp "  New admin domain: " new_d
            [[ -z "$new_d" ]] && continue
            sed -i "s/server_name ${admin_d}/server_name ${new_d}/" "$NGINX_ADMIN"
            sed -i "s|https://${admin_d}|https://${new_d}|g" "$SERVICE_FILE"
            systemctl daemon-reload
            nginx -t && systemctl reload nginx
            certbot --nginx -d "$new_d" --non-interactive --agree-tos \
                --email "admin@${new_d}" --redirect 2>/dev/null \
                && ok "Domain updated + SSL issued" \
                || warn "Domain updated — SSL failed (check DNS)"
            pause ;;
        3)
            local main_d admin_d; main_d=$(get_main_domain); admin_d=$(get_admin_domain)
            certbot --nginx -d "$main_d" -d "$admin_d" \
                --non-interactive --agree-tos \
                --email "admin@${main_d}" --redirect 2>/dev/null \
                && ok "SSL certificates renewed" \
                || fail "SSL renewal failed — check DNS"
            pause ;;
        0) break ;;
        esac
    done
}

# ══════════════════════════════════════════════
#  MENU: Credentials
# ══════════════════════════════════════════════
menu_credentials() {
    while true; do
        header
        section "Admin Credentials"
        echo ""
        echo -e "    Username: ${CYAN}$(get_env ADMIN_USERNAME)${NC}"
        echo -e "    Password: ${DIM}(hidden)${NC}"
        echo ""
        echo "    [1]  Change username"
        echo "    [2]  Change password"
        echo "    [3]  Change both"
        echo "    [0]  ← Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1)
            read -rp "  New username (min 3 chars): " new_u
            [[ ${#new_u} -lt 3 ]] && fail "Too short" && pause && continue
            set_env ADMIN_USERNAME "$new_u"
            systemctl daemon-reload && systemctl restart resume-api
            ok "Username changed to: ${new_u}"
            pause ;;
        2)
            while true; do
                read -rsp "  New password (min 8 chars): " new_p; echo
                [[ ${#new_p} -lt 8 ]] && fail "Too short" && continue
                read -rsp "  Confirm: " new_p2; echo
                [[ "$new_p" == "$new_p2" ]] && break
                fail "Passwords do not match"
            done
            set_env ADMIN_PASSWORD "$new_p"
            systemctl daemon-reload && systemctl restart resume-api
            ok "Password changed"
            pause ;;
        3)
            read -rp "  New username (min 3 chars): " new_u
            [[ ${#new_u} -lt 3 ]] && fail "Too short" && pause && continue
            while true; do
                read -rsp "  New password (min 8 chars): " new_p; echo
                [[ ${#new_p} -lt 8 ]] && fail "Too short" && continue
                read -rsp "  Confirm: " new_p2; echo
                [[ "$new_p" == "$new_p2" ]] && break
                fail "Passwords do not match"
            done
            set_env ADMIN_USERNAME "$new_u"
            set_env ADMIN_PASSWORD "$new_p"
            systemctl daemon-reload && systemctl restart resume-api
            ok "Credentials updated"
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
        section "Service Management"
        echo ""
        show_status
        echo "    [1]  Restart API"
        echo "    [2]  Stop API"
        echo "    [3]  Start API"
        echo "    [4]  Live logs  (Ctrl+C to exit)"
        echo "    [5]  Last 50 log lines"
        echo "    [0]  ← Back"
        echo ""
        read -rp "  Choice: " ch
        case $ch in
        1) systemctl restart resume-api && ok "Service restarted"; pause ;;
        2) systemctl stop   resume-api && warn "Service stopped";  pause ;;
        3) systemctl start  resume-api && ok "Service started";    pause ;;
        4) journalctl -u resume-api -f ;;
        5) journalctl -u resume-api -n 50 --no-pager; pause ;;
        0) break ;;
        esac
    done
}

# ══════════════════════════════════════════════
#  MENU: Update
# ══════════════════════════════════════════════
menu_update() {
    header
    section "Update Resume Website"
    echo ""
    echo -e "  This will:"
    echo -e "    ${DIM}·${NC} Pull the latest code from GitHub"
    echo -e "    ${DIM}·${NC} Rebuild the backend"
    echo -e "    ${DIM}·${NC} Replace frontend files"
    echo -e "    ${DIM}·${NC} Restart the API service"
    echo -e "    ${DIM}·${NC} ${GREEN}Keep your data, credentials and domains intact${NC}"
    echo ""
    read -rp "$(echo -e "  ${YELLOW}Proceed with update? [y/N]:${NC} ")" CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && return

    # ── Save current settings ──
    local main_d admin_d jwt_key admin_user admin_pass db_path app_port allowed_origins dotnet_exec
    main_d=$(get_main_domain)
    admin_d=$(get_admin_domain)
    jwt_key=$(get_env JWT_KEY)
    admin_user=$(get_env ADMIN_USERNAME)
    admin_pass=$(get_env ADMIN_PASSWORD)
    db_path=$(get_env DB_PATH)
    app_port=$(grep -oP '(?<=http://localhost:)\d+' "$SERVICE_FILE" | head -1)
    allowed_origins=$(get_env ALLOWED_ORIGINS)
    dotnet_exec=$(grep -oP '(?<=ExecStart=)\S+' "$SERVICE_FILE" | head -1)
    [[ -z "$app_port" ]] && app_port=5000

    echo ""
    info "Stopping service..."
    systemctl stop resume-api

    info "Pulling latest code..."
    local TMP_DIR="/tmp/resume-update-$$"
    cd /tmp
    git clone --depth=1 https://github.com/AbolfazlTafakori/Resume-Website.git "$TMP_DIR" 2>&1 \
        || { fail "Git clone failed — check internet connection"; pause; return; }

    info "Rebuilding backend..."
    rm -rf /tmp/resume-build
    mkdir -p /tmp/resume-build
    cd "${TMP_DIR}/Backend/ResumeAPI" || { fail "Source directory not found"; pause; return; }
    "$dotnet_exec" publish -c Release \
        -o "$PUBLISH_DIR" \
        -p:BaseIntermediateOutputPath=/tmp/resume-build/obj/ \
        -p:BaseOutputPath=/tmp/resume-build/bin/ \
        --nologo 2>&1 | grep -vE "^[[:space:]]*$|Telemetry|telemetry|learn\.microsoft"

    if [[ ! -f "$PUBLISH_DIR/ResumeAPI.dll" ]]; then
        fail "Build failed — keeping previous version"
        systemctl start resume-api
        rm -rf "$TMP_DIR"
        pause; return
    fi

    info "Updating frontend files..."
    # Save production config.js, replace all frontend, restore it
    local saved_config
    saved_config=$(cat "${FRONTEND_DIR}/js/config.js" 2>/dev/null || echo "const API_BASE = '/api';")
    cp -r "${TMP_DIR}/Frontend/." "${FRONTEND_DIR}/"
    echo "$saved_config" > "${FRONTEND_DIR}/js/config.js"

    info "Updating management tool..."
    cp "${TMP_DIR}/r-ui.sh" /usr/local/bin/r-ui
    chmod +x /usr/local/bin/r-ui

    # ── Regenerate nginx performance config (self-heal) ──
    # NOTE: gzip is already enabled in the main nginx.conf; do NOT redeclare
    # `gzip on;` here or nginx refuses to load any config and the site goes down.
    info "Refreshing nginx performance config..."
    cat > /etc/nginx/conf.d/performance.conf <<'NGINXPERF'
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/javascript application/javascript application/json image/svg+xml;

open_file_cache max=1000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;

client_max_body_size 20M;
keepalive_timeout 65;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

# Limit login endpoint rate
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
NGINXPERF
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        info "Nginx config refreshed and reloaded"
    else
        warn "Nginx config test failed — left previous config running"
    fi

    # ── Restore appsettings ──
    cat > "$PUBLISH_DIR/appsettings.json" <<APPEOF
{
  "Logging": { "LogLevel": { "Default": "Warning", "Microsoft.AspNetCore": "Warning" } },
  "AllowedHosts": "*",
  "Jwt": { "Key": "${jwt_key}", "Issuer": "ResumeAPI", "Audience": "ResumeClient" },
  "Urls": "http://localhost:${app_port}"
}
APPEOF

    info "Fixing permissions..."
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 775 "$DATA_DIR" "${PUBLISH_DIR}/uploads"

    rm -rf "$TMP_DIR"

    info "Starting service..."
    systemctl daemon-reload
    systemctl start resume-api
    sleep 2

    if systemctl is-active --quiet resume-api; then
        ok "Update complete — service is running"
    else
        warn "Service did not start — check logs:"
        warn "  journalctl -u resume-api -n 30 --no-pager"
    fi
    echo ""
    echo -e "  ${DIM}Website :${NC} ${CYAN}https://${main_d}${NC}"
    echo -e "  ${DIM}Admin   :${NC} ${CYAN}https://${admin_d}${NC}"
    pause
}

# ══════════════════════════════════════════════
#  MENU: Uninstall
# ══════════════════════════════════════════════
menu_uninstall() {
    header
    section "Uninstall Resume Website"
    echo ""
    echo -e "  ${RED}${BOLD}⚠  This will permanently remove:${NC}"
    echo ""
    echo -e "    ${DIM}·${NC} API service  (resume-api)"
    echo -e "    ${DIM}·${NC} All website files  (${INSTALL_DIR})"
    echo -e "    ${DIM}·${NC} Nginx configs  (resume-main, resume-admin)"
    echo -e "    ${DIM}·${NC} r-ui management tool"
    echo ""

    local main_d; main_d=$(get_main_domain)

    read -rp "$(echo -e "  ${YELLOW}Also remove SSL certificates? [y/N]:${NC} ")" RM_SSL

    echo ""
    echo -e "  ${RED}${BOLD}This cannot be undone.${NC}"
    read -rp "$(echo -e "  Type  ${BOLD}yes${NC}  to confirm uninstall: ")" FINAL
    if [[ "$FINAL" != "yes" ]]; then
        warn "Uninstall cancelled"
        pause; return
    fi

    echo ""
    info "Stopping and disabling service..."
    systemctl stop    resume-api 2>/dev/null
    systemctl disable resume-api 2>/dev/null
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload

    info "Removing nginx configs..."
    rm -f /etc/nginx/sites-enabled/resume-main
    rm -f /etc/nginx/sites-enabled/resume-admin
    rm -f /etc/nginx/sites-available/resume-main
    rm -f /etc/nginx/sites-available/resume-admin
    nginx -t 2>/dev/null && systemctl reload nginx

    if [[ "$RM_SSL" =~ ^[Yy]$ ]]; then
        info "Removing SSL certificates..."
        local admin_d; admin_d=$(get_admin_domain 2>/dev/null || true)
        certbot delete --cert-name "$main_d"  --non-interactive 2>/dev/null || true
        certbot delete --cert-name "$admin_d" --non-interactive 2>/dev/null || true
    fi

    info "Removing website files..."
    rm -rf "$INSTALL_DIR"

    info "Removing r-ui tool..."
    rm -f /usr/local/bin/r-ui

    echo ""
    echo -e "  ${GREEN}${BOLD}✓  Uninstall complete.${NC}"
    echo -e "  ${DIM}Nginx and .NET are still installed (system packages — remove manually if needed).${NC}"
    echo ""
    exit 0
}

# ══════════════════════════════════════════════
#  MAIN MENU
# ══════════════════════════════════════════════
while true; do
    header
    show_status
    echo -e "  ${BOLD}Main Menu${NC}"
    echo ""
    echo "    [1]  Domain management"
    echo "    [2]  Admin credentials"
    echo "    [3]  Service management"
    echo "    [4]  Update to latest version"
    echo ""
    echo -e "    ${RED}[5]  Uninstall${NC}"
    echo ""
    echo "    [0]  Exit"
    echo ""
    read -rp "  Choice: " choice
    case $choice in
    1) menu_domains ;;
    2) menu_credentials ;;
    3) menu_service ;;
    4) menu_update ;;
    5) menu_uninstall ;;
    0) echo ""; exit 0 ;;
    esac
done
