/* ============================================
   ADMIN DASHBOARD JS
   ============================================ */

// API_BASE is defined in config.js
const API = API_BASE;

function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

function safeUrl(url) {
    if (!url) return '#';
    try {
        const p = new URL(url);
        return ['http:', 'https:', 'mailto:'].includes(p.protocol) ? url : '#';
    } catch { return '#'; }
}

// ---- PRESET SKILL ICONS ----
// To add more: drop PNG files into Frontend/assets/images/HomePage/ and add an entry here
const PRESET_ICONS = [
    { name: 'C#',      file: 'csharp.png'   },
    { name: '.NET',    file: 'Dot-NET.png'  },
    { name: 'SQL',     file: 'SQL.png'      },
    { name: 'Docker',  file: 'Docker.png'   },
    { name: 'Git',     file: 'Git.png'      },
    { name: 'GitHub',  file: 'GitHub.png'   },
    { name: 'HTML',    file: 'HTML.png'     },
    { name: 'CSS',     file: 'CSS.png'      },
];
const PRESET_PREFIX = 'preset:';
const PRESET_BASE   = '../assets/images/HomePage/';

function skillIconUrl(iconPath) {
    if (!iconPath) return '';
    if (iconPath.startsWith(PRESET_PREFIX))
        return PRESET_BASE + iconPath.slice(PRESET_PREFIX.length);
    return `${API}/uploads/${iconPath}`;
}

function buildIconPicker(currentIcon) {
    const picker = document.getElementById('icon-picker');
    picker.innerHTML = PRESET_ICONS.map(ic => {
        const key = PRESET_PREFIX + ic.file;
        const sel = currentIcon === key ? 'selected' : '';
        return `<div class="icon-pick-item ${sel}" data-key="${key}" onclick="selectPresetIcon('${key}')">
            <img src="${PRESET_BASE}${ic.file}" alt="${ic.name}">
            <span>${ic.name}</span>
        </div>`;
    }).join('');
}

function selectPresetIcon(key) {
    document.getElementById('skill-selected-icon').value = key;
    // highlight
    document.querySelectorAll('#icon-picker .icon-pick-item').forEach(el => {
        el.classList.toggle('selected', el.dataset.key === key);
    });
    // clear custom upload preview
    document.getElementById('preview-skill-icon').style.display = 'none';
    document.getElementById('file-skill-icon').value = '';
}

function authHeaders() {
    return {
        'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
        'Content-Type': 'application/json'
    };
}

// Auth guard
if (!localStorage.getItem('admin_token')) {
    window.location.href = 'login.html';
}

document.getElementById('logout-btn').addEventListener('click', () => {
    localStorage.removeItem('admin_token');
    window.location.href = 'login.html';
});

// ---- NAV TABS ----
function activateSection(section) {
    document.querySelectorAll('.sidebar-nav a[data-section]').forEach(l => l.classList.remove('active'));
    const link = document.querySelector(`.sidebar-nav a[data-section="${section}"]`);
    if (link) link.classList.add('active');
    document.querySelectorAll('.section-view').forEach(v => v.style.display = 'none');
    const view = document.getElementById(`section-${section}`);
    if (view) view.style.display = 'block';
}

document.querySelectorAll('.sidebar-nav a[data-section]').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        activateSection(link.dataset.section);
    });
});

// ---- MODAL HELPERS ----
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
document.querySelectorAll('.modal-overlay').forEach(m => {
    m.addEventListener('click', e => { if (e.target === m) m.classList.remove('open'); });
});

// ---- CONFIRM DIALOG (replaces browser confirm()) ----
function confirmDelete(title, message, onConfirm) {
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-msg').textContent   = message || 'This action cannot be undone.';
    openModal('modal-confirm');
    const btn = document.getElementById('confirm-ok-btn');
    const handler = () => {
        closeModal('modal-confirm');
        btn.removeEventListener('click', handler);
        onConfirm();
    };
    btn.removeEventListener('click', handler);
    btn.addEventListener('click', handler);
}

// ---- UPLOAD HELPER ----
async function uploadFile(fileInput, previewEl) {
    const file = fileInput.files[0];
    if (!file) return null;
    const reader = new FileReader();
    reader.onload = e => { previewEl.src = e.target.result; };
    reader.readAsDataURL(file);

    const form = new FormData();
    form.append('file', file);

    // NOTE: do NOT swallow errors here. A failed upload must surface so the
    // caller can stop and show the real reason instead of silently saving null.
    const res = await fetch(`${API}/upload`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${localStorage.getItem('admin_token')}` },
        body: form
    });
    if (res.status === 401) {
        localStorage.removeItem('admin_token');
        window.location.href = 'login.html';
        throw new Error('Session expired — please log in again');
    }
    if (!res.ok) {
        let detail = '';
        try { detail = await res.text(); } catch {}
        throw new Error(`Image upload failed (HTTP ${res.status})${detail ? ': ' + detail : ''}`);
    }
    const data = await res.json();
    if (!data || !data.filename) throw new Error('Upload returned no filename');
    return data.filename;
}

// Preview on file select
function bindPreview(inputId, previewId) {
    document.getElementById(inputId).addEventListener('change', function() {
        const file = this.files[0];
        if (file) {
            const r = new FileReader();
            r.onload = e => document.getElementById(previewId).src = e.target.result;
            r.readAsDataURL(file);
        }
    });
}

// Avatar inputs: upload AND save immediately when a file is chosen.
// No separate "Save" step — picking the image is the whole action.
function bindAvatarAutoSave(inputId, previewId, field) {
    document.getElementById(inputId).addEventListener('change', async function() {
        const file = this.files[0];
        if (!file) return;

        // instant local preview
        const r = new FileReader();
        r.onload = e => document.getElementById(previewId).src = e.target.result;
        r.readAsDataURL(file);

        try {
            const filename = await uploadFile(this, document.getElementById(previewId));
            const res = await fetch(`${API}/profile`, {
                method: 'PUT',
                headers: authHeaders(),
                body: JSON.stringify({ [field]: filename })
            });
            if (res.status === 401) {
                localStorage.removeItem('admin_token');
                window.location.href = 'login.html';
                return;
            }
            if (!res.ok) {
                let detail = ''; try { detail = await res.text(); } catch {}
                throw new Error(`HTTP ${res.status}${detail ? ': ' + detail : ''}`);
            }
            showToast('Image uploaded and saved!');
            this.value = ''; // clear so the main Save won't re-upload it
        } catch (e) {
            showToast('Upload failed: ' + e.message, true);
        }
    });
}

bindAvatarAutoSave('file-home-avatar',    'preview-home-avatar',    'homeAvatar');
bindAvatarAutoSave('file-about-avatar',   'preview-about-avatar',   'aboutAvatar');
bindAvatarAutoSave('file-contact-avatar', 'preview-contact-avatar', 'contactAvatar');
bindPreview('file-skill-icon', 'preview-skill-icon');
bindPreview('file-project-img', 'preview-project-img');

// ---- LOAD ALL DATA ----
async function loadAll() {
    await Promise.all([loadProfile(), loadSkills(), loadProjects(), loadEducation(), loadExperience(), loadSocials(), loadTexts()]);
}

// ---- SITE TEXTS ----
const TEXT_FIELDS = [
    'navLogo','navHome','navAbout','navPortfolio','navContact',
    'homeSkillsTitle',
    'aboutPageTitle','aboutEducationHeader','aboutExperienceHeader',
    'portfolioPageTitle',
    'contactPageTitle'
];

const TEXT_DEFAULTS = {
    navLogo:                 'Mrnobudi',
    navHome:                 'Home',
    navAbout:                'About',
    navPortfolio:            'Portfolio',
    navContact:              "Let's talk",
    homeSkillsTitle:         'My Skills',
    aboutPageTitle:          'About me',
    aboutEducationHeader:    'Education',
    aboutExperienceHeader:   'Experience',
    portfolioPageTitle:      'Portfolio',
    contactPageTitle:        'Contact',
};

async function loadTexts() {
    try {
        const res = await fetch(`${API}/sitetexts`, { headers: authHeaders() });
        const t = await res.json();
        TEXT_FIELDS.forEach(k => {
            const el = document.getElementById(`txt-${k}`);
            if (el) el.value = t[k] || TEXT_DEFAULTS[k] || '';
        });
    } catch {}
}

async function saveTexts() {
    const body = {};
    TEXT_FIELDS.forEach(k => {
        const el = document.getElementById(`txt-${k}`);
        body[k] = el ? el.value : '';
    });
    try {
        await fetch(`${API}/sitetexts`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
        showToast('Texts saved!');
    } catch { showToast('Error saving texts', true); }
}

// ---- PROFILE ----
function setColor(pickerId, hexId, value) {
    const v = value || '#5b8dee';
    const el = document.getElementById(pickerId);
    const hexEl = document.getElementById(hexId);
    if (el)    el.value    = v === 'none' ? '#000000' : v;
    if (hexEl) hexEl.value = v;
}

async function loadProfile() {
    try {
        const res = await fetch(`${API}/profile`, { headers: authHeaders() });
        const p = await res.json();
        document.getElementById('heroTitle').value        = p.heroTitle    || 'Backend web developer !';
        document.getElementById('heroSubtitle').value     = p.heroSubtitle || "Hi, I'm Mrnobudi, passionate Back end Web Developer From IRAN";
        document.getElementById('profileName').value      = p.name         || 'Mrnobudi';
        document.getElementById('profileTitle').value     = p.title        || 'Back-end Developer';
        document.getElementById('profileLocation').value  = p.location     || '';
        document.getElementById('profileBio').value       = p.bio          || 'Chief Technology Officer with experience in leading innovative teams and implementing scalable solutions.';
        document.getElementById('preview-home-avatar').src    = p.homeAvatar    ? `${API}/uploads/${p.homeAvatar}`    : '../assets/images/HomePage/Logo.png';
        document.getElementById('preview-about-avatar').src   = p.aboutAvatar   ? `${API}/uploads/${p.aboutAvatar}`   : '../assets/images/AboutMe/Logo.png';
        document.getElementById('preview-contact-avatar').src = p.contactAvatar ? `${API}/uploads/${p.contactAvatar}` : '../assets/images/Contact/Logo.png';
        setColor('homeAvatarBorderColor',    'homeAvatarBorderColorHex',    p.homeAvatarBorderColor);
        setColor('aboutAvatarBorderColor',   'aboutAvatarBorderColorHex',   p.aboutAvatarBorderColor);
        setColor('contactAvatarBorderColor', 'contactAvatarBorderColorHex', p.contactAvatarBorderColor || '#c9960a');
    } catch {}
}

async function saveProfile() {
    const homeFile    = document.getElementById('file-home-avatar');
    const aboutFile   = document.getElementById('file-about-avatar');
    const contactFile = document.getElementById('file-contact-avatar');

    const [homeAvatar, aboutAvatar, contactAvatar] = await Promise.all([
        homeFile.files[0]    ? uploadFile(homeFile,    document.getElementById('preview-home-avatar'))    : Promise.resolve(null),
        aboutFile.files[0]   ? uploadFile(aboutFile,   document.getElementById('preview-about-avatar'))   : Promise.resolve(null),
        contactFile.files[0] ? uploadFile(contactFile, document.getElementById('preview-contact-avatar')) : Promise.resolve(null)
    ]);

    const body = {
        heroTitle:      document.getElementById('heroTitle').value,
        heroSubtitle:   document.getElementById('heroSubtitle').value,
        name:           document.getElementById('profileName').value,
        title:          document.getElementById('profileTitle').value,
        location:       document.getElementById('profileLocation').value,
        bio:            document.getElementById('profileBio').value,
        homeAvatarBorderColor:    document.getElementById('homeAvatarBorderColorHex').value.trim()    || '#5b8dee',
        aboutAvatarBorderColor:   document.getElementById('aboutAvatarBorderColorHex').value.trim()   || '#5b8dee',
        contactAvatarBorderColor: document.getElementById('contactAvatarBorderColorHex').value.trim() || '#5b8dee',
    };
    if (homeAvatar)    body.homeAvatar    = homeAvatar;
    if (aboutAvatar)   body.aboutAvatar   = aboutAvatar;
    if (contactAvatar) body.contactAvatar = contactAvatar;

    const res = await fetch(`${API}/profile`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
    if (res.status === 401) {
        localStorage.removeItem('admin_token');
        window.location.href = 'login.html';
        throw new Error('Session expired — please log in again');
    }
    if (!res.ok) {
        let detail = '';
        try { detail = await res.text(); } catch {}
        throw new Error(`Profile save failed (HTTP ${res.status})${detail ? ': ' + detail : ''}`);
    }

    // Clear the file inputs so a re-save doesn't re-upload the same images
    document.getElementById('file-home-avatar').value    = '';
    document.getElementById('file-about-avatar').value   = '';
    document.getElementById('file-contact-avatar').value = '';
}

// ---- SKILLS ----
let skills = [];

async function loadSkills() {
    try {
        const res = await fetch(`${API}/skills`, { headers: authHeaders() });
        skills = await res.json();
        renderSkills();
    } catch {}
}

function renderSkills() {
    document.getElementById('skills-list').innerHTML = skills.map(s => `
        <div class="item-row" data-id="${s.id}">
            <img class="item-icon" src="${escapeHtml(skillIconUrl(s.iconPath))}" alt="${escapeHtml(s.name)}"
                 style="background:var(--surface2);border-radius:8px;object-fit:contain;">
            <span class="item-name">${escapeHtml(s.name)}</span>
            <div class="item-actions">
                <button class="btn-icon" onclick="editSkill(${s.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="btn-icon danger" onclick="deleteSkill(${s.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
            </div>
        </div>
    `).join('');
}

document.getElementById('add-skill-btn').addEventListener('click', () => {
    document.getElementById('modal-skill-title').textContent = 'Add Skill';
    document.getElementById('skill-edit-id').value = '';
    document.getElementById('skill-name').value = '';
    document.getElementById('skill-selected-icon').value = '';
    document.getElementById('preview-skill-icon').style.display = 'none';
    document.getElementById('file-skill-icon').value = '';
    buildIconPicker('');
    openModal('modal-skill');
});

function editSkill(id) {
    const s = skills.find(x => x.id === id);
    document.getElementById('modal-skill-title').textContent = 'Edit Skill';
    document.getElementById('skill-edit-id').value = id;
    document.getElementById('skill-name').value = s.name;
    document.getElementById('skill-selected-icon').value = s.iconPath || '';
    // show custom preview only if uploaded (not preset)
    const previewEl = document.getElementById('preview-skill-icon');
    if (s.iconPath && !s.iconPath.startsWith(PRESET_PREFIX)) {
        previewEl.src = skillIconUrl(s.iconPath);
        previewEl.style.display = 'block';
    } else {
        previewEl.style.display = 'none';
    }
    buildIconPicker(s.iconPath || '');
    openModal('modal-skill');
}

// when custom file selected, clear preset selection
document.getElementById('file-skill-icon').addEventListener('change', function() {
    if (this.files[0]) {
        document.getElementById('skill-selected-icon').value = '';
        document.querySelectorAll('#icon-picker .icon-pick-item').forEach(el => el.classList.remove('selected'));
        const previewEl = document.getElementById('preview-skill-icon');
        const r = new FileReader();
        r.onload = e => { previewEl.src = e.target.result; previewEl.style.display = 'block'; };
        r.readAsDataURL(this.files[0]);
    }
});

document.getElementById('skill-save-btn').addEventListener('click', async () => {
    const id = document.getElementById('skill-edit-id').value;
    const presetKey = document.getElementById('skill-selected-icon').value;
    const iconFile  = document.getElementById('file-skill-icon');
    const body = { name: document.getElementById('skill-name').value };

    if (presetKey) {
        body.iconPath = presetKey;
    } else if (iconFile.files[0]) {
        body.iconPath = await uploadFile(iconFile, document.getElementById('preview-skill-icon'));
    }

    if (id) {
        await fetch(`${API}/skills/${id}`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
    } else {
        await fetch(`${API}/skills`, { method: 'POST', headers: authHeaders(), body: JSON.stringify(body) });
    }
    closeModal('modal-skill');
    await loadSkills();
    showToast('Skill saved!');
});

function deleteSkill(id) {
    const s = skills.find(x => x.id === id);
    confirmDelete(`Delete "${s?.name}"?`, 'This skill will be removed from your website.', async () => {
        await fetch(`${API}/skills/${id}`, { method: 'DELETE', headers: authHeaders() });
        await loadSkills();
        showToast('Skill deleted.');
    });
}

// ---- PROJECTS ----
let projects = [];

async function loadProjects() {
    try {
        const res = await fetch(`${API}/projects`, { headers: authHeaders() });
        projects = await res.json();
        renderProjects();
    } catch {}
}

function renderProjects() {
    document.getElementById('projects-list').innerHTML = projects.map(p => `
        <div class="item-row" data-id="${p.id}">
            <span class="item-name">${escapeHtml(p.name)}</span>
            <span class="item-sub">${escapeHtml(p.viewUrl || '')}</span>
            <div class="item-actions">
                <button class="btn-icon" onclick="editProject(${p.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="btn-icon danger" onclick="deleteProject(${p.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
            </div>
        </div>
    `).join('');
}

document.getElementById('add-project-btn').addEventListener('click', () => {
    document.getElementById('modal-project-title').textContent = 'Add Project';
    document.getElementById('project-edit-id').value = '';
    document.getElementById('project-name').value = '';
    document.getElementById('project-overview').value = '';
    document.getElementById('project-view').value = '';
    document.getElementById('project-github').value = '';
    document.getElementById('preview-project-img').src = '';
    openModal('modal-project');
});

function editProject(id) {
    const p = projects.find(x => x.id === id);
    document.getElementById('modal-project-title').textContent = 'Edit Project';
    document.getElementById('project-edit-id').value = id;
    document.getElementById('project-name').value = p.name;
    document.getElementById('project-overview').value = p.overview || '';
    document.getElementById('project-view').value = p.viewUrl || '';
    document.getElementById('project-github').value = p.githubUrl || '';
    document.getElementById('preview-project-img').src = p.imagePath ? `${API}/uploads/${p.imagePath}` : '';
    openModal('modal-project');
}

document.getElementById('project-save-btn').addEventListener('click', async () => {
    const nameVal = document.getElementById('project-name').value.trim();
    if (!nameVal) { showToast('Project name is required.', true); return; }

    const saveBtn = document.getElementById('project-save-btn');
    saveBtn.disabled = true;
    saveBtn.textContent = 'Saving...';

    try {
        const id = document.getElementById('project-edit-id').value;
        const imgFile = document.getElementById('file-project-img');
        let imagePath = null;
        if (imgFile.files[0]) {
            imagePath = await uploadFile(imgFile, document.getElementById('preview-project-img'));
        }
        const body = {
            name:      nameVal,
            overview:  document.getElementById('project-overview').value,
            viewUrl:   document.getElementById('project-view').value,
            githubUrl: document.getElementById('project-github').value,
        };
        if (imagePath) body.imagePath = imagePath;

        const url    = id ? `${API}/projects/${id}` : `${API}/projects`;
        const method = id ? 'PUT' : 'POST';
        const res = await fetch(url, { method, headers: authHeaders(), body: JSON.stringify(body) });

        if (!res.ok) {
            const txt = await res.text().catch(() => res.status);
            showToast(`Save failed (${res.status}): ${txt}`, true);
            return;
        }

        closeModal('modal-project');
        await loadProjects();
        showToast('Project saved!');
    } catch (e) {
        showToast('Save failed: ' + e.message, true);
    } finally {
        saveBtn.disabled = false;
        saveBtn.textContent = 'Save';
    }
});

function deleteProject(id) {
    const p = projects.find(x => x.id === id);
    confirmDelete(`Delete "${p?.name}"?`, 'This project will be removed from your portfolio.', async () => {
        await fetch(`${API}/projects/${id}`, { method: 'DELETE', headers: authHeaders() });
        await loadProjects();
        showToast('Project deleted.');
    });
}

// ---- EDUCATION ----
let educations = [];

async function loadEducation() {
    try {
        const res = await fetch(`${API}/education`, { headers: authHeaders() });
        educations = await res.json();
        renderEducation();
    } catch {}
}

function renderEducation() {
    document.getElementById('edu-list').innerHTML = educations.map(e => `
        <div class="item-row" data-id="${e.id}">
            <div style="flex:1">
                <div class="item-name">${escapeHtml(e.period)}</div>
                <div class="item-sub">${escapeHtml(e.description)}</div>
            </div>
            <div class="item-actions">
                <button class="btn-icon" onclick="editEdu(${e.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="btn-icon danger" onclick="deleteEdu(${e.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
            </div>
        </div>
    `).join('');
}

document.getElementById('add-edu-btn').addEventListener('click', () => {
    document.getElementById('modal-edu-title').textContent = 'Add Education';
    document.getElementById('edu-edit-id').value = '';
    document.getElementById('edu-period').value = '';
    document.getElementById('edu-desc').value = '';
    openModal('modal-edu');
});

function editEdu(id) {
    const e = educations.find(x => x.id === id);
    document.getElementById('modal-edu-title').textContent = 'Edit Education';
    document.getElementById('edu-edit-id').value = id;
    document.getElementById('edu-period').value = e.period;
    document.getElementById('edu-desc').value = e.description;
    openModal('modal-edu');
}

document.getElementById('edu-save-btn').addEventListener('click', async () => {
    const id = document.getElementById('edu-edit-id').value;
    const body = {
        period: document.getElementById('edu-period').value,
        description: document.getElementById('edu-desc').value
    };
    if (id) {
        await fetch(`${API}/education/${id}`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
    } else {
        await fetch(`${API}/education`, { method: 'POST', headers: authHeaders(), body: JSON.stringify(body) });
    }
    closeModal('modal-edu');
    await loadEducation();
    showToast('Education saved!');
});

function deleteEdu(id) {
    const e = educations.find(x => x.id === id);
    confirmDelete(`Delete "${e?.period}"?`, 'This education entry will be removed.', async () => {
        await fetch(`${API}/education/${id}`, { method: 'DELETE', headers: authHeaders() });
        await loadEducation();
        showToast('Education entry deleted.');
    });
}

// ---- EXPERIENCE ----
let experiences = [];

async function loadExperience() {
    try {
        const res = await fetch(`${API}/experience`, { headers: authHeaders() });
        experiences = await res.json();
        renderExperience();
    } catch {}
}

function renderExperience() {
    document.getElementById('exp-list').innerHTML = experiences.map(e => `
        <div class="item-row" data-id="${e.id}">
            <div style="flex:1">
                <div class="item-name">${escapeHtml(e.company)}</div>
                <div class="item-sub">${escapeHtml(e.role)} · ${escapeHtml(e.period)}</div>
            </div>
            <div class="item-actions">
                <button class="btn-icon" onclick="editExp(${e.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="btn-icon danger" onclick="deleteExp(${e.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
            </div>
        </div>
    `).join('');
}

document.getElementById('add-exp-btn').addEventListener('click', () => {
    document.getElementById('modal-exp-title').textContent = 'Add Experience';
    document.getElementById('exp-edit-id').value = '';
    document.getElementById('exp-company').value = '';
    document.getElementById('exp-role').value = '';
    document.getElementById('exp-period').value = '';
    document.getElementById('exp-bullets').value = '';
    openModal('modal-exp');
});

function editExp(id) {
    const e = experiences.find(x => x.id === id);
    document.getElementById('modal-exp-title').textContent = 'Edit Experience';
    document.getElementById('exp-edit-id').value = id;
    document.getElementById('exp-company').value = e.company;
    document.getElementById('exp-role').value = e.role;
    document.getElementById('exp-period').value = e.period;
    document.getElementById('exp-bullets').value = (e.bullets || []).join('\n');
    openModal('modal-exp');
}

document.getElementById('exp-save-btn').addEventListener('click', async () => {
    const id = document.getElementById('exp-edit-id').value;
    const body = {
        company: document.getElementById('exp-company').value,
        role:    document.getElementById('exp-role').value,
        period:  document.getElementById('exp-period').value,
        bullets: document.getElementById('exp-bullets').value.split('\n').map(b => b.trim()).filter(Boolean)
    };
    if (id) {
        await fetch(`${API}/experience/${id}`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
    } else {
        await fetch(`${API}/experience`, { method: 'POST', headers: authHeaders(), body: JSON.stringify(body) });
    }
    closeModal('modal-exp');
    await loadExperience();
    showToast('Experience saved!');
});

function deleteExp(id) {
    const e = experiences.find(x => x.id === id);
    confirmDelete(`Delete "${e?.company}"?`, 'This experience entry will be removed.', async () => {
        await fetch(`${API}/experience/${id}`, { method: 'DELETE', headers: authHeaders() });
        await loadExperience();
        showToast('Experience entry deleted.');
    });
}

// ---- SOCIALS ----
const SOCIAL_PRESETS = ['LinkedIn','Email','GitHub','Telegram'];
let socials = [];

function socialIconUrl(iconPath) {
    if (!iconPath) return '';
    if (iconPath.startsWith('preset:')) {
        const name = iconPath.replace('preset:', '');
        return `../assets/images/Contact/${name}.png`;
    }
    return `${API}/uploads/${iconPath}`;
}

async function loadSocials() {
    try {
        const res = await fetch(`${API}/socials`, { headers: authHeaders() });
        socials = await res.json();
        renderSocials();
    } catch {}
}

function renderSocials() {
    const el = document.getElementById('socials-list');
    if (!el) return;
    el.innerHTML = socials.map(s => `
        <div class="item-row" data-id="${s.id}">
            <img class="item-icon" src="${escapeHtml(socialIconUrl(s.iconPath))}" alt="${escapeHtml(s.name)}"
                 style="background:var(--surface2);border-radius:8px;object-fit:contain;">
            <div style="flex:1">
                <div class="item-name">${escapeHtml(s.name)}</div>
                <div class="item-sub">${escapeHtml(s.url || '')}</div>
            </div>
            <div class="item-actions">
                <button class="btn-icon" onclick="editSocial(${s.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="btn-icon danger" onclick="deleteSocial(${s.id})">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                </button>
            </div>
        </div>
    `).join('');
}

function buildSocialIconPicker(selected) {
    const picker = document.getElementById('social-icon-picker');
    if (!picker) return;
    picker.innerHTML = SOCIAL_PRESETS.map(name => `
        <div class="icon-pick-item ${selected === 'preset:'+name ? 'selected' : ''}"
             onclick="selectSocialIcon('preset:${name}', this)"
             title="${name}" style="cursor:pointer;padding:6px;border-radius:8px;border:2px solid transparent;
             background:var(--surface2);transition:border-color 0.2s;">
            <img src="../assets/images/Contact/${name}.png"
                 style="width:48px;height:48px;object-fit:contain;display:block;">
        </div>
    `).join('');
}

function selectSocialIcon(key, el) {
    document.getElementById('social-selected-icon').value = key;
    document.querySelectorAll('#social-icon-picker .icon-pick-item').forEach(e => e.style.borderColor = 'transparent');
    el.style.borderColor = 'var(--accent)';
}

document.getElementById('add-social-btn').addEventListener('click', () => {
    document.getElementById('modal-social-title').textContent = 'Add Social Link';
    document.getElementById('social-edit-id').value = '';
    document.getElementById('social-name').value = '';
    document.getElementById('social-url').value = '';
    document.getElementById('social-selected-icon').value = '';
    document.getElementById('preview-social-icon').style.display = 'none';
    buildSocialIconPicker('');
    openModal('modal-social');
});

function editSocial(id) {
    const s = socials.find(x => x.id === id);
    document.getElementById('modal-social-title').textContent = 'Edit Social Link';
    document.getElementById('social-edit-id').value = id;
    document.getElementById('social-name').value = s.name;
    document.getElementById('social-url').value = s.url || '';
    document.getElementById('social-selected-icon').value = s.iconPath || '';
    const previewEl = document.getElementById('preview-social-icon');
    if (s.iconPath && !s.iconPath.startsWith('preset:')) {
        previewEl.src = `${API}/uploads/${s.iconPath}`;
        previewEl.style.display = 'block';
    } else {
        previewEl.style.display = 'none';
    }
    buildSocialIconPicker(s.iconPath || '');
    openModal('modal-social');
}

document.getElementById('file-social-icon').addEventListener('change', function() {
    if (this.files[0]) {
        document.getElementById('social-selected-icon').value = '';
        document.querySelectorAll('#social-icon-picker .icon-pick-item').forEach(e => e.style.borderColor='transparent');
        const r = new FileReader();
        const prev = document.getElementById('preview-social-icon');
        r.onload = e => { prev.src = e.target.result; prev.style.display = 'block'; };
        r.readAsDataURL(this.files[0]);
    }
});

document.getElementById('social-save-btn').addEventListener('click', async () => {
    const id = document.getElementById('social-edit-id').value;
    const presetKey  = document.getElementById('social-selected-icon').value;
    const iconFile   = document.getElementById('file-social-icon');
    let iconPath = presetKey;
    if (!presetKey && iconFile.files[0]) {
        iconPath = await uploadFile(iconFile, document.getElementById('preview-social-icon'));
    }
    const body = {
        name:     document.getElementById('social-name').value,
        iconPath: iconPath || '',
        url:      document.getElementById('social-url').value,
    };
    if (id) {
        await fetch(`${API}/socials/${id}`, { method: 'PUT', headers: authHeaders(), body: JSON.stringify(body) });
    } else {
        await fetch(`${API}/socials`, { method: 'POST', headers: authHeaders(), body: JSON.stringify(body) });
    }
    closeModal('modal-social');
    await loadSocials();
    showToast('Social link saved!');
});

function deleteSocial(id) {
    const s = socials.find(x => x.id === id);
    confirmDelete(`Delete "${s?.name}"?`, 'This social link will be removed from your contact page.', async () => {
        await fetch(`${API}/socials/${id}`, { method: 'DELETE', headers: authHeaders() });
        await loadSocials();
        showToast('Social link deleted.');
    });
}

// ---- CHANGE PASSWORD ----
async function savePassword() {
    const cur = document.getElementById('pwd-current').value;
    const nw  = document.getElementById('pwd-new').value;
    const cnf = document.getElementById('pwd-confirm').value;
    if (!cur || !nw) { showToast('All password fields are required.', true); return; }
    if (nw.length < 8) { showToast('New password must be at least 8 characters.', true); return; }
    if (nw !== cnf) { showToast('Passwords do not match.', true); return; }
    try {
        const res = await fetch(`${API}/auth/change-password`, {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ currentPassword: cur, newPassword: nw })
        });
        if (res.ok) {
            showToast('Password changed successfully!');
            document.getElementById('pwd-current').value = '';
            document.getElementById('pwd-new').value = '';
            document.getElementById('pwd-confirm').value = '';
        } else {
            showToast('Current password is incorrect.', true);
        }
    } catch { showToast('Failed to change password.', true); }
}

// ---- SAVE ALL ----
document.getElementById('save-btn').addEventListener('click', async () => {
    const btn = document.getElementById('save-btn');
    btn.textContent = 'Saving...';
    btn.disabled = true;

    try {
        const activeSection = document.querySelector('.sidebar-nav a.active')?.dataset?.section;
        const profileSections = ['home-hero', 'about-identity', 'contact-info'];
        if (profileSections.includes(activeSection)) await saveProfile();
        if (activeSection === 'socials')    await saveSocials();
        if (activeSection === 'password')   await savePassword();

        showToast('Saved successfully!');
    } catch (e) {
        alert('Save failed: ' + e.message);
    }

    btn.textContent = 'Save Changes';
    btn.disabled = false;
});

// ---- TOAST ----
function showToast(msg, isError = false) {
    const el = document.getElementById('save-msg');
    if (el) {
        el.textContent = msg;
        el.style.background = isError ? '#c0392b' : '';
        el.classList.add('visible');
        setTimeout(() => { el.classList.remove('visible'); el.style.background = ''; }, 2500);
    }
}

// ---- INIT ----
loadAll();
