const express = require('express');
const router = express.Router();
const db = require('../db');

// GET all users
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET user by ID
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'User not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST new user
router.post('/', async (req, res) => {
  const { username, email, password, role } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO users (username, email, password, role, mobile) VALUES (?, ?, ?, ?, ?)',
      [username, email, password, role,mobile]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update user
router.put('/:id', async (req, res) => {
  const { username, email, password, role, mobile } = req.body;
  const fields = [];
  const values = [];

  if (username !== undefined) {
    fields.push('username = ?');
    values.push(username);
  }
  if (email !== undefined) {
    fields.push('email = ?');
    values.push(email);
  }
  if (password !== undefined) {
    fields.push('password = ?');
    values.push(password);
  }
  if (role !== undefined) {
    fields.push('role = ?');
    values.push(role);
  }
  if (mobile !== undefined) {
    fields.push('mobile = ?');
    values.push(mobile);
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }

  const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
  values.push(req.params.id);

  try {
    await db.query(sql, values);
    res.json({ message: 'User updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// DELETE user
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM users WHERE id = ?', [req.params.id]);
    res.json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
