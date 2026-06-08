document.addEventListener('DOMContentLoaded', async () => {
    const titleEl    = document.getElementById('hero-title');
    const subtitleEl = document.getElementById('hero-subtitle');
    const grid       = document.getElementById('skills-grid');

    const origTitle    = titleEl ? titleEl.innerHTML : '';
    const origSubtitle = subtitleEl ? subtitleEl.textContent : '';
    const origGrid     = grid ? grid.innerHTML : '';

    document.getElementById('nav-toggle').addEventListener('click', function () {
        this.classList.toggle('open');
        document.getElementById('nav-links').classList.toggle('open');
    });

    applySiteTexts('home');

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.heroTitle && titleEl)       titleEl.innerHTML      = profile.heroTitle;
        if (profile.heroSubtitle && subtitleEl) subtitleEl.textContent = profile.heroSubtitle;
        if (profile.homeAvatar)                 document.getElementById('hero-avatar').src = `${API_BASE}/uploads/${profile.homeAvatar}`;
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
    }
});
