#!/bin/bash
# ============================================================
#  Resume Website — One-Command Installer for Ubuntu 20.04+
#  Usage:
#    bash <(curl -Ls https://raw.githubusercontent.com/AbolfazlTafakori/Resume-Website/main/install.sh)
# ============================================================

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

C1='\033[38;5;39m'
C2='\033[38;5;33m'
C3='\033[38;5;27m'
CG='\033[38;5;46m'
CY='\033[38;5;226m'
CW='\033[1;37m'
DIM='\033[2m'

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

while true; do
    read -rp "$(echo -e "  ${BOLD}Main domain${NC} (e.g. resume.example.com): ")" MAIN_DOMAIN
    [[ -n "$MAIN_DOMAIN" ]] && break
    echo -e "  ${RED}Domain cannot be empty.${NC}"
done

while true; do
    read -rp "$(echo -e "  ${BOLD}Admin subdomain${NC} (e.g. admin.example.com): ")" ADMIN_DOMAIN
    [[ -n "$ADMIN_DOMAIN" ]] && break
    echo -e "  ${RED}Admin subdomain cannot be empty.${NC}"
done

echo ""

while true; do
    read -rp "$(echo -e "  ${BOLD}Admin username${NC}: ")" ADMIN_USER
    [[ ${#ADMIN_USER} -ge 3 ]] && break
    echo -e "  ${RED}Username must be at least 3 characters.${NC}"
done

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
#  STEP 2 — Install system dependencies
# ══════════════════════════════════════════════
step "Installing System Dependencies"

apt-get update -qq
apt-get install -y -qq curl wget unzip git nginx certbot python3-certbot-nginx lsb-release
success "nginx, certbot, git installed"

# ── .NET 9 ──────────────────────────────────
DOTNET_EXEC=""

dotnet_ok() {
    command -v dotnet &>/dev/null && [[ "$(dotnet --version 2>/dev/null | cut -d. -f1)" -ge 9 ]]
}

if dotnet_ok; then
    DOTNET_EXEC="$(command -v dotnet)"
    success ".NET already installed: $(dotnet --version)  [${DOTNET_EXEC}]"
else
    info "Installing .NET 9 SDK..."

    UBUNTU_VER=$(lsb_release -rs 2>/dev/null | cut -d. -f1)
    if [[ "$UBUNTU_VER" -ge 24 ]]; then
        info "Trying Ubuntu built-in .NET packages..."
        apt-get install -y -qq dotnet-sdk-9.0 2>/dev/null \
            || apt-get install -y -qq dotnet9 2>/dev/null \
            || true
    fi

    # Fallback: official dotnet-install.sh (works on all Ubuntu versions)
    if ! dotnet_ok; then
        info "Using official dotnet-install.sh (universal fallback)..."
        wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh \
            || curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
            || error "Could not download dotnet-install.sh — check internet connection."
        chmod +x /tmp/dotnet-install.sh
        /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet 2>&1 | tail -5

        # Make dotnet executable by all users including www-data
        chmod -R o+rx /usr/share/dotnet

        # Symlink into standard PATH locations
        ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet
        ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet
        export PATH="$PATH:/usr/share/dotnet"
    fi

    if dotnet_ok; then
        DOTNET_EXEC="$(command -v dotnet)"
        success ".NET 9 installed: $(dotnet --version)  [${DOTNET_EXEC}]"
    else
        error ".NET 9 installation failed. Check internet connection and try again."
    fi
fi

# Prefer the real binary path for systemd (avoids shell wrapper issues with www-data)
if [[ -f /usr/share/dotnet/dotnet ]]; then
    chmod o+rx /usr/share/dotnet/dotnet
    DOTNET_EXEC="/usr/share/dotnet/dotnet"
fi
[[ -z "$DOTNET_EXEC" ]] && DOTNET_EXEC="$(command -v dotnet)"
info "Using dotnet binary: ${DOTNET_EXEC}"

# ══════════════════════════════════════════════
#  STEP 3 — Download & Build
# ══════════════════════════════════════════════
step "Downloading & Building"

INSTALL_DIR="/opt/resume-website"
PUBLISH_DIR="${INSTALL_DIR}/publish"
DATA_DIR="${INSTALL_DIR}/data"
FRONTEND_DIR="${INSTALL_DIR}/Frontend"
APP_PORT=5000
JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

rm -rf "$INSTALL_DIR"

# Check if running from a local copy of the repo
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi

if [[ -n "$SCRIPT_DIR" ]] && [[ -f "${SCRIPT_DIR}/Backend/ResumeAPI/ResumeAPI.csproj" ]]; then
    info "Using local project files..."
    mkdir -p "$INSTALL_DIR"
    cp -r "${SCRIPT_DIR}/." "$INSTALL_DIR/"
else
    info "Cloning from GitHub..."
    git clone --depth=1 https://github.com/AbolfazlTafakori/Resume-Website.git "$INSTALL_DIR" \
        || error "Could not clone repository. Check internet connection."
fi

mkdir -p "$DATA_DIR" "${PUBLISH_DIR}/uploads"

info "Building backend (this may take 1-2 minutes on first run)..."
rm -rf /tmp/resume-build
mkdir -p /tmp/resume-build/obj /tmp/resume-build/bin
chmod -R 777 /tmp/resume-build

cd "${INSTALL_DIR}/Backend/ResumeAPI"

"$DOTNET_EXEC" publish -c Release \
    -o "$PUBLISH_DIR" \
    -p:BaseIntermediateOutputPath=/tmp/resume-build/obj/ \
    -p:BaseOutputPath=/tmp/resume-build/bin/ \
    --nologo 2>&1 | grep -vE "^[[:space:]]*$|Telemetry|telemetry|learn\.microsoft|dotnet-cli|dotnet dev-certs|Write your first|Find out what|Explore doc|Report issues|Use \.dotnet"

if [[ ! -f "$PUBLISH_DIR/ResumeAPI.dll" ]]; then
    error "Build failed — ResumeAPI.dll not found. Check build output above."
fi
success "Backend built successfully"

# ══════════════════════════════════════════════
#  STEP 4 — Configure
# ══════════════════════════════════════════════
step "Configuring"

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

# Production config.js — always /api (nginx proxies to backend)
cat > "$FRONTEND_DIR/js/config.js" <<JSEOF
/* Auto-generated by installer */
const API_BASE = '/api';
JSEOF

success "Configuration done"

# ══════════════════════════════════════════════
#  STEP 5 — Permissions
# ══════════════════════════════════════════════
step "Setting Permissions"

chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 775 "$DATA_DIR" "${PUBLISH_DIR}/uploads"
success "Permissions set"

# ══════════════════════════════════════════════
#  STEP 6 — Systemd service
# ══════════════════════════════════════════════
step "Creating System Service"

cat > "/etc/systemd/system/resume-api.service" <<EOF
[Unit]
Description=Resume Website API
After=network.target

[Service]
WorkingDirectory=${PUBLISH_DIR}
ExecStart=${DOTNET_EXEC} ${PUBLISH_DIR}/ResumeAPI.dll
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

systemctl daemon-reload
systemctl enable resume-api
systemctl start resume-api

# Wait up to 20 seconds for service to become active
info "Waiting for API service to start..."
SERVICE_OK=false
for i in $(seq 1 20); do
    sleep 1
    if systemctl is-active --quiet resume-api; then
        SERVICE_OK=true
        break
    fi
done

if $SERVICE_OK; then
    success "API service is running"
else
    warn "API service did not start within 20 seconds."
    warn "Installation will continue — diagnose with:"
    warn "  journalctl -u resume-api -n 50 --no-pager"
fi

# ══════════════════════════════════════════════
#  STEP 7 — Nginx
# ══════════════════════════════════════════════
step "Configuring Nginx"

rm -f /etc/nginx/sites-enabled/default

# ── Global nginx performance settings ───────
# NOTE: gzip is already enabled in the main nginx.conf http{} block.
# Do NOT redeclare `gzip on;` here — it makes the directive duplicate
# and nginx refuses to load any config (site goes down).
cat > /etc/nginx/conf.d/performance.conf <<'NGINXPERF'
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/javascript application/javascript application/json image/svg+xml;

open_file_cache max=1000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;

client_max_body_size 100M;
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

# ── Main resume site ────────────────────────
cat > "/etc/nginx/sites-available/resume-main" <<EOF
server {
    listen 80;
    server_name ${MAIN_DOMAIN};

    root ${FRONTEND_DIR};
    index pages/index.html;

    location = / {
        return 302 /pages/index.html;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    # NOTE: '^~' on the /api/ prefix below makes nginx skip regex locations for
    # anything under /api/. Without it these static-file regexes would match
    # uploaded media like /api/uploads/avatar.png (ends in .png) and try to serve
    # it from disk -> 404, so avatars/project images never render on the site.
    location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|woff2|woff|ttf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }

    location ~* \.(css|js)$ {
        expires 7d;
        add_header Cache-Control "public";
        try_files \$uri =404;
    }

    error_page 404 /pages/404.html;
    location = /pages/404.html { internal; }

    location = /api/auth/login {
        limit_req zone=login burst=3 nodelay;
        proxy_pass         http://localhost:${APP_PORT}/api/auth/login;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }

    location ^~ /api/ {
        proxy_pass         http://localhost:${APP_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    client_max_body_size 100M;
}
EOF

# ── Admin panel ──────────────────────────────
# Root is Frontend/ (not Frontend/admin/) so ../js/ ../css/ paths resolve correctly
cat > "/etc/nginx/sites-available/resume-admin" <<EOF
server {
    listen 80;
    server_name ${ADMIN_DOMAIN};

    root ${FRONTEND_DIR};
    index admin/login.html;

    location = / {
        return 302 /admin/login.html;
    }

    location / {
        try_files \$uri \$uri/ /admin/login.html;
    }

    location ^~ /api/ {
        proxy_pass         http://localhost:${APP_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    client_max_body_size 100M;
}
EOF

ln -sf /etc/nginx/sites-available/resume-main  /etc/nginx/sites-enabled/resume-main
ln -sf /etc/nginx/sites-available/resume-admin /etc/nginx/sites-enabled/resume-admin

if nginx -t 2>/dev/null; then
    systemctl reload nginx
    success "Nginx configured and reloaded"
else
    nginx -t
    warn "Nginx config has errors — check output above."
fi

# ══════════════════════════════════════════════
#  STEP 8 — SSL with Let's Encrypt
# ══════════════════════════════════════════════
step "Obtaining SSL Certificates"

info "Getting SSL for ${MAIN_DOMAIN}..."
if certbot --nginx -d "$MAIN_DOMAIN" \
    --non-interactive --agree-tos \
    --email "admin@${MAIN_DOMAIN}" \
    --redirect 2>/dev/null; then
    success "SSL ready for ${MAIN_DOMAIN}"
else
    warn "SSL failed for ${MAIN_DOMAIN} — make sure DNS is pointed here, then run:"
    warn "  certbot --nginx -d ${MAIN_DOMAIN} --redirect"
fi

info "Getting SSL for ${ADMIN_DOMAIN}..."
if certbot --nginx -d "$ADMIN_DOMAIN" \
    --non-interactive --agree-tos \
    --email "admin@${MAIN_DOMAIN}" \
    --redirect 2>/dev/null; then
    success "SSL ready for ${ADMIN_DOMAIN}"
else
    warn "SSL failed for ${ADMIN_DOMAIN} — make sure DNS is pointed here, then run:"
    warn "  certbot --nginx -d ${ADMIN_DOMAIN} --redirect"
fi

# Auto-renew via systemd timer (preferred) or cron fallback
systemctl enable certbot.timer 2>/dev/null \
    || { (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -; }

# ══════════════════════════════════════════════
#  STEP 9 — Install r-ui management tool
# ══════════════════════════════════════════════
step "Installing r-ui Management Tool"

cp "${INSTALL_DIR}/r-ui.sh" /usr/local/bin/r-ui
chmod +x /usr/local/bin/r-ui
success "r-ui installed — type 'r-ui' anytime to manage your site"

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
echo -e "  🔑  Password  : ${CYAN}${ADMIN_PASS}${NC}"
echo ""
echo -e "  ${YELLOW}Management tool:${NC}"
echo -e "  ${BOLD}r-ui${NC}   — change domains, credentials, restart service"
echo ""
echo -e "  ${YELLOW}Other useful commands:${NC}"
echo -e "  journalctl -u resume-api -f          — live API logs"
echo -e "  certbot renew                        — renew SSL manually"
echo ""
if ! $SERVICE_OK; then
    echo -e "  ${RED}⚠  API service did not start automatically.${NC}"
    echo -e "  Run this to diagnose:"
    echo -e "  ${YELLOW}journalctl -u resume-api -n 50 --no-pager${NC}"
    echo ""
fi
