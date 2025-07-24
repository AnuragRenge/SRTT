const db = require('../db');

// GET all leads
exports.getLeads = async (req, res) => {
  
  try {
    const [rows] = await db.query('SELECT * FROM leads');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET lead by ID
exports.getLeadById = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM leads WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Lead not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST new lead
exports.createLead = async (req, res) => {
  const { name, phone, email, source, status } = req.body;
  try {
    const [existingLeads] = await db.query(
      'SELECT id FROM leads WHERE phone = ?',
      [phone]
    );
    if (existingLeads.length > 0) {
      return res.status(409).json({ error: 'Lead with this phone number already exists' });
    }
    const [result] = await db.query(
      'INSERT INTO leads (name, phone, email,source,status) VALUES (?, ?, ?, ?, ?)',
      [name, phone, email, source, status]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

//update leads
exports.updateLead = async (req, res) => {
  const fields = [];
  const values = [];

  if (req.body.name !== undefined) { fields.push('name = ?'); values.push(req.body.name);}
  if (req.body.phone !== undefined) { fields.push('phone = ?'); values.push(req.body.phone);}
  if (req.body.email !== undefined) { fields.push('email = ?'); values.push(req.body.email);}
  if (req.body.source !== undefined) { fields.push('source = ?'); values.push(req.body.source);}
  if (req.body.status !== undefined) { fields.push('status = ?'); values.push(req.body.status);}

  if (fields.length === 0) return res.status(400).json({ error: 'No valid fields provided for update' });
  values.push(req.params.id);

  try {
    const sql = `UPDATE leads SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);
    res.json({ message: 'Lead updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE lead
exports.deleteLead = async (req, res) => {
  try {
    await db.query('DELETE FROM leads WHERE id = ?', [req.params.id]);
    res.json({ message: 'Lead deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};