#!/bin/bash
# ============================================================
#  Resume Website — One-Command Installer for Ubuntu 20.04+
#  Usage:
#    bash <(curl -Ls https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[•]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗] $1${NC}"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }

# ---- Must be root ----
[[ $EUID -ne 0 ]] && error "Please run as root:  sudo bash install.sh"

clear

# ---- Colors for banner ----
C1='\033[38;5;39m'   # bright blue
C2='\033[38;5;33m'   # medium blue
C3='\033[38;5;27m'   # dark blue
CG='\033[38;5;46m'   # bright green
CY='\033[38;5;226m'  # yellow
CW='\033[1;37m'      # white bold
DIM='\033[2m'

# ---- Animated intro ----
sleep 0.1 && echo ""
sleep 0.05
echo -e "${C1}  ██████╗ ███████╗███████╗██╗   ██╗███╗   ███╗███████╗"
sleep 0.05
echo -e "${C1}  ██╔══██╗${C2}██╔════╝██╔════╝██║   ██║████╗ ████║██╔════╝"
sleep 0.05
echo -e "${C2}  ██████╔╝${C1}█████╗  ███████╗██║   ██║██╔████╔██║█████╗  "
sleep 0.05
echo -e "${C2}  ██╔══██╗${C3}██╔══╝  ╚════██║██║   ██║██║╚██╔╝██║██╔══╝  "
sleep 0.05
echo -e "${C3}  ██║  ██║███████╗███████║╚██████╔╝██║ ╚═╝ ██║███████╗"
sleep 0.05
echo -e "${C3}  ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝${NC}"
echo ""
sleep 0.1

echo -e "  ${CW}Resume Website${NC}  ${DIM}+${NC}  ${CG}One-Click Installer${NC}"
echo ""
sleep 0.05
echo -e "  ${DIM}┌─────────────────────────────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC}  ${CY}Version   ${NC}  v1.0                                ${DIM}│${NC}"
echo -e "  ${DIM}│${NC}  ${CY}Stack     ${NC}  ASP.NET Core 9 · SQLite · Nginx      ${DIM}│${NC}"
echo -e "  ${DIM}│${NC}  ${CY}Features  ${NC}  Admin Panel · SSL · Auto-Renew       ${DIM}│${NC}"
echo -e "  ${DIM}│${NC}  ${CY}Platform  ${NC}  Ubuntu 20.04+                        ${DIM}│${NC}"
echo -e "  ${DIM}└─────────────────────────────────────────────────┘${NC}"
echo ""
sleep 0.05

# Clickable hyperlink (works in modern terminals: GNOME Terminal, iTerm2, Windows Terminal)
GITHUB_URL="https://github.com/AbolfazlTafakori"
echo -e "  ${DIM}Developed by${NC} ${CW}Abolfazl Tafakori${NC}  ${DIM}·${NC}  \e]8;;${GITHUB_URL}\e\\${C1}github.com/AbolfazlTafakori${NC}\e]8;;\e\\"
echo ""
sleep 0.2

# ══════════════════════════════════════════════
#  STEP 1 — Collect information from user
# ══════════════════════════════════════════════
step "Setup Information"
echo ""
echo -e "  ${YELLOW}Make sure DNS records are already pointed to this server's IP.${NC}"
echo -e "  ${YELLOW}Both domains/subdomains must resolve here before SSL can be issued.${NC}"
echo ""

# Main domain
while true; do
    read -rp "$(echo -e "  ${BOLD}Main domain${NC} (e.g. example.com or resume.example.com): ")" MAIN_DOMAIN
    [[ -n "$MAIN_DOMAIN" ]] && break
    echo -e "  ${RED}Domain cannot be empty.${NC}"
done

# Admin subdomain
while true; do
    read -rp "$(echo -e "  ${BOLD}Admin subdomain${NC} (e.g. admin.example.com): ")" ADMIN_DOMAIN
    [[ -n "$ADMIN_DOMAIN" ]] && break
    echo -e "  ${RED}Admin subdomain cannot be empty.${NC}"
done

echo ""

# Admin username
while true; do
    read -rp "$(echo -e "  ${BOLD}Admin username${NC}: ")" ADMIN_USER
    [[ ${#ADMIN_USER} -ge 3 ]] && break
    echo -e "  ${RED}Username must be at least 3 characters.${NC}"
done

# Admin password (min 8 chars, confirmed)
while true; do
    read -rsp "$(echo -e "  ${BOLD}Admin password${NC} (min 8 characters): ")" ADMIN_PASS
    echo ""
    if [[ ${#ADMIN_PASS} -lt 8 ]]; then
        echo -e "  ${RED}Password must be at least 8 characters.${NC}"
        continue
    fi
    read -rsp "$(echo -e "  ${BOLD}Confirm password${NC}: ")" ADMIN_PASS2
    echo ""
    if [[ "$ADMIN_PASS" == "$ADMIN_PASS2" ]]; then
        break
    fi
    echo -e "  ${RED}Passwords do not match. Please try again.${NC}"
done

echo ""
echo -e "  ${GREEN}Configuration summary:${NC}"
echo -e "  Website URL  : ${CYAN}https://${MAIN_DOMAIN}${NC}"
echo -e "  Admin URL    : ${CYAN}https://${ADMIN_DOMAIN}${NC}"
echo -e "  Admin user   : ${CYAN}${ADMIN_USER}${NC}"
echo ""
read -rp "$(echo -e "  ${BOLD}Proceed with installation? [y/N]:${NC} ")" CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && echo "Aborted." && exit 0

# ══════════════════════════════════════════════
#  STEP 2 — Install dependencies
# ══════════════════════════════════════════════
step "Installing System Dependencies"

apt-get update -qq
apt-get install -y -qq curl wget unzip git nginx certbot python3-certbot-nginx
success "nginx, certbot installed"

# .NET 9
if ! command -v dotnet &>/dev/null || [[ $(dotnet --version 2>/dev/null | cut -d. -f1) -lt 9 ]]; then
    info "Installing .NET 9..."

    # Method 1: Microsoft package repo
    UBUNTU_VER=$(lsb_release -rs)
    wget -q "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VER}/packages-microsoft-prod.deb" \
        -O /tmp/ms-prod.deb 2>/dev/null

    if [[ -f /tmp/ms-prod.deb ]]; then
        dpkg -i /tmp/ms-prod.deb >/dev/null 2>&1
        apt-get update -qq
    fi

    # Try SDK first, fall back to runtime-only
    if apt-get install -y -qq dotnet-sdk-9.0 2>/dev/null; then
        success ".NET 9 SDK installed"
    elif apt-get install -y -qq aspnetcore-runtime-9.0 2>/dev/null; then
        # Runtime only — need SDK for building, install via snap or direct download
        info "SDK not in apt, installing via dotnet-install script..."
        wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
        chmod +x /tmp/dotnet-install.sh
        /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet
        ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet
        success ".NET 9 installed via install script"
    else
        # Fallback: official dotnet-install.sh (works on any Linux)
        info "Using official dotnet-install.sh..."
        wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
        chmod +x /tmp/dotnet-install.sh
        /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet
        ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet
        success ".NET 9 installed via install script"
    fi
else
    success ".NET already installed: $(dotnet --version)"
fi

# ══════════════════════════════════════════════
#  STEP 3 — Download & Build
# ══════════════════════════════════════════════
step "Downloading & Building"

INSTALL_DIR="/opt/resume-website"
PUBLISH_DIR="${INSTALL_DIR}/publish"
DATA_DIR="${INSTALL_DIR}/data"
FRONTEND_DIR="${INSTALL_DIR}/Frontend"
APP_PORT=5000
JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%' | fold -w 64 | head -n 1)

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$DATA_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/Backend/ResumeAPI/ResumeAPI.csproj" ]]; then
    info "Using local project files..."
    cp -r "${SCRIPT_DIR}/." "$INSTALL_DIR/"
else
    info "Cloning from GitHub..."
    git clone --depth=1 https://github.com/AbolfazlTafakori/Resume-Website.git "$INSTALL_DIR" \
        || error "Could not clone repository."
fi

info "Building backend..."
cd "$INSTALL_DIR/Backend/ResumeAPI"
dotnet publish -c Release -o "$PUBLISH_DIR" --nologo -q
success "Backend built"

mkdir -p "$PUBLISH_DIR/uploads"

# ══════════════════════════════════════════════
#  STEP 4 — Configure
# ══════════════════════════════════════════════
step "Configuring"

# appsettings.json
cat > "$PUBLISH_DIR/appsettings.json" <<EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Jwt": {
    "Key": "${JWT_SECRET}",
    "Issuer": "ResumeAPI",
    "Audience": "ResumeClient"
  },
  "Urls": "http://localhost:${APP_PORT}"
}
EOF

# Frontend config.js — use /api (nginx proxy)
cat > "$FRONTEND_DIR/js/config.js" <<'JSEOF'
/* Auto-generated by installer */
const API_BASE = '/api';
JSEOF

success "Configuration done"

# ══════════════════════════════════════════════
#  STEP 5 — Systemd Service
# ══════════════════════════════════════════════
step "Creating System Service"

cat > "/etc/systemd/system/resume-api.service" <<EOF
[Unit]
Description=Resume Website API
After=network.target

[Service]
WorkingDirectory=${PUBLISH_DIR}
ExecStart=/usr/bin/dotnet ${PUBLISH_DIR}/ResumeAPI.dll
Restart=always
RestartSec=5
SyslogIdentifier=resume-api
User=www-data
Group=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:${APP_PORT}
Environment=JWT_KEY=${JWT_SECRET}
Environment=ADMIN_PASSWORD=${ADMIN_PASS}
Environment=ADMIN_USERNAME=${ADMIN_USER}
Environment=ALLOWED_ORIGINS=https://${MAIN_DOMAIN},https://${ADMIN_DOMAIN}
Environment=DB_PATH=${DATA_DIR}/resume.db

[Install]
WantedBy=multi-user.target
EOF

chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

systemctl daemon-reload
systemctl enable resume-api
systemctl start resume-api
sleep 3

if systemctl is-active --quiet resume-api; then
    success "API service started"
else
    error "API service failed to start. Check: journalctl -u resume-api -n 30"
fi

# ══════════════════════════════════════════════
#  STEP 6 — Nginx (HTTP first, SSL after)
# ══════════════════════════════════════════════
step "Configuring Nginx"

# Main site
cat > "/etc/nginx/sites-available/resume-main" <<EOF
server {
    listen 80;
    server_name ${MAIN_DOMAIN};

    root ${FRONTEND_DIR};
    index pages/index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location = / {
        return 302 /pages/index.html;
    }

    error_page 404 /pages/404.html;
    location = /pages/404.html { internal; }

    location /api/ {
        proxy_pass http://localhost:${APP_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    client_max_body_size 20M;
}
EOF

# Admin panel
cat > "/etc/nginx/sites-available/resume-admin" <<EOF
server {
    listen 80;
    server_name ${ADMIN_DOMAIN};

    root ${FRONTEND_DIR}/admin;
    index dashboard.html;

    location / {
        try_files \$uri \$uri/ /dashboard.html;
    }

    location /api/ {
        proxy_pass http://localhost:${APP_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    client_max_body_size 20M;
}
EOF

ln -sf /etc/nginx/sites-available/resume-main  /etc/nginx/sites-enabled/resume-main
ln -sf /etc/nginx/sites-available/resume-admin /etc/nginx/sites-enabled/resume-admin
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
success "Nginx configured"

# ══════════════════════════════════════════════
#  STEP 7 — SSL with Let's Encrypt
# ══════════════════════════════════════════════
step "Obtaining SSL Certificates"

info "Getting SSL for ${MAIN_DOMAIN}..."
certbot --nginx -d "$MAIN_DOMAIN" \
    --non-interactive --agree-tos \
    --email "admin@${MAIN_DOMAIN}" \
    --redirect \
    && success "SSL ready for ${MAIN_DOMAIN}" \
    || warn "SSL failed for ${MAIN_DOMAIN} — site will work on HTTP for now"

info "Getting SSL for ${ADMIN_DOMAIN}..."
certbot --nginx -d "$ADMIN_DOMAIN" \
    --non-interactive --agree-tos \
    --email "admin@${MAIN_DOMAIN}" \
    --redirect \
    && success "SSL ready for ${ADMIN_DOMAIN}" \
    || warn "SSL failed for ${ADMIN_DOMAIN} — admin will work on HTTP for now"

# Auto-renew
systemctl enable certbot.timer 2>/dev/null || true
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -

# ══════════════════════════════════════════════
#  Done
# ══════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║        Installation Complete! ✓           ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  🌐  Website   : ${CYAN}https://${MAIN_DOMAIN}${NC}"
echo -e "  🔧  Admin     : ${CYAN}https://${ADMIN_DOMAIN}${NC}"
echo -e "  👤  Username  : ${CYAN}${ADMIN_USER}${NC}"
echo -e "  🔑  Password  : ${CYAN}(the one you set)${NC}"
echo ""
echo -e "  ${YELLOW}Useful commands:${NC}"
echo -e "  systemctl status resume-api       — check API"
echo -e "  systemctl restart resume-api      — restart API"
echo -e "  journalctl -u resume-api -f       — live logs"
echo -e "  certbot renew                     — renew SSL manually"
echo ""
