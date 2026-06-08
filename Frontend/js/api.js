/* ============================================
   API CLIENT — shared across all pages
   Change BASE_URL to your backend address
   ============================================ */

// API_BASE is defined in config.js (loaded before this file)

async function apiFetch(endpoint) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3000);
    try {
        const res = await fetch(`${API_BASE}${endpoint}`, { signal: controller.signal });
        clearTimeout(timer);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return await res.json();
    } catch (err) {
        clearTimeout(timer);
        console.warn(`[API] Could not reach ${endpoint}:`, err.message);
        return null;
    }
}

// Apply site-wide texts (nav + page-specific)
function applyText(id, value) {
    const el = document.getElementById(id);
    if (el && value) el.textContent = value;
}

async function applySiteTexts(pageKey) {
    const t = await apiFetch('/sitetexts');
    if (!t) return;
    // Nav
    applyText('nav-logo',      t.navLogo);
    applyText('nav-home',      t.navHome);
    applyText('nav-about',     t.navAbout);
    applyText('nav-portfolio', t.navPortfolio);
    applyText('nav-contact',   t.navContact);
    // Page-specific
    if (pageKey === 'home') {
        applyText('skills-title', t.homeSkillsTitle);
    }
    if (pageKey === 'about') {
        applyText('page-title',          t.aboutPageTitle);
        applyText('edu-header',          t.aboutEducationHeader);
        applyText('exp-header',          t.aboutExperienceHeader);
    }
    if (pageKey === 'portfolio') {
        applyText('page-title', t.portfolioPageTitle);
    }
    if (pageKey === 'contact') {
        applyText('page-title', t.contactPageTitle);
    }
}
