// controllers/toursController.js
const db = require('../db');

// GET all tours
exports.getTours = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM tours');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET one tour by id
exports.getTourById = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM tours WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Tour not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST new tour
exports.createTour = async (req, res) => {
  const {
    company_id, lead_id, vehicle_id, driver_id, name,
    description, start_state, end_state, start_city, end_city,
    pickup_location, drop_location, start_date, end_date,
    duration_days, distance_km, type_of_tour,
    premium, total_amount, price
  } = req.body;

  try {
    const [result] = await db.query(
      `INSERT INTO tours (
        company_id, lead_id, vehicle_id, driver_id, name,
        description, start_state, end_state, start_city, end_city,
        pickup_location, drop_location, start_date, end_date,
        duration_days, distance_km, type_of_tour,
        premium, total_amount, price
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        company_id, lead_id, vehicle_id, driver_id, name,
        description, start_state, end_state, start_city, end_city,
        pickup_location, drop_location, start_date, end_date,
        duration_days, distance_km, type_of_tour,
        premium, total_amount, price
      ]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PUT update tour
exports.updateTour = async (req, res) => {
  const fields = [];
  const values = [];

  [
    'company_id', 'lead_id', 'vehicle_id', 'driver_id', 'name',
    'description', 'start_state', 'end_state', 'start_city', 'end_city',
    'pickup_location', 'drop_location', 'start_date', 'end_date',
    'duration_days', 'distance_km', 'type_of_tour',
    'premium', 'total_amount', 'price'
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
    const sql = `UPDATE tours SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Tour details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE tour
exports.deleteTour = async (req, res) => {
  try {
    await db.query('DELETE FROM tours WHERE id = ?', [req.params.id]);
    res.json({ message: 'Tour deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
