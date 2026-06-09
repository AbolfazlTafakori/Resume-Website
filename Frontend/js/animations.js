/* =============================================
   Scroll Reveal — IntersectionObserver
   ============================================= */
(function () {
    'use strict';

    var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    function initReveal() {
        document.querySelectorAll('.reveal').forEach(function (el) {
            observer.observe(el);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initReveal);
    } else {
        initReveal();
    }

    /* Re-scan after dynamic content is injected */
    window.revealScan = function () {
        document.querySelectorAll('.reveal:not(.visible)').forEach(function (el) {
            observer.observe(el);
        });
    };
}());
