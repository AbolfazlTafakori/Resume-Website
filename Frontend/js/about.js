document.addEventListener('DOMContentLoaded', async () => {
    const eduList = document.getElementById('edu-list');
    const expList = document.getElementById('exp-list');

    /* ── Skeletons ── */
    if (eduList) eduList.innerHTML = Array(2).fill(0).map(() =>
        `<li class="skeleton skeleton-block" style="height:52px;margin-bottom:10px;list-style:none;"></li>`
    ).join('');
    if (expList) expList.innerHTML = Array(2).fill(0).map(() =>
        `<div class="skeleton skeleton-block" style="height:90px;margin-bottom:12px;"></div>`
    ).join('');

    applySiteTexts('about');

    const profile = await apiFetch('/profile');
    if (profile) {
        if (profile.name)        document.getElementById('about-name').textContent  = profile.name;
        if (profile.title)       document.getElementById('about-role').textContent  = profile.title;
        if (profile.bio)         document.getElementById('about-desc').textContent  = profile.bio;
        if (profile.aboutAvatar) swapAvatar(document.getElementById('about-avatar'), `${API_BASE}/uploads/${profile.aboutAvatar}`);

        const avatarEl = document.querySelector('.profile-avatar');
        if (avatarEl) {
            const color = profile.aboutAvatarBorderColor || '#5b8dee';
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
        eduList.innerHTML = education.map(e => `
            <li class="page-loaded">
                <strong>${e.period}</strong>
                <span>${e.description}</span>
            </li>
        `).join('');
    } else if (eduList) {
        eduList.innerHTML = '';
    }

    const experience = await apiFetch('/experience');
    if (experience && experience.length) {
        expList.innerHTML = experience.map(e => `
            <div class="exp-item page-loaded">
                <div class="exp-company">${e.company}</div>
                <div class="exp-role-wrap"><div class="exp-role">${e.role} (${e.period})</div></div>
                <ul class="exp-bullets">
                    ${e.bullets.map(b => `<li>${b}</li>`).join('')}
                </ul>
            </div>
        `).join('');
    } else if (expList) {
        expList.innerHTML = '';
    }

    if (window.revealScan) revealScan();
});

function swapAvatar(imgEl, newSrc) {
    const tmp = new Image();
    tmp.onload = () => {
        imgEl.style.transition = 'opacity 0.3s ease';
        imgEl.style.opacity = '0';
        setTimeout(() => { imgEl.src = newSrc; imgEl.style.opacity = '1'; }, 150);
    };
    tmp.src = newSrc;
}
