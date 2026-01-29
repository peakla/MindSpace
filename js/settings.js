(function() {
  'use strict';

  const STORAGE_KEYS = {
    theme: 'mindbalance_theme',
    fontSize: 'mindbalance_font_size',
    reduceMotion: 'mindbalance_reduce_motion',
    highContrast: 'mindbalance_high_contrast',
    colorblind: 'mindbalance_colorblind',
    adhdMode: 'mindbalance_adhd_mode',
    dyslexiaFont: 'mindbalance_dyslexia_font'
  };

  function getPreference(key, defaultValue) {
    try {
      const value = localStorage.getItem(key);
      return value !== null ? value : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  function setPreference(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch (e) {
      console.warn('Could not save preference:', key);
    }
  }

  function getSystemThemePreference() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    return 'light';
  }

  function applyTheme(theme) {
    const effectiveTheme = theme === 'system' ? getSystemThemePreference() : theme;
    
    if (effectiveTheme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }

    document.querySelectorAll('[data-theme-toggle]').forEach(toggle => {
      toggle.checked = effectiveTheme === 'dark';
    });
  }

  function applyFontSize(size) {
    document.documentElement.setAttribute('data-font-size', size);
    
    document.querySelectorAll('select[data-font-size-select]').forEach(select => {
      select.value = size;
    });
  }

  function applyReduceMotion(enabled) {
    if (enabled === 'true' || enabled === true) {
      document.documentElement.setAttribute('data-reduce-motion', 'true');
    } else {
      document.documentElement.removeAttribute('data-reduce-motion');
    }

    document.querySelectorAll('[data-reduce-motion-toggle]').forEach(toggle => {
      if (toggle.tagName === 'INPUT') {
        toggle.checked = enabled === 'true' || enabled === true;
      }
    });
  }

  function applyHighContrast(enabled) {
    if (enabled === 'true' || enabled === true) {
      document.documentElement.setAttribute('data-high-contrast', 'true');
    } else {
      document.documentElement.removeAttribute('data-high-contrast');
    }

    document.querySelectorAll('[data-high-contrast-toggle]').forEach(toggle => {
      if (toggle.tagName === 'INPUT') {
        toggle.checked = enabled === 'true' || enabled === true;
      }
    });
  }

  function applyColorblind(mode) {
    if (mode && mode !== 'none') {
      document.documentElement.setAttribute('data-colorblind', mode);
    } else {
      document.documentElement.removeAttribute('data-colorblind');
    }

    document.querySelectorAll('select[data-colorblind-select]').forEach(select => {
      select.value = mode || 'none';
    });
  }

  function applyAdhdMode(enabled) {
    if (enabled === 'true' || enabled === true) {
      document.documentElement.setAttribute('data-adhd-mode', 'true');
    } else {
      document.documentElement.removeAttribute('data-adhd-mode');
    }

    document.querySelectorAll('[data-adhd-toggle]').forEach(toggle => {
      if (toggle.tagName === 'INPUT') {
        toggle.checked = enabled === 'true' || enabled === true;
      }
    });
  }

  function applyDyslexiaFont(enabled) {
    if (enabled === 'true' || enabled === true) {
      document.documentElement.setAttribute('data-dyslexia-font', 'true');
    } else {
      document.documentElement.removeAttribute('data-dyslexia-font');
    }

    document.querySelectorAll('[data-dyslexia-toggle]').forEach(toggle => {
      if (toggle.tagName === 'INPUT') {
        toggle.checked = enabled === 'true' || enabled === true;
      }
    });
  }

  function initSettings() {
    const savedTheme = getPreference(STORAGE_KEYS.theme, 'light');
    const savedFontSize = getPreference(STORAGE_KEYS.fontSize, 'normal');
    const savedReduceMotion = getPreference(STORAGE_KEYS.reduceMotion, 'false');
    const savedColorblind = getPreference(STORAGE_KEYS.colorblind, 'none');
    const savedAdhdMode = getPreference(STORAGE_KEYS.adhdMode, 'false');
    const savedDyslexiaFont = getPreference(STORAGE_KEYS.dyslexiaFont, 'false');

    // Clear any stored high contrast preference (feature removed)
    try { localStorage.removeItem(STORAGE_KEYS.highContrast); } catch(e) {}
    document.documentElement.removeAttribute('data-high-contrast');

    applyTheme(savedTheme);
    applyFontSize(savedFontSize);
    applyReduceMotion(savedReduceMotion);
    applyColorblind(savedColorblind);
    applyAdhdMode(savedAdhdMode);
    applyDyslexiaFont(savedDyslexiaFont);
  }

  function initSettingsListeners() {
    document.querySelectorAll('[data-theme-toggle]').forEach(toggle => {
      toggle.addEventListener('change', function() {
        const newTheme = this.checked ? 'dark' : 'light';
        setPreference(STORAGE_KEYS.theme, newTheme);
        applyTheme(newTheme);
      });
    });

    document.querySelectorAll('select[data-font-size-select]').forEach(select => {
      select.addEventListener('change', function() {
        const newSize = this.value;
        setPreference(STORAGE_KEYS.fontSize, newSize);
        applyFontSize(newSize);
      });
    });

    document.querySelectorAll('input[data-reduce-motion-toggle]').forEach(toggle => {
      toggle.addEventListener('change', function() {
        const newValue = this.checked ? 'true' : 'false';
        setPreference(STORAGE_KEYS.reduceMotion, newValue);
        applyReduceMotion(newValue);
      });
    });

    document.querySelectorAll('input[data-high-contrast-toggle]').forEach(toggle => {
      toggle.addEventListener('change', function() {
        const newValue = this.checked ? 'true' : 'false';
        setPreference(STORAGE_KEYS.highContrast, newValue);
        applyHighContrast(newValue);
      });
    });

    document.querySelectorAll('select[data-colorblind-select]').forEach(select => {
      select.addEventListener('change', function() {
        const newMode = this.value;
        setPreference(STORAGE_KEYS.colorblind, newMode);
        applyColorblind(newMode);
      });
    });

    document.querySelectorAll('input[data-adhd-toggle]').forEach(toggle => {
      toggle.addEventListener('change', function() {
        const newValue = this.checked ? 'true' : 'false';
        setPreference(STORAGE_KEYS.adhdMode, newValue);
        applyAdhdMode(newValue);
      });
    });

    document.querySelectorAll('input[data-dyslexia-toggle]').forEach(toggle => {
      toggle.addEventListener('change', function() {
        const newValue = this.checked ? 'true' : 'false';
        setPreference(STORAGE_KEYS.dyslexiaFont, newValue);
        applyDyslexiaFont(newValue);
      });
    });
  }

  function initSettingsDropdown() {
    const settingsWrappers = document.querySelectorAll('.settings-wrapper');
    
    settingsWrappers.forEach(wrapper => {
      const settingsToggle = wrapper.querySelector('[data-settings-toggle]');
      const settingsDropdown = wrapper.querySelector('[data-settings-dropdown]');

      if (settingsToggle && settingsDropdown) {
        settingsToggle.addEventListener('click', function(e) {
          e.stopPropagation();
          document.querySelectorAll('.settings-dropdown.active').forEach(d => {
            if (d !== settingsDropdown) d.classList.remove('active');
          });
          settingsDropdown.classList.toggle('active');
        });

        settingsDropdown.addEventListener('click', function(e) {
          e.stopPropagation();
        });
      }
    });

    document.addEventListener('click', function(e) {
      document.querySelectorAll('.settings-dropdown.active').forEach(dropdown => {
        dropdown.classList.remove('active');
      });
    });
  }

  function initUserButton() {
    const userBtns = document.querySelectorAll('[data-user-btn]');
    
    if (userBtns.length > 0 && typeof MindBalanceAuth !== 'undefined') {
      MindBalanceAuth.onAuthChange(function(user) {
        userBtns.forEach(userBtn => {
          if (user) {
            userBtn.classList.add('signed-in');
            userBtn.setAttribute('title', user.email || 'Signed in');
          } else {
            userBtn.classList.remove('signed-in');
            userBtn.setAttribute('title', 'Not signed in');
          }
        });
      });
    }
  }

  initSettings();

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initSettingsListeners();
      initSettingsDropdown();
      initUserButton();
    });
  } else {
    initSettingsListeners();
    initSettingsDropdown();
    initUserButton();
  }

  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function() {
      const savedTheme = getPreference(STORAGE_KEYS.theme, 'light');
      if (savedTheme === 'system') {
        applyTheme('system');
      }
    });
  }

  window.MindBalanceSettings = {
    setTheme: function(theme) {
      setPreference(STORAGE_KEYS.theme, theme);
      applyTheme(theme);
    },
    setFontSize: function(size) {
      setPreference(STORAGE_KEYS.fontSize, size);
      applyFontSize(size);
    },
    setReduceMotion: function(enabled) {
      setPreference(STORAGE_KEYS.reduceMotion, enabled ? 'true' : 'false');
      applyReduceMotion(enabled);
    },
    setHighContrast: function(enabled) {
      setPreference(STORAGE_KEYS.highContrast, enabled ? 'true' : 'false');
      applyHighContrast(enabled);
    },
    setColorblind: function(mode) {
      setPreference(STORAGE_KEYS.colorblind, mode);
      applyColorblind(mode);
    },
    setAdhdMode: function(enabled) {
      setPreference(STORAGE_KEYS.adhdMode, enabled ? 'true' : 'false');
      applyAdhdMode(enabled);
    },
    setDyslexiaFont: function(enabled) {
      setPreference(STORAGE_KEYS.dyslexiaFont, enabled ? 'true' : 'false');
      applyDyslexiaFont(enabled);
    },
    getPreferences: function() {
      return {
        theme: getPreference(STORAGE_KEYS.theme, 'light'),
        fontSize: getPreference(STORAGE_KEYS.fontSize, 'normal'),
        reduceMotion: getPreference(STORAGE_KEYS.reduceMotion, 'false') === 'true',
        highContrast: getPreference(STORAGE_KEYS.highContrast, 'false') === 'true',
        colorblind: getPreference(STORAGE_KEYS.colorblind, 'none'),
        adhdMode: getPreference(STORAGE_KEYS.adhdMode, 'false') === 'true',
        dyslexiaFont: getPreference(STORAGE_KEYS.dyslexiaFont, 'false') === 'true'
      };
    }
  };
})();
