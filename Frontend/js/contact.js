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
