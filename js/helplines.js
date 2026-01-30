document.addEventListener('DOMContentLoaded', function() {
  initHelplinesFilters();
  initCopyButtons();
});

function initHelplinesFilters() {
  const filterPills = document.querySelectorAll('.helplines-filter-pill');
  const helplineCards = document.querySelectorAll('.helpline-card');
  const helplinesGrid = document.querySelector('.helplines-grid');
  
  if (!filterPills.length || !helplineCards.length) return;
  
  filterPills.forEach(pill => {
    pill.addEventListener('click', function() {
      const filter = this.dataset.filter;
      
      filterPills.forEach(p => p.classList.remove('active'));
      this.classList.add('active');
      
      helplineCards.forEach((card, index) => {
        const category = card.dataset.category;
        const shouldShow = filter === 'all' || category === filter;
        
        if (shouldShow) {
          card.classList.remove('filter-hidden');
          card.classList.add('filter-visible');
          card.style.position = 'relative';
          card.style.visibility = 'visible';
          card.style.animationDelay = `${index * 0.05}s`;
        } else {
          card.classList.add('filter-hidden');
          card.classList.remove('filter-visible');
          setTimeout(() => {
            if (card.classList.contains('filter-hidden')) {
              card.style.position = 'absolute';
              card.style.visibility = 'hidden';
            }
          }, 300);
        }
      });
      
      if (helplinesGrid) {
        helplinesGrid.style.minHeight = '400px';
      }
    });
  });
}

function initCopyButtons() {
  document.querySelectorAll('.helpline-copy-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      const phoneNumber = this.dataset.phone;
      if (!phoneNumber) return;
      
      navigator.clipboard.writeText(phoneNumber).then(() => {
        this.classList.add('copied');
        const icon = this.querySelector('ion-icon');
        if (icon) {
          icon.setAttribute('name', 'checkmark-outline');
        }
        
        setTimeout(() => {
          this.classList.remove('copied');
          if (icon) {
            icon.setAttribute('name', 'copy-outline');
          }
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy:', err);
        const textArea = document.createElement('textarea');
        textArea.value = phoneNumber;
        textArea.style.position = 'fixed';
        textArea.style.left = '-9999px';
        document.body.appendChild(textArea);
        textArea.select();
        try {
          document.execCommand('copy');
          this.classList.add('copied');
          const icon = this.querySelector('ion-icon');
          if (icon) {
            icon.setAttribute('name', 'checkmark-outline');
          }
          setTimeout(() => {
            this.classList.remove('copied');
            if (icon) {
              icon.setAttribute('name', 'copy-outline');
            }
          }, 2000);
        } catch (fallbackErr) {
          console.error('Fallback copy failed:', fallbackErr);
        }
        document.body.removeChild(textArea);
      });
    });
  });
}
