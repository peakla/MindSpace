# MindBalance

## Overview

MindBalance is a static website platform providing curated, credible information and resources on mental health topics like anxiety, depression, stress, and mindfulness. It offers a resource library, blog content, and user authentication for personalized features such as saving articles. The project aims to be an accessible digital hub for mental wellness, sourcing information from authoritative providers.

## User Preferences

Preferred communication style: Simple, everyday language.
Design preference: NO glassmorphism (no backdrop-blur effects). Use solid, clean card designs with subtle shadows and borders instead.

## System Architecture

### Core Design
MindBalance is a static website built with HTML, CSS, and JavaScript, employing a component-based styling approach with a strong focus on accessibility and user experience.

### Frontend
-   **Structure & Styling**: Multiple static HTML pages, custom CSS with a robust custom properties system for theming, and Poppins font family.
-   **Interactivity**: Vanilla JavaScript for DOM manipulation and managing user preferences.
-   **Animation System**: Comprehensive shared animation library (`css/animations.css` and `js/animations.js`) providing:
    - Scroll-triggered animations via IntersectionObserver (fade-in, slide-up, slide-left, slide-right, scale-in, blur-in)
    - Staggered card reveal animations for grids
    - Hover effects (lift, scale, glow, 3D tilt, shine)
    - Continuous animations (float, pulse, shimmer, bounce)
    - Enhanced quote-block component with floating animation and decorative elements
    - Back-to-top button with bounce animation
    - Full dark mode support for all animations
    - Respects `prefers-reduced-motion` for accessibility
-   **Accessibility**: Comprehensive settings panel offering 7 options (Dark Mode, Font Size, High Contrast, Colorblind modes, Focus Mode, Dyslexia Font, Reduced Motion) with preferences persisted via localStorage.
-   **Enhanced Settings Modal** (`css/settings-modal.css` and `js/settings-modal.js`): Full-featured modal experience with:
    - First-time onboarding wizard for new users
    - Tabbed navigation (Appearance, Accessibility, Reading, Language)
    - Theme presets (Calm Ocean, Warm Sunset, Forest Green, Night Mode, High Contrast) with live preview
    - Before/After comparison toggle for accessibility settings
    - Accessibility score ring with real-time calculation
    - Profile sync indicator showing when settings are saved to account
    - Reset buttons per section and master reset to defaults
    - Keyboard navigation (Escape to close, Tab cycling)
    - Full dark mode support with purple accent colors
    - Integrated across all 21+ pages
-   **User Accent Color System**: Theme-aware accent color picker with 8 color options (gold, purple, blue, green, teal, pink, orange, red). Applied via CSS custom properties (`--user-accent`, `--user-accent-hover`, `--user-accent-rgb`, `--user-accent-glow`) at `:root` level. Default accent is gold-crayola (#af916d) for light mode and purple (#9b7ed9) for dark mode. User-selected accent persists independently of theme and is applied to all interactive elements (buttons, links, progress bars, TOC pills, TTS controls, scrollbars).
-   **Responsiveness**: Full responsive design with orientation lock messages and safe area support.
-   **Responsive Design System** (`css/responsive-system.css`): Comprehensive responsive framework providing:
    - Fluid typography scale using clamp() for seamless scaling (--fs-display through --fs-tiny)
    - Consistent spacing scale (--space-3xs through --space-3xl) using CSS variables
    - Line-height and letter-spacing scales for consistent vertical rhythm
    - Text wrapping improvements (overflow-wrap, text-wrap: balance/pretty)
    - Opt-in utility classes for grids, flexbox, spacing, and typography
    - Container, card, and section utility classes (resp-container, resp-card, resp-section)
    - Print styles and reduced motion support
    - Integrated across all 21+ pages
-   **Multilingual Support**: Supports 6 languages (English, Spanish, French, Chinese Simplified, Hindi, Korean) using `data-translate` attributes and JSON-based translation files. Language preference persists in localStorage. A CSV master file (`translations.csv`) is the single source of truth for translations, with Python scripts to generate JSON files and audit for completeness.

### Backend/Data
-   **Authentication**: Utilizes Supabase for email/password authentication and user sessions.
-   **Community Hub**: Live forum with posts, comments, and likes stored in Supabase, featuring real-time updates, profanity filtering, media uploads, and admin moderation.
-   **Data Storage**: Resource library data is stored in static JSON files, linking to external authoritative sources.
-   **Resource Suggestions**: User-submitted resource suggestions are stored in a Supabase table for administrative review.

### Key Features
-   **Homepage Enhancements** (`css/quote-banner.css` and `js/quote-banner.js`):
    - **Inspirational Quote Banner**: Rotating quotes from mental health advocates with smooth fade transitions, navigation dots, auto-rotation (12s), pause on hover/focus, and full accessibility support
    - **Daily Wellness Tip**: Day-of-week rotating tips with actionable advice, icon, and call-to-action button linking to relevant resources
    - Full translation support for all 6 languages
    - Dark mode styling and reduced motion respect
-   **Resource Library**: Interactive directory with featured resources spotlight, non-profit organizations (NAMI, Mental Health America, Crisis Text Line, The Trevor Project, 988 Lifeline), community resources with local examples, a suggestion form, real-time search and filtering (including Non-Profit and Community categories), share buttons, and visual polish (card effects, animations, skeleton loading).
-   **Find Help** (`/find-help/`): Dedicated page for finding local mental health services:
    - Always-visible crisis resources section (988 Lifeline, Crisis Text Line, Trevor Project)
    - National non-profits with local chapter finders (pulled from resources.json)
    - Links to external helplines and support organizations
-   **Support Page**: Provides crisis support, helplines, self-help tools (breathing, grounding, journaling), an appointment scheduler, and a split-panel FAQ with modern design (questions list on left, answer display on right, category tabs, search, prev/next navigation, quick tips section, responsive mobile layout).
-   **User Settings**: Persistent panel for customizing accessibility options.
-   **Navigation**: Dynamic navbar with a crisis button, search bar with typeahead, dropdown menus, notification badges, and a mobile-specific hamburger menu.
-   **User Profile Page**: Instagram-style profile with cover and avatar uploads, editable display name and bio, social links, unified stats card (posts, comments, likes, followers, following, reputation, streak badges), and multiple tabs (Activity, Liked Posts, Saved Articles, Achievements, Wellness, Settings). Includes a mood tracker, wellness goals CRUD, reading streak calendar, profile theme picker, privacy controls, and account deletion functionality. Supports public profile viewing with privacy considerations and a social follow/unfollow system.
-   **First-Time Profile Onboarding**: Welcoming modal that appears for new users who haven't set a display name. Features required display name field (2+ characters), optional bio, and cannot be dismissed without completing setup. Ensures all users have a proper display name for community interactions.
-   **Immersive Profile Experience** (`profile/profile-immersive.css` and `profile/profile-immersive.js`): Cinematic, full-page profile with:
    - **Day/Night Cycle**: Time-based gradients, colors, and decorative elements that change based on user's local time (morning/afternoon/evening/night)
    - **Personalized Greeting**: Time-aware welcome messages with user's name and daily affirmations
    - **Parallax Background**: Floating animated shapes, stars (night), sun rays (day), and moon elements
    - **Scroll-Triggered Animations**: Reveal effects for all profile sections (fade-in, slide-up, scale, stagger)
    - **Clean Card Design**: Solid cards with subtle shadows and borders
    - **Haptic Feedback**: Vibration feedback on mobile for button interactions (light/medium/heavy)
    - **Community Connections**: "People You May Know" suggestions with follow functionality
    - **AI Wellness Insights**: OpenAI-powered personalized insights, mood analysis, and goal suggestions
    - Full dark mode support and reduced motion respect
-   **Enhanced Wellness Tab** (`profile/wellness-enhanced.css`): Comprehensive visual overhaul including:
    - Full-width profile layout (1400px max-width) for better laptop/desktop experience
    - Clean card effects with solid backgrounds and gradient top borders
    - Mood tracker with large animated emoji buttons (2rem), glow effects on selection, and wiggle animations
    - Mood entry cards redesigned to match Liked Posts style: emoji in circular container, mood label (color-coded), date/time, and note preview with chat icon
    - Wellness goals with category icons (leaf, fitness, moon, people, book), enhanced empty states, and delete button hover effects
    - Reading streak with animated flame icon, GitHub-style activity calendar with 4 intensity levels, and milestone badges (7/14/30/100 day)
    - Full dark mode support and mobile responsive design (768px/480px breakpoints)
-   **Analytics & Tracking System**: Comprehensive user activity tracking via centralized `analytics.js` and `auth.js` modules:
    - Tracks page views, article reads/completions, scroll depth, time spent on pages
    - **Daily visit logging** with streak calculation - automatically logs visits to `user_engagement` table
    - **Reading streak tracking** - calculates consecutive daily visits with current and longest streak stats
    - **Expanded Achievement System**: 28 unlockable badges across 5 categories (community, engagement, reading, wellness, social) with unlock animations
    - Calendar heatmap visualization (GitHub-style) showing daily activity levels
    - Activity timeline with icons, timestamps, and smooth animations
    - Reading stats cards with animated bar charts
    - Progress rings for wellness goals
    - Four Supabase tables: `user_activity_logs`, `reading_progress`, `user_achievements`, `user_engagement`
    - Full dark mode support and skeleton loading states
-   **Enhanced Footer** (`js/footer.js`): Comprehensive modern footer with:
    - Animated three-layer wave separator with CSS keyframe animations
    - Decorative dot pattern overlay for visual texture
    - Gradient backgrounds with radial overlay effects
    - Trust badges section (Privacy First, Accessible, Community)
    - Newsletter signup form with email input, subscribe button, and success toast
    - Recent blog posts preview section with 3 latest articles
    - Collapsible accordion navigation for mobile (expand/collapse with animation)
    - Footer controls: language selector dropdown + dark/light mode toggle with bidirectional sync to header
    - Social media icons: Instagram + YouTube (https://www.youtube.com/@MindBaIance)
    - Rounded pill-style buttons with shadows and hover effects
    - Clean topic tags with solid backgrounds
    - Full dark mode support with consistent purple accent colors (--purple-accent, --purple-gradient variables)
    - Back-to-top button with smooth scroll and bounce animation
    - Control sync: Footer and header theme/language toggles stay synchronized via shared localStorage keys
-   **Community Hub Enhancements**: Features popular discussions sidebar, clickable usernames linking to profiles, an @mentions system with autocomplete, and an inbox/notifications modal.
-   **Article Pages**: Dedicated `/articles/` directory for full-length, TTS-enabled articles with a magazine-style layout, TTS audio player with advanced controls (speed, highlighting, progress), floating reading controls panel (font size, line spacing, dark mode, focus mode, print), text highlighting, bookmarking, and an enhanced sticky Table of Contents sidebar. Includes reading time per section, completion checkmarks, mini-map, scroll position indicator, keyboard navigation, and social share buttons. Also features a "Save Article" button and related articles section.
-   **News & Stories Section**: Dedicated blog section featuring real stories, research updates, and community spotlights. Includes 6 article pages: Mental Health Research News, Recovery Stories, Workplace Wellness, Teen Mental Health Support, Community Support, and Mental Health Wins. All articles feature "New" badges with pulse animation, TTS audio, and full reading controls.
-   **Legal Pages**: Dedicated pages for Terms of Service, Privacy Policy, and Disclaimer, all styled consistently.

## External Dependencies

-   **Supabase**: For user authentication, community forum backend (database, Realtime, Storage).
-   **Swiper.js**: For carousel and slider functionalities.
-   **Font Awesome**: For iconography.
-   **Google Fonts**: For "Poppins", "Montserrat", and "Noto Sans KR" font families.
-   **External Content Providers**: National Institute of Mental Health (NIMH) and Mayo Clinic for credible resource content.
-   **OpenAI (via Replit AI Integrations)**: For AI-powered wellness insights, mood analysis, and goal suggestions in the profile wellness tab.
-   **ElevenLabs**: For high-quality text-to-speech in article pages.