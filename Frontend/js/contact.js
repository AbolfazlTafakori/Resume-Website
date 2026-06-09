document.addEventListener('DOMContentLoaded', async () => {
    document.getElementById('nav-toggle').addEventListener('click', function () {
        this.classList.toggle('open');
        document.getElementById('nav-links').classList.toggle('open');
    });

    applySiteTexts('contact');

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.name)          document.getElementById('contact-name').textContent     = profile.name;
        if (profile.title)         document.getElementById('contact-role').textContent     = profile.title;
        if (profile.location)      document.getElementById('contact-location').textContent = profile.location;
        if (profile.contactAvatar) document.getElementById('contact-avatar').src = `${API_BASE}/uploads/${profile.contactAvatar}`;
        const contactAvatarEl = document.querySelector('.profile-avatar');
        if (contactAvatarEl) {
            const color = profile.contactAvatarBorderColor || '#c9960a';
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
    const grid = document.getElementById('social-grid');
    if (socials && socials.length && grid) {
        grid.innerHTML = socials.map(s => {
            const iconSrc = s.iconPath && s.iconPath.startsWith('preset:')
                ? `../assets/images/Contact/${s.iconPath.replace('preset:','')}.png`
                : (s.iconPath ? `${API_BASE}/uploads/${s.iconPath}` : '');
            return `<a href="${s.url || '#'}" class="social-cell page-loaded" target="_blank" rel="noopener">
                <img src="${iconSrc}" alt="${s.name}">
            </a>`;
        }).join('');
    }
});
