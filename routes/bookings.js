const express = require('express');
const router = express.Router();
const db = require('../db');

const authenticateToken = require('../middleware/auth');
//const authorizeRoles = require('../middleware/role');
// Protect all routes by adding authenticateToken middleware
router.use(authenticateToken);

// GET all bookings
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM bookings');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET booking by ID
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM bookings WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Booking not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST new booking
router.post('/', async (req, res) => {
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
});

// PUT update booking
router.put('/:id', async (req, res) => {
  const fields = [];
  const values = [];

  // Dynamically build query based on available fields
  if (req.body.company_id !== undefined) {
    fields.push('company_id = ?');
    values.push(req.body.company_id);
  }
  if (req.body.lead_id !== undefined) {
    fields.push('lead_id = ?');
    values.push(req.body.lead_id);
  }
  if (req.body.vehicle_id !== undefined) {
    fields.push('vehicle_id = ?');
    values.push(req.body.vehicle_id);
  }
  if (req.body.driver_id !== undefined) {
    fields.push('driver_id = ?');
    values.push(req.body.driver_id);
  }
  if (req.body.name !== undefined) {
    fields.push('name = ?');
    values.push(req.body.name);
  }
  if (req.body.type_of_tour !== undefined) {
    fields.push('type_of_tour = ?');
    values.push(req.body.type_of_tour);
  }
  if (req.body.booking_date !== undefined) {
    fields.push('booking_date = ?');
    values.push(req.body.booking_date);
  }
  if (req.body.booking_end_date !== undefined) {
    fields.push('booking_end_date = ?');
    values.push(req.body.booking_end_date);
  }
  if (req.body.booked_distance_km !== undefined) {
    fields.push('booked_distance_km = ?');
    values.push(req.body.booked_distance_km);
  }
  if (req.body.actual_distance_km !== undefined) {
    fields.push('actual_distance_km = ?');
    values.push(req.body.actual_distance_km);
  }
  if (req.body.actual_total_amount !== undefined) {
    fields.push('actual_total_amount = ?');
    values.push(req.body.actual_total_amount);
  }
  if (req.body.total_amount !== undefined) {
    fields.push('total_amount = ?');
    values.push(req.body.total_amount);
  }
  if (req.body.amount_paid !== undefined) {
    fields.push('amount_paid = ?');
    values.push(req.body.amount_paid);
  }
  if (req.body.outstanding_amount !== undefined) {
    fields.push('outstanding_amount = ?');
    values.push(req.body.outstanding_amount);
  }
  if (req.body.expenses !== undefined) {
    fields.push('expenses = ?');
    values.push(req.body.expenses);
  }
  if (req.body.toll_tax !== undefined) {
    fields.push('toll_tax = ?');
    values.push(req.body.toll_tax);
  }
  if (req.body.profit !== undefined) {
    fields.push('profit = ?');
    values.push(req.body.profit);
  }
  if (req.body.status !== undefined) {
    fields.push('status = ?');
    values.push(req.body.status);
  }
  if (req.body.tour_id !== undefined) {
    fields.push('tour_id = ?');
    values.push(req.body.tour_id);
  }

  // If no valid fields sent
  if (fields.length === 0) {
    return res.status(400).json({ error: 'No valid fields provided for update' });
  }
  // Add the ID as the last parameter
  values.push(req.params.id);

  try {
    const sql = `UPDATE bookings SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Booking details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE booking
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM bookings WHERE id = ?', [req.params.id]);
    res.json({ message: 'Booking deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
