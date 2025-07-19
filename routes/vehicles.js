const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticateToken = require('../middleware/auth');
// Protect all routes by adding authenticateToken middleware
router.use(authenticateToken);

// GET all vehicles
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM vehicles');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET one vehicle
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM vehicles WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Vehicle not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST new vehicle
router.post('/', async (req, res) => {
  const { company_id, registration_number, make, owner_driver_id, 
    assigned_driver_id,capacity,available_status } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO vehicles ( company_id, registration_number, make, owner_driver_id, assigned_driver_id,capacity,available_status ) VALUES (?, ?, ?,?,?,?,?)',
      [ company_id, registration_number, make, owner_driver_id, assigned_driver_id,capacity,available_status ]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update vehicle
router.put('/:id', async (req, res) => {
    const fields = [];
    const values = [];

    // Dynamically build query based on available fields
    if (req.body.company_id !== undefined) {
      fields.push('company_id = ?');
      values.push(req.body.company_id);
    }
    if (req.body.registration_number !== undefined) {
      fields.push('registration_number = ?');
      values.push(req.body.registration_number);
    }
    if (req.body.make !== undefined) {
      fields.push('make = ?');
      values.push(req.body.make);
    }
    if (req.body.owner_driver_id !== undefined) {
      fields.push('owner_driver_id = ?');
      values.push(req.body.owner_driver_id);
    }
    if (req.body.assigned_driver_id !== undefined) {
      fields.push('assigned_driver_id = ?');
      values.push(req.body.assigned_driver_id);
    }  
    if (req.body.capacity !== undefined) {
      fields.push('capacity = ?');
      values.push(req.body.capacity);
    }
    if (req.body.available_status !== undefined) {
      fields.push('available_status = ?');
      values.push(req.body.available_status);
    } 
    // If no valid fields sent
    if (fields.length === 0) {
      return res.status(400).json({ error: 'No valid fields provided for update' });
    }
    // Add the ID as the last parameter
    values.push(req.params.id);

  try {
    const sql = `UPDATE vehicles SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Vehicle details updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE vehicle
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM vehicles WHERE id = ?', [req.params.id]);
    res.json({ message: 'Vehicle deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
