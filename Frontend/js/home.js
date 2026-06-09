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

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.heroTitle && titleEl)       titleEl.innerHTML      = profile.heroTitle;
        if (profile.heroSubtitle && subtitleEl) subtitleEl.textContent = profile.heroSubtitle;

        const avatarEl = document.getElementById('hero-avatar');
        if (avatarEl && profile.homeAvatar) {
            swapAvatar(avatarEl, `${API_BASE}/uploads/${profile.homeAvatar}`);
        }

        const homeAvatarEl = document.querySelector('.hero-avatar img');
        if (homeAvatarEl) {
            const color = profile.homeAvatarBorderColor || '#5b8dee';
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

/* Load avatar — fade in when ready */
function swapAvatar(imgEl, newSrc) {
    if (!imgEl) return;
    imgEl.style.opacity = '0';
    const tmp = new Image();
    tmp.onload = () => {
        imgEl.src = newSrc;
        imgEl.style.opacity = '1';
    };
    tmp.onerror = () => { /* keep hidden if image fails */ };
    tmp.src = newSrc;
}
