# Resume Website

A full-stack personal resume website with an admin panel to manage all content — built with **ASP.NET Core 9**, **SQLite**, and a clean vanilla HTML/CSS/JS frontend.

---

## ✨ Features

- 🎨 Fully responsive design
- 🔧 Admin panel to edit all content (profile, skills, projects, experience, education, social links)
- 🖼️ Image upload support (avatar, project thumbnails)
- 🔐 JWT authentication with BCrypt password hashing
- 🗄️ SQLite database (zero configuration)
- 🌐 nginx reverse proxy with HTTPS (Let's Encrypt)
- 🔄 Auto SSL renewal
- 🛠️ `r-ui` CLI tool for server management

---

## 🚀 One-Command Install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/AbolfazlTafakori/Resume-Website/main/install.sh)
```

The installer will ask for:
- Main site domain (e.g. `resume.example.com`)
- Admin panel domain (e.g. `admin.example.com`)
- Admin username
- Admin password (min 8 characters)

Then it automatically:
1. Installs .NET 9 SDK
2. Clones and builds the project
3. Creates a systemd service
4. Configures nginx for both domains
5. Issues SSL certificates via Let's Encrypt
6. Installs the `r-ui` management tool

> ⚠️ Make sure DNS records for both domains point to your server's IP **before** running the installer.

---

## 🛠️ Server Management — `r-ui`

After installation, type `r-ui` on the server to open the management menu:

```
  +-----------------------------------------+
  |       Resume Website  --  r-ui          |
  +-----------------------------------------+

  API service  : active
  Main site    : https://resume.example.com
  Admin panel  : https://admin.example.com
  Admin user   : admin

  Main Menu

  [1]  Domain management
  [2]  Admin credentials  (username / password)
  [3]  Service management  (restart / logs)
  [0]  Exit
```

---

## 🏗️ Tech Stack

| Layer     | Technology                        |
|-----------|-----------------------------------|
| Backend   | ASP.NET Core 9 Web API (C#)       |
| Database  | SQLite + Entity Framework Core 9  |
| Auth      | JWT Bearer + BCrypt               |
| Frontend  | HTML / CSS / Vanilla JS           |
| Server    | nginx + systemd                   |
| SSL       | Let's Encrypt (Certbot)           |
| Platform  | Ubuntu 20.04+                     |

---

## 📁 Project Structure

```
├── Backend/
│   └── ResumeAPI/          # ASP.NET Core Web API
│       ├── Controllers/
│       ├── Models/
│       ├── Data/
│       └── Program.cs
├── Frontend/
│   ├── pages/              # Main site pages
│   ├── admin/              # Admin panel (login + dashboard)
│   ├── css/
│   ├── js/
│   └── assets/
├── install.sh              # One-command installer
└── r-ui.sh                 # Server management CLI
```

---

## 🔧 Useful Commands

```bash
# Management tool
r-ui

# Service
systemctl status resume-api
systemctl restart resume-api
journalctl -u resume-api -f

# SSL
certbot renew

# Nginx
nginx -t && systemctl reload nginx
```

---

## 👤 Author

**Abolfazl Tafakori** — [github.com/AbolfazlTafakori](https://github.com/AbolfazlTafakori)
