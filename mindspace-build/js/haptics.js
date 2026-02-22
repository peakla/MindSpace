(function () {
  'use strict';

  const supportsVibrate = 'vibrate' in navigator;
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  const patterns = {
    light: [10],
    medium: [20],
    heavy: [30],
    success: [10, 50, 20],
    error: [30, 50, 30, 50, 30],
    select: [5]
  };

  function vibrate(type) {
    if (prefersReducedMotion.matches) return;
    if (!supportsVibrate) return;
    const pattern = patterns[type] || patterns.light;
    try {
      navigator.vibrate(pattern);
    } catch (e) {}
  }

  function tapAnimation(el) {
    if (!el || prefersReducedMotion.matches) return;
    el.classList.remove('haptic-tap');
    void el.offsetWidth;
    el.classList.add('haptic-tap');
  }

  function feedback(el, type) {
    vibrate(type || 'light');
    tapAnimation(el);
  }

  const interactiveSelectors = [
    'button',
    'a.btn',
    '.btn',
    '.cta-btn',
    '.nav-link',
    '.topbar__dot',
    '.mb-categoryCard',
    '.mb-articleCard',
    '.mb-filterChip',
    '.mb-stickyFilter__btn',
    '.mood-option',
    '.checkin-submit',
    '.achievement-card',
    '.community-like-btn',
    '.community-comment-btn',
    '.settings-toggle',
    '.toggle-switch',
    '.theme-option',
    'input[type="checkbox"]',
    'input[type="radio"]',
    '.tab-btn',
    '.accordion-header',
    '.dropdown-trigger',
    '.mobile-nav-toggle',
    '.hamburger',
    '[role="button"]',
    '[data-haptic]'
  ];

  function getHapticType(el) {
    if (el.hasAttribute('data-haptic')) {
      return el.getAttribute('data-haptic');
    }
    if (el.closest('.mood-option') || el.closest('.checkin-submit')) return 'medium';
    if (el.closest('.achievement-card')) return 'success';
    if (el.closest('.community-like-btn')) return 'light';
    if (el.closest('.get-help-btn') || el.closest('[data-translate="nav_crisis"]')) return 'heavy';
    return 'light';
  }

  function isInteractive(el) {
    for (let i = 0; i < interactiveSelectors.length; i++) {
      if (el.matches(interactiveSelectors[i])) return true;
    }
    return false;
  }

  function findInteractiveAncestor(el) {
    let current = el;
    let depth = 0;
    while (current && depth < 5) {
      if (isInteractive(current)) return current;
      current = current.parentElement;
      depth++;
    }
    return null;
  }

  document.addEventListener('pointerdown', function (e) {
    const target = findInteractiveAncestor(e.target);
    if (!target) return;
    const type = getHapticType(target);
    feedback(target, type);
  }, { passive: true });

  window.MindSpaceHaptics = {
    vibrate: vibrate,
    tap: tapAnimation,
    feedback: feedback
  };
})();
