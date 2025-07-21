// controllers/vehiclesController.js
const db = require('../db');

// GET all vehicles
exports.getVehicles = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM vehicles');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET one vehicle by id
exports.getVehicleById = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM vehicles WHERE id = ?', [req.params.id]);
    if (rows.length === 0)
      return res.status(404).json({ message: 'Vehicle not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST new vehicle
exports.createVehicle = async (req, res) => {
  const {
    company_id, registration_number, make,
    owner_driver_id, assigned_driver_id, capacity, available_status,
  } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO vehicles (company_id, registration_number, make, owner_driver_id, assigned_driver_id, capacity, available_status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [company_id, registration_number, make, owner_driver_id, assigned_driver_id, capacity, available_status]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PUT update vehicle
exports.updateVehicle = async (req, res) => {
  const fields = [];
  const values = [];

  [
    'company_id', 'registration_number', 'make', 'owner_driver_id',
    'assigned_driver_id', 'capacity', 'available_status'
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
    const sql = `UPDATE vehicles SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Vehicle details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE vehicle
exports.deleteVehicle = async (req, res) => {
  try {
    await db.query('DELETE FROM vehicles WHERE id = ?', [req.params.id]);
    res.json({ message: 'Vehicle deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
