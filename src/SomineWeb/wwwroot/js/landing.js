(function () {
  'use strict';

  /* ─── Navbar scroll state (yalnız şeffaf başlayan navlar için) ─── */
  const nav = document.getElementById('siteNav');
  if (nav && nav.dataset.transparent === 'true') {
    const navLight = ['bg-white/80', 'backdrop-blur-2xl', 'shadow-[0_1px_3px_rgba(0,0,0,0.06)]', 'border-black/[0.04]'];
    const navTransp = ['bg-transparent', 'border-transparent'];
    const linkLight = ['text-gray-600', 'hover:text-gray-900', 'hover:bg-black/[0.04]'];
    const linkTransp = ['text-white/80', 'hover:text-white', 'hover:bg-white/[0.08]'];
    const ctaLight = ['bg-black', 'text-white', 'hover:bg-gray-800'];
    const ctaTransp = ['bg-white/15', 'text-white', 'border', 'border-white/20', 'hover:bg-white/25', 'backdrop-blur-sm'];
    const links = nav.querySelectorAll('.nav-link, .nav-ghost');
    const cta = nav.querySelector('.nav-cta');
    const logo = document.getElementById('navLogo');
    const menuBtn = document.getElementById('menuToggle');
    let isLight = false;

    const apply = (light) => {
      if (light === isLight) return;
      isLight = light;
      nav.classList.remove(...(light ? navTransp : navLight));
      nav.classList.add(...(light ? navLight : navTransp));
      links.forEach((l) => {
        l.classList.remove(...(light ? linkTransp : linkLight));
        l.classList.add(...(light ? linkLight : linkTransp));
      });
      if (cta) {
        cta.classList.remove(...(light ? ctaTransp : ctaLight));
        cta.classList.add(...(light ? ctaLight : ctaTransp));
      }
      if (logo) logo.style.filter = light ? '' : 'brightness(0) invert(1)';
      if (menuBtn) {
        menuBtn.classList.toggle('text-white', !light);
        menuBtn.classList.toggle('text-gray-900', light);
      }
    };

    const onScroll = () => apply(window.scrollY > 60);
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* ─── Mobil menü ─── */
  const menu = document.getElementById('mobileMenu');
  const panel = document.getElementById('menuPanel');
  const openBtn = document.getElementById('menuToggle');
  const closeBtn = document.getElementById('menuClose');
  const backdrop = document.getElementById('menuBackdrop');
  if (menu && panel && openBtn) {
    const open = () => {
      menu.classList.remove('hidden');
      requestAnimationFrame(() => panel.classList.remove('translate-x-full'));
      document.body.style.overflow = 'hidden';
    };
    const close = () => {
      panel.classList.add('translate-x-full');
      document.body.style.overflow = '';
      setTimeout(() => menu.classList.add('hidden'), 300);
    };
    openBtn.addEventListener('click', open);
    if (closeBtn) closeBtn.addEventListener('click', close);
    if (backdrop) backdrop.addEventListener('click', close);
    menu.querySelectorAll('.menu-link').forEach((l) => l.addEventListener('click', close));
  }

  /* ─── Scroll reveal (framer-motion useInView yerine) ─── */
  const reveals = document.querySelectorAll('.reveal');
  if (reveals.length) {
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver((entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add('in-view');
            io.unobserve(e.target);
          }
        });
      }, { rootMargin: '-60px 0px', threshold: 0.05 });
      reveals.forEach((el) => io.observe(el));
    } else {
      reveals.forEach((el) => el.classList.add('in-view'));
    }
  }

  /* ─── Hero platform ikon rotasyonu (her 3sn blok değişir) ─── */
  const heroBlocks = document.querySelectorAll('#heroIcons .hero-icon-block');
  if (heroBlocks.length > 1) {
    let active = 0;
    setInterval(() => {
      heroBlocks[active].classList.remove('opacity-100');
      heroBlocks[active].classList.add('opacity-0');
      active = (active + 1) % heroBlocks.length;
      heroBlocks[active].classList.remove('opacity-0');
      heroBlocks[active].classList.add('opacity-100');
    }, 3000);
  }

  /* ─── Swiper showcase ─── */
  if (window.Swiper && document.querySelector('.showcase-swiper')) {
    new window.Swiper('.showcase-swiper', {
      modules: window.Swiper.modules,
      grabCursor: true,
      centeredSlides: true,
      slidesPerView: 2.3,
      spaceBetween: 12,
      loop: true,
      speed: 700,
      autoplay: { delay: 2500, disableOnInteraction: false, pauseOnMouseEnter: true },
      breakpoints: {
        480: { slidesPerView: 3.3 },
        640: { slidesPerView: 5.7 },
      },
    });
  }

  /* ─── Scroll-to-top ─── */
  const toTop = document.getElementById('scrollToTop');
  if (toTop) {
    const toggle = () => {
      const show = window.scrollY > 400;
      toTop.classList.toggle('opacity-0', !show);
      toTop.classList.toggle('pointer-events-none', !show);
      toTop.classList.toggle('translate-y-2', !show);
    };
    window.addEventListener('scroll', toggle, { passive: true });
    toTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
    toggle();
  }
})();
