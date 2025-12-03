function leadCreatedTemplate(name) {
  return `
  <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.12);">

  <!-- Banner -->
  <div style="width: 100%;">
    <img src="https://images.unsplash.com/photo-1507525428034-b723cf961d3e" alt="Travel Banner" style="width: 100%; height: 125px; display: block;">
  </div>

  <!-- Header with Glossy Gradient -->
  <div style="background: linear-gradient(135deg, #00d4ff, #0077ff); padding: 20px; text-align: center; position: relative; overflow: hidden;">
    <!-- Glossy overlay -->
    <div style="position: absolute; top: 0; left: 0; right: 0; height: 70%; background: rgba(255,255,255,0.25); clip-path: polygon(0 0, 100% 0, 100% 50%, 0 100%);"></div>
    <h1 style="margin: 0; font-size: 26px; font-weight: bold; color: white; position: relative; z-index: 1;">Sai Ram Tours & Travels</h1>
  </div>

  <!-- Body -->
  <div style="padding: 20px;">
    <h2 style="color: #333; margin-top: 0;">Hi ${name},</h2>
    <p style="color: #555; font-size: 15px; line-height: 1.6;">
      Thank you for showing your interest in our services! 🌏  
      We’ve received your request and our team will get in touch with you soon.
    </p>
    <p style="color: #555; font-size: 15px; line-height: 1.6;">
      In the meantime, if you have any questions or need quick assistance, just click the button below or call us directly.
    </p>

    <!-- Call to Action Button -->
    <div style="text-align: center; margin: 25px 0;">
      <a href="tel:7755926255" style="background: linear-gradient(135deg, #00c6ff, #0072ff); color: white; padding: 14px 28px; border-radius: 30px; text-decoration: none; font-size: 15px; font-weight: bold; display: inline-block; box-shadow: 0 4px 12px rgba(0,0,0,0.25);">
        📞 Call Us Now
      </a>
    </div>

    <p style="color: #333; font-size: 15px; margin-bottom: 0;">
      Best Regards,<br>
      <strong>Sai Ram Tours & Travels</strong>
    </p>
  </div>

  <!-- Footer -->
  <div style="background-color: #f8f8f8; color: #777; font-size: 12px; text-align: center; padding: 12px;">
    &copy; ${new Date().getFullYear()} Sai Ram Tours & Travels. All rights reserved.
  </div>

</div>
  `;
}

module.exports = leadCreatedTemplate;
