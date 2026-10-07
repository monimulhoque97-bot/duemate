const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// =========================================================
// GET ALL BILLS FOR A USER
// =========================================================

router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        provider,
        amount,
        frequency,
        due_date,
        auto_repeat,
        status,
        notes,
        created_at,
        updated_at
      FROM bills
      WHERE user_id = ?
      ORDER BY due_date ASC`,
      [userId],
    );

    res.json({
      bills: rows,
    });
  } catch (error) {
    console.error('Get bills error:', error.message);

    res.status(500).json({
      message: 'Failed to get bills',
    });
  }
});

// =========================================================
// GET SINGLE BILL
// =========================================================

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        provider,
        amount,
        frequency,
        due_date,
        auto_repeat,
        status,
        notes,
        created_at,
        updated_at
      FROM bills
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Bill not found',
      });
    }

    res.json({
      bill: rows[0],
    });
  } catch (error) {
    console.error('Get bill error:', error.message);

    res.status(500).json({
      message: 'Failed to get bill',
    });
  }
});

// =========================================================
// CREATE BILL
// =========================================================

router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      name,
      provider,
      amount,
      frequency,
      due_date,
      auto_repeat,
      status,
      notes,
    } = req.body;

    if (!user_id) {
      return res.status(400).json({
        message: 'User ID is required',
      });
    }

    if (!name || !name.trim()) {
      return res.status(400).json({
        message: 'Bill name is required',
      });
    }

    if (amount === undefined || amount === null || Number(amount) <= 0) {
      return res.status(400).json({
        message: 'Valid amount is required',
      });
    }

    const allowedFrequencies = [
      'once',
      'weekly',
      'monthly',
      'yearly',
    ];

    const selectedFrequency = frequency || 'monthly';

    if (!allowedFrequencies.includes(selectedFrequency)) {
      return res.status(400).json({
        message: 'Invalid frequency',
      });
    }

    if (!due_date) {
      return res.status(400).json({
        message: 'Due date is required',
      });
    }

    const selectedStatus = status || 'active';

    const allowedStatuses = [
      'active',
      'paid',
      'cancelled',
    ];

    if (!allowedStatuses.includes(selectedStatus)) {
      return res.status(400).json({
        message: 'Invalid bill status',
      });
    }

    const [result] = await pool.execute(
      `INSERT INTO bills (
        user_id,
        name,
        provider,
        amount,
        frequency,
        due_date,
        auto_repeat,
        status,
        notes
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        user_id,
        name.trim(),
        provider?.trim() || null,
        Number(amount),
        selectedFrequency,
        due_date,
        auto_repeat === undefined ? 1 : auto_repeat ? 1 : 0,
        selectedStatus,
        notes?.trim() || null,
      ],
    );

    res.status(201).json({
      message: 'Bill created successfully',
      bill_id: result.insertId,
    });
  } catch (error) {
    console.error('Create bill error:', error.message);

    res.status(500).json({
      message: 'Failed to create bill',
    });
  }
});

// =========================================================
// UPDATE BILL
// =========================================================

router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      name,
      provider,
      amount,
      frequency,
      due_date,
      auto_repeat,
      status,
      notes,
    } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        message: 'Bill name is required',
      });
    }

    if (amount === undefined || amount === null || Number(amount) <= 0) {
      return res.status(400).json({
        message: 'Valid amount is required',
      });
    }

    const allowedFrequencies = [
      'once',
      'weekly',
      'monthly',
      'yearly',
    ];

    if (!allowedFrequencies.includes(frequency)) {
      return res.status(400).json({
        message: 'Invalid frequency',
      });
    }

    const allowedStatuses = [
      'active',
      'paid',
      'cancelled',
    ];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: 'Invalid bill status',
      });
    }

    const [result] = await pool.execute(
      `UPDATE bills
       SET
        name = ?,
        provider = ?,
        amount = ?,
        frequency = ?,
        due_date = ?,
        auto_repeat = ?,
        status = ?,
        notes = ?
       WHERE id = ?`,
      [
        name.trim(),
        provider?.trim() || null,
        Number(amount),
        frequency,
        due_date,
        auto_repeat ? 1 : 0,
        status,
        notes?.trim() || null,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Bill not found',
      });
    }

    res.json({
      message: 'Bill updated successfully',
    });
  } catch (error) {
    console.error('Update bill error:', error.message);

    res.status(500).json({
      message: 'Failed to update bill',
    });
  }
});

// =========================================================
// MARK BILL AS PAID
// =========================================================

router.patch('/:id/pay', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      `UPDATE bills
       SET status = 'paid'
       WHERE id = ?`,
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Bill not found',
      });
    }

    res.json({
      message: 'Bill marked as paid',
    });
  } catch (error) {
    console.error('Mark bill paid error:', error.message);

    res.status(500).json({
      message: 'Failed to mark bill as paid',
    });
  }
});

// =========================================================
// DELETE BILL
// =========================================================

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      `DELETE FROM bills
       WHERE id = ?`,
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Bill not found',
      });
    }

    res.json({
      message: 'Bill deleted successfully',
    });
  } catch (error) {
    console.error('Delete bill error:', error.message);

    res.status(500).json({
      message: 'Failed to delete bill',
    });
  }
});

module.exports = router;