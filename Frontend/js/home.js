document.addEventListener('DOMContentLoaded', async () => {
    const titleEl    = document.getElementById('hero-title');
    const subtitleEl = document.getElementById('hero-subtitle');
    const grid       = document.getElementById('skills-grid');

    /* ── Skeleton for skills ── */
    if (grid) {
        grid.innerHTML = Array(6).fill(0).map(() =>
            `<div class="skill-cell skeleton skeleton-block" style="height:80px;"></div>`
        ).join('');
    }

    applySiteTexts('home');

    const DEFAULT_AVATAR = '../assets/images/HomePage/Logo.png';
    const profile = await apiFetch('/profile');

    // Always render an avatar. Even when the API is unreachable or the uploaded
    // file fails to load, swapAvatar falls back to the bundled default image —
    // so the hero is never left blank.
    const avatarEl = document.getElementById('hero-avatar');
    if (avatarEl) {
        const avatarSrc = (profile && profile.homeAvatar)
            ? `${API_BASE}/uploads/${profile.homeAvatar}`
            : DEFAULT_AVATAR;
        swapAvatar(avatarEl, avatarSrc, DEFAULT_AVATAR);
    }

    if (profile) {
        if (profile.heroTitle && titleEl)       titleEl.textContent    = profile.heroTitle;
        if (profile.heroSubtitle && subtitleEl) subtitleEl.textContent = profile.heroSubtitle;

        const homeAvatarEl = document.querySelector('.hero-avatar img');
        if (homeAvatarEl) {
            const color = safeColor(profile.homeAvatarBorderColor, '#5b8dee');
            if (color === 'none' || color === 'transparent') {
                homeAvatarEl.style.border = 'none';
                homeAvatarEl.style.boxShadow = 'none';
            } else {
                homeAvatarEl.style.borderColor = color;
                homeAvatarEl.style.boxShadow = `0 0 0 6px ${color}30, 0 0 36px ${color}55`;
            }
        }
    }

    const skills = await apiFetch('/skills');
    if (skills && skills.length && grid) {
        grid.innerHTML = skills.map(s => {
            const iconUrl = s.iconPath
                ? (s.iconPath.startsWith('preset:')
                    ? `../assets/images/HomePage/${s.iconPath.slice(7)}`
                    : `${API_BASE}/uploads/${s.iconPath}`)
                : '';
            return `<div class="skill-cell page-loaded">
                ${iconUrl ? `<img src="${iconUrl}" alt="${s.name}">` : ''}
                <span>${s.name}</span>
            </div>`;
        }).join('');
    } else if (grid) {
        grid.innerHTML = '';
    }

    if (window.revealScan) revealScan();
});

/* Load avatar — fade in when ready, fall back to default if it fails */
function swapAvatar(imgEl, newSrc, fallbackSrc) {
    if (!imgEl) return;
    imgEl.style.opacity = '0';
    const reveal = (src) => { imgEl.src = src; imgEl.style.opacity = '1'; };
    const tmp = new Image();
    tmp.onload = () => reveal(newSrc);
    tmp.onerror = () => {
        // Uploaded image missing/broken — show the bundled default instead of
        // leaving the avatar invisible.
        if (fallbackSrc && fallbackSrc !== newSrc) {
            const fb = new Image();
            fb.onload  = () => reveal(fallbackSrc);
            fb.onerror = () => {};
            fb.src = fallbackSrc;
        }
    };
    tmp.src = newSrc;
}
