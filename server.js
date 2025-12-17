const express = require('express');
const path = require('path');
const app = express();
require('dotenv').config();
const { sendEmail } = require('./controllers/emailHelper');
const leadCreatedTemplate = require('./templates/leadCreated');
const enquiryCreatedTemplate = require('./templates/enquiryCreated');

const bookingsRouter = require('./routes/bookings');
const leadsRouter = require('./routes/leads');
const usersRouter = require('./routes/users');
const toursRouter = require('./routes/tours');
const vehiclesRouter = require('./routes/vehicles');
const driversRouter = require('./routes/drivers');
const authRoutes = require('./routes/auth');
const companiesRouter = require('./routes/companies');

app.use(express.json()); // For JSON body parsing

//app.use(express.static('public'));
// Safer than express.static('public')
// app.use(express.static(path.join(__dirname, 'public'))); // [web:16]

const staticDir = process.env.NODE_ENV === 'production' ? 'dist' : 'public';
app.use(express.static(path.join(__dirname, staticDir)));

// If deployed behind nginx / load balancer (HTTPS termination), enable this
// app.set('trust proxy', 1); // [web:73]

const PORT = process.env.PORT || 3000;

// IMPORTANT: use fixed base URL for server-to-server calls (don’t use req.get('host'))
const API_BASE_URL = process.env.API_BASE_URL || `http://127.0.0.1:${PORT}`; // [web:87]

let cachedToken = null;
let tokenFetchedAt = 0;
const TOKEN_TTL_MS = 10 * 60 * 1000;

async function getServiceToken() {
  const now = Date.now();
  if (cachedToken && (now - tokenFetchedAt) < TOKEN_TTL_MS) return cachedToken;

  const res = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', },
    body: JSON.stringify({
      email: process.env.SERVICE_EMAIL,
      password: process.env.SERVICE_PASSWORD,
    }),
  });

  if (!res.ok) {
    throw new Error(`Service login failed (HTTP ${res.status})`);
  }

  const data = await res.json();
  const token = data.token || data.accessToken;
  if (!token) throw new Error('Login response did not include a token');

  cachedToken = token;
  tokenFetchedAt = now;
  return token;
}
app.post('/api/enquiry', async (req, res) => {
  try {
    const { name, phone, email } = req.body || {};
    if (!name || !phone || !email) {
      return res.status(400).json({ message: 'name, phone, email are required' });
    }
    // const requestBaseUrl = `${req.protocol}://${req.get('host')}`;
    // console.log('Request Base URL:', requestBaseUrl);

    const token = await getServiceToken();

    const leadRes = await fetch(`${API_BASE_URL}/leads/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        name,
        phone,
        email,
        source: 'Website',
        status: 'New',
      }),
    });

    const contentType = leadRes.headers.get('content-type') || '';
    const payload = contentType.includes('application/json') ? await leadRes.json() : await leadRes.text();

    if (leadRes.status === 409) { // 409 Conflict (duplicate) [web:89]
      // Customer email (keep it same tone as "thank you" email)
      const subject = 'Thank you for your interest';
      const text = `Hello ${name}, Thank you for showing interest. We have received your details.`;
      const html = leadCreatedTemplate(name);

      // Admin email (explicitly mark as existing lead)
      const adminSubject = 'New enquiry for existing lead received';
      const adminText =
        `Hello Admin, a new enquiry was received for an existing lead.\n` +
        `Name: ${name}\nPhone: ${phone}\nEmail: ${email}\nSource: Website`;
      const adminHTML = enquiryCreatedTemplate({ name, phone, email, source: 'Website' });

      setImmediate(() => {
        sendEmail(email, subject, html, text).catch(err => console.error('Customer email error:', err));
        sendEmail('contact.gosrtt@gmail.com', adminSubject, adminHTML, adminText).catch(err => console.error('Admin email error:', err));
      });

      return res.status(200).json({ message: 'Thanks! Your enquiry has been received.' });

    }

    return res.status(leadRes.status).send(payload);

  } catch (err) {
    return res.status(500).json({ message: err.message || 'Server error' });
  }
});

app.use('/auth', authRoutes);
app.use('/bookings', bookingsRouter);
app.use('/leads', leadsRouter);
app.use('/users', usersRouter);
app.use('/tours', toursRouter);
app.use('/vehicles', vehiclesRouter);
app.use('/drivers', driversRouter);
app.use('/companies', companiesRouter);

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
