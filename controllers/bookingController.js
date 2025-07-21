// controllers/bookingController.js
const db = require('../db');

// GET all bookings
exports.getBookings = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM bookings');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET booking by ID
exports.getBookingById = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM bookings WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Booking not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST new booking
exports.createBooking = async (req, res) => {
  const {
    company_id, lead_id, vehicle_id, driver_id, name, type_of_tour,
    booking_date, booking_end_date, booked_distance_km, actual_distance_km,
    actual_total_amount, total_amount, amount_paid, outstanding_amount,
    expenses, toll_tax, profit, status, tour_id
  } = req.body;

  try {
    const [result] = await db.query(
      `INSERT INTO bookings (
        company_id, lead_id, vehicle_id, driver_id, name, type_of_tour,
        booking_date, booking_end_date, booked_distance_km, actual_distance_km,
        actual_total_amount, total_amount, amount_paid, outstanding_amount,
        expenses, toll_tax, profit, status, tour_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        company_id, lead_id, vehicle_id, driver_id, name, type_of_tour,
        booking_date, booking_end_date, booked_distance_km, actual_distance_km,
        actual_total_amount, total_amount, amount_paid, outstanding_amount,
        expenses, toll_tax, profit, status, tour_id
      ]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PUT update booking
exports.updateBooking = async (req, res) => {
  const fields = [];
  const values = [];

  [
    'company_id', 'lead_id', 'vehicle_id', 'driver_id', 'name', 'type_of_tour',
    'booking_date', 'booking_end_date', 'booked_distance_km', 'actual_distance_km',
    'actual_total_amount', 'total_amount', 'amount_paid', 'outstanding_amount',
    'expenses', 'toll_tax', 'profit', 'status', 'tour_id'
  ].forEach(field => {
    if (req.body[field] !== undefined) {
      fields.push(`${field} = ?`);
      values.push(req.body[field]);
    }
  });

  if (fields.length === 0) {
    return res.status(400).json({ error: 'No valid fields provided for update' });
  }
  values.push(req.params.id);

  try {
    const sql = `UPDATE bookings SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Booking details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE booking
exports.deleteBooking = async (req, res) => {
  try {
    await db.query('DELETE FROM bookings WHERE id = ?', [req.params.id]);
    res.json({ message: 'Booking deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
