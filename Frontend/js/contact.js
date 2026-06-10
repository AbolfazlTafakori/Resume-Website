/* ── Email popup ── */
let _emailAddr = '';
let _popupJustOpened = false;

function showEmailPopup(e, addr) {
    e.preventDefault();
    _emailAddr = addr;
    _popupJustOpened = true;

    const popup  = document.getElementById('email-popup');
    const copyBtn = document.getElementById('email-copy-btn');
    document.getElementById('email-popup-addr').textContent = addr;
    copyBtn.textContent = 'Copy Address';
    copyBtn.classList.remove('copied');

    const x = Math.min(e.clientX, window.innerWidth  - 260);
    const y = Math.min(e.clientY + 14, window.innerHeight - 120);
    popup.style.left = x + 'px';
    popup.style.top  = y + 'px';
    popup.classList.add('show');
}

function closeEmailPopup() {
    document.getElementById('email-popup').classList.remove('show');
}

function emailCopy() {
    if (!_emailAddr) return;
    navigator.clipboard.writeText(_emailAddr).then(() => {
        const btn = document.getElementById('email-copy-btn');
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(closeEmailPopup, 1000);
    });
}

function emailSend() {
    if (!_emailAddr) return;
    window.location.href = 'mailto:' + _emailAddr;
    closeEmailPopup();
}

document.addEventListener('click', function(e) {
    if (_popupJustOpened) { _popupJustOpened = false; return; }
    const popup = document.getElementById('email-popup');
    if (popup && !popup.contains(e.target)) closeEmailPopup();
});

document.addEventListener('DOMContentLoaded', async () => {
    const grid = document.getElementById('social-grid');

    /* ── Skeleton ── */
    if (grid) {
        grid.innerHTML = Array(4).fill(0).map(() =>
            `<div class="social-cell skeleton skeleton-block" style="height:72px;"></div>`
        ).join('');
    }

    applySiteTexts('contact');

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.name)          document.getElementById('contact-name').textContent     = profile.name;
        if (profile.title)         document.getElementById('contact-role').textContent     = profile.title;
        if (profile.location)      document.getElementById('contact-location').textContent = profile.location;
        if (profile.contactAvatar) swapAvatar(document.getElementById('contact-avatar'), `${API_BASE}/uploads/${profile.contactAvatar}`);
        const contactAvatarEl = document.querySelector('.profile-avatar');
        if (contactAvatarEl) {
            const color = safeColor(profile.contactAvatarBorderColor, '#c9960a');
            if (color === 'none' || color === 'transparent') {
                contactAvatarEl.style.border = 'none';
                contactAvatarEl.style.boxShadow = 'none';
            } else {
                contactAvatarEl.style.borderColor = color;
                contactAvatarEl.style.boxShadow = `0 0 0 6px ${color}30, 0 0 36px ${color}55`;
            }
        }
    }

    const socials = await apiFetch('/socials');
    if (socials && socials.length && grid) {
        grid.innerHTML = socials.map(s => {
            const iconSrc = s.iconPath && s.iconPath.startsWith('preset:')
                ? `../assets/images/Contact/${s.iconPath.replace('preset:','')}.png`
                : (s.iconPath ? `${API_BASE}/uploads/${s.iconPath}` : '');

            /* detect email links */
            const isEmail = s.url && (s.url.startsWith('mailto:') || s.url.includes('@'));
            const emailAddr = isEmail
                ? s.url.replace('mailto:', '').trim()
                : '';

            if (isEmail) {
                return `<a href="#" class="social-cell page-loaded"
                    onclick="showEmailPopup(event,'${escapeHtml(emailAddr)}')">
                    <img src="${escapeHtml(iconSrc)}" alt="${escapeHtml(s.name)}">
                </a>`;
            }

            return `<a href="${safeUrl(s.url)}" class="social-cell page-loaded" target="_blank" rel="noopener noreferrer">
                <img src="${escapeHtml(iconSrc)}" alt="${escapeHtml(s.name)}">
            </a>`;
        }).join('');
    } else if (grid) {
        grid.innerHTML = '';
    }

    if (window.revealScan) revealScan();
});

function swapAvatar(imgEl, newSrc) {
    if (!imgEl) return;
    imgEl.style.opacity = '0';
    const tmp = new Image();
    tmp.onload = () => { imgEl.src = newSrc; imgEl.style.opacity = '1'; };
    tmp.onerror = () => {};
    tmp.src = newSrc;
}
