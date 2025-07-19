const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticateToken = require('../middleware/auth');
// Protect all routes by adding authenticateToken middleware
router.use(authenticateToken);
// GET all tours
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM tours');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET one tour
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM tours WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Tour not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST new tour
router.post('/', async (req, res) => {
  const { company_id, lead_id, vehicle_id, driver_id, name,
    description,start_state,end_state,start_city,end_city,
    pickup_location,drop_location,start_date,end_date,
    duration_days,distance_km,type_of_tour,
    premium,total_amount,price } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO tours (company_id, lead_id, vehicle_id, driver_id, name,description,start_state,end_state,start_city,end_city,pickup_location,drop_location,start_date,end_date,duration_days,distance_km,type_of_tour,premium,total_amount,price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [company_id, lead_id, vehicle_id, driver_id, name,description,start_state,end_state,start_city,end_city,pickup_location,drop_location,start_date,end_date,duration_days,distance_km,type_of_tour,premium,total_amount,price ]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update tour
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
  if (req.body.description !== undefined) {
    fields.push('description = ?');
    values.push(req.body.description);
  }
  if (req.body.start_state !== undefined) {
    fields.push('start_state = ?');
    values.push(req.body.start_state);
  }
  if (req.body.end_state !== undefined) {
    fields.push('end_state = ?');
    values.push(req.body.end_state);
  }
  if (req.body.start_city !== undefined) {
    fields.push('start_city = ?');
    values.push(req.body.start_city);
  }
  if (req.body.end_city !== undefined) {
    fields.push('end_city = ?');
    values.push(req.body.end_city);
  }
  if (req.body.pickup_location !== undefined) {
    fields.push('pickup_location = ?');
    values.push(req.body.pickup_location);
  }
  if (req.body.drop_location !== undefined) {
    fields.push('drop_location = ?');
    values.push(req.body.drop_location);
  }
  if (req.body.start_date !== undefined) {
    fields.push('start_date = ?');
    values.push(req.body.start_date);
  }
  if (req.body.end_date !== undefined) {
    fields.push('end_date = ?');
    values.push(req.body.end_date);
  }
  if (req.body.duration_days !== undefined) {
    fields.push('duration_days = ?');
    values.push(req.body.duration_days);
  }
  if (req.body.distance_km !== undefined) {
    fields.push('distance_km = ?');
    values.push(req.body.distance_km);
  }
  if (req.body.type_of_tour !== undefined) {
    fields.push('type_of_tour = ?');
    values.push(req.body.type_of_tour);
  }
  if (req.body.premium !== undefined) {
    fields.push('premium = ?');
    values.push(req.body.premium);
  }
  if (req.body.total_amount !== undefined) {
    fields.push('total_amount = ?');
    values.push(req.body.total_amount);
  }
  if (req.body.price !== undefined) {
    fields.push('price = ?');
    values.push(req.body.price);
  }

  // If no valid fields sent
  if (fields.length === 0) {
    return res.status(400).json({ error: 'No valid fields provided for update' });
  }
  // Add the ID as the last parameter
  values.push(req.params.id);

  try {
    const sql = `UPDATE tours SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Tour details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE tour
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM tours WHERE id = ?', [req.params.id]);
    res.json({ message: 'Tour deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
