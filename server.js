const express = require('express');
const app = express();
require('dotenv').config();

const bookingsRouter = require('./routes/bookings');
const leadsRouter = require('./routes/leads');
const usersRouter = require('./routes/users');
const toursRouter = require('./routes/tours');
const vehiclesRouter = require('./routes/vehicles');
const driversRouter = require('./routes/drivers');
const authRoutes = require('./routes/auth');
const companiesRouter = require('./routes/companies');


app.use(express.json()); // For JSON body parsing

app.use(express.static('public'));

app.use('/auth', authRoutes);
app.use('/bookings', bookingsRouter); 
app.use('/leads', leadsRouter);
app.use('/users', usersRouter);
app.use('/tours', toursRouter);
app.use('/vehicles', vehiclesRouter);
app.use('/drivers', driversRouter);
app.use('/companies', companiesRouter);

app.get('/', (req, res) => {
  res.sendFile(require('path').join(__dirname, 'public', 'index.html'));
});
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
