document.addEventListener('DOMContentLoaded', async () => {
    document.getElementById('nav-toggle').addEventListener('click', function () {
        this.classList.toggle('open');
        document.getElementById('nav-links').classList.toggle('open');
    });

    applySiteTexts('about');

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.name)        document.getElementById('about-name').textContent  = profile.name;
        if (profile.title)       document.getElementById('about-role').textContent  = profile.title;
        if (profile.bio)         document.getElementById('about-desc').textContent  = profile.bio;
        if (profile.aboutAvatar) document.getElementById('about-avatar').src        = `${API_BASE}/uploads/${profile.aboutAvatar}`;

        const avatarEl = document.querySelector('.profile-avatar');
        if (avatarEl) {
            const color = profile.avatarBorderColor || '#5b8dee';
            if (color === 'none' || color === 'transparent') {
                avatarEl.style.border = 'none';
                avatarEl.style.boxShadow = 'none';
            } else {
                avatarEl.style.borderColor = color;
                avatarEl.style.boxShadow = `0 0 0 6px ${color}30, 0 0 36px ${color}55`;
            }
        }
    }

    const education = await apiFetch('/education');
    if (education && education.length) {
        document.getElementById('edu-list').innerHTML = education.map(e => `
            <li class="page-loaded">
                <strong>${e.period}</strong>
                <span>${e.description}</span>
            </li>
        `).join('');
    }

    const experience = await apiFetch('/experience');
    if (experience && experience.length) {
        document.getElementById('exp-list').innerHTML = experience.map(e => `
            <div class="exp-item page-loaded">
                <div class="exp-company">${e.company}</div>
                <div class="exp-role-wrap"><div class="exp-role">${e.role} (${e.period})</div></div>
                <ul class="exp-bullets">
                    ${e.bullets.map(b => `<li>${b}</li>`).join('')}
                </ul>
            </div>
        `).join('');
    }
});
