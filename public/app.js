// Utilities
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

document.addEventListener('DOMContentLoaded', () => {
  // Year in footer
  $('#year').textContent = new Date().getFullYear();

  // Mobile nav
  const toggle = $('.nav-toggle');
  const menu = $('#nav-menu');
  if (toggle && menu) {
    toggle.addEventListener('click', () => {
      const open = menu.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }

  // Accordion
  $$('.accordion-header').forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.parentElement;
      const expanded = btn.getAttribute('aria-expanded') === 'true';
      btn.setAttribute('aria-expanded', String(!expanded));
      if (!expanded) item.setAttribute('aria-expanded', 'true');
      else item.removeAttribute('aria-expanded');
    });
  });

  // Booking modal
  const modal = $('#booking-modal');
  const form = $('#booking-form');
  const fareEl = $('#fare');
  const fareNote = $('#fare-note');

  // Pre-fill date/time to now+2h
  const dateInput = form.querySelector('input[name="date"]');
  const timeInput = form.querySelector('input[name="time"]');
  const now = new Date(Date.now() + 2*60*60*1000);
  dateInput.valueAsDate = now;
  timeInput.value = now.toTimeString().slice(0,5);

  // Open modal
  $$('[data-open-booking]').forEach(btn => {
    btn.addEventListener('click', () => {
      const tour = btn.getAttribute('data-tour');
      if (tour) {
        form.notes.value = `Booking for: ${tour}`;
      }
      if (typeof modal.showModal === 'function') modal.showModal();
      else modal.setAttribute('open','');
    });
  });

  // Close modal
  $$('[data-close]').forEach(btn => {
    btn.addEventListener('click', () => modal.close());
  });

  // Fare estimation logic (simple, client-side)
  const base = {
    sedan: { perKm: 18, base: 120 },
    suv:   { perKm: 24, base: 180 },
    van:   { perKm: 30, base: 250 }
  };
  const multipliers = {
    oneway: 1,
    round: 1.8,
    hourly: 1 // base + perKm uses "distance" as approx hours*12km
  };

  function numberOrZero(v){ const n = parseFloat(v); return Number.isFinite(n) ? n : 0; }

  function updateFare() {
    const vehicle = form.vehicle.value || 'sedan';
    const distance = numberOrZero(form.distance.value);
    const tripType = form.tripType.value || 'oneway';
    const pax = Math.max(1, parseInt(form.passengers.value || '1', 10));

    const slab = base[vehicle] || base.sedan;
    let calcDistance = distance;

    if (tripType === 'hourly') {
      // interpret "distance" as hours and convert to km heuristic
      calcDistance = distance * 12; // ~12km/hour average
      fareNote.textContent = 'Hourly estimate assumes ~12km/hour usage.';
    } else if (tripType === 'round') {
      fareNote.textContent = 'Round trip estimate includes return at discounted rate.';
    } else {
      fareNote.textContent = 'Estimate updates as details change.';
    }

    // Night surcharge 22:00–05:00
    const t = form.time.value || '12:00';
    const hr = parseInt(t.split(':')[0], 10);
    const night = (hr >= 22 || hr < 5) ? 1.15 : 1;

    // Extra passenger handling fee for vans beyond 8
    const paxFee = (vehicle === 'van' && pax > 8) ? 200 : 0;

    let estimate = slab.base + slab.perKm * calcDistance;
    estimate *= multipliers[tripType] || 1;
    estimate = estimate * night + paxFee;

    // Minimum fare enforcement
    const minFare = { sedan: 250, suv: 400, van: 550 }[vehicle] || 250;
    estimate = Math.max(estimate, minFare);

    fareEl.textContent = `₹${Math.round(estimate).toLocaleString('en-IN')}`;
  }

  form.addEventListener('input', updateFare);
  updateFare();

  // Submit booking -> POST to your existing API
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    // Compose ISO datetime
    try {
      const d = new Date(`${data.date}T${data.time}:00`);
      data.pickupTime = d.toISOString();
    } catch { /* noop */ }

    // Map vehicle and tripType to backend expectations if needed
    const payload = {
      pickup: data.pickup,
      drop: data.drop,
      pickupTime: data.pickupTime,
      vehicleType: data.vehicle,
      passengers: Number(data.passengers),
      tripType: data.tripType,
      approxDistanceKm: Number(data.distance),
      notes: data.notes || '',
      source: 'website'
    };

    // If you have /bookings API:
    // Change to your actual endpoint fields
    try {
      const res = await fetch('/bookings', {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify(payload)
      });
      if (!res.ok) throw new Error('Failed to create booking');
      const json = await res.json();
      modal.close();
      alert('Booking received! Reference: ' + (json.reference || json.id || 'N/A'));
    } catch (err) {
      alert('Could not submit booking. Please try again.');
      console.error(err);
    }
  });

  // Contact form (example -> send as lead)
  const contactForm = $('#contact-form');
  const statusEl = $('.form-status');
  contactForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    statusEl.textContent = 'Sending...';
    const data = Object.fromEntries(new FormData(contactForm).entries());
    try {
      const res = await fetch('/leads', {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({
          name: data.name,
          email: data.email,
          phone: data.phone,
          topic: data.topic,
          message: data.message,
          source: 'website'
        })
      });
      if (!res.ok) throw new Error('Failed to send');
      statusEl.textContent = 'Thanks! We will contact you shortly.';
      contactForm.reset();
    } catch (err) {
      statusEl.textContent = 'Something went wrong. Please try again.';
      console.error(err);
    }
  });
});
