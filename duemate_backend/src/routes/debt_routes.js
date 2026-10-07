const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// Create debt
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      person_name,
      type,
      total_amount,
      paid_amount,
      due_date,
      status,
      note,
    } = req.body;

    if (!user_id || !person_name || !type || total_amount === undefined) {
      return res.status(400).json({
        message:
          'user_id, person_name, type and total_amount are required',
      });
    }

    if (!['borrowed', 'lent'].includes(type)) {
      return res.status(400).json({
        message: 'Type must be borrowed or lent',
      });
    }

    const totalAmount = Number(total_amount);
    const paidAmount = paid_amount === undefined
      ? 0
      : Number(paid_amount);

    if (!Number.isFinite(totalAmount) || totalAmount <= 0) {
      return res.status(400).json({
        message: 'Total amount must be greater than 0',
      });
    }

    if (!Number.isFinite(paidAmount) || paidAmount < 0) {
      return res.status(400).json({
        message: 'Paid amount cannot be negative',
      });
    }

    if (paidAmount > totalAmount) {
      return res.status(400).json({
        message: 'Paid amount cannot be greater than total amount',
      });
    }

    const finalStatus =
      status && ['active', 'settled', 'overdue'].includes(status)
        ? status
        : 'active';

    const [result] = await pool.execute(
      `INSERT INTO debts
      (
        user_id,
        person_name,
        type,
        total_amount,
        paid_amount,
        due_date,
        status,
        note
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        user_id,
        person_name.trim(),
        type,
        totalAmount,
        paidAmount,
        due_date || null,
        finalStatus,
        note?.trim() || null,
      ],
    );

    res.status(201).json({
      message: 'Debt created successfully',
      debt_id: result.insertId,
    });
  } catch (error) {
    console.error('Create debt error:', error.message);

    res.status(500).json({
      message: 'Failed to create debt',
    });
  }
});

// Get all debts for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        person_name,
        type,
        total_amount,
        paid_amount,
        (total_amount - paid_amount) AS remaining_amount,
        due_date,
        status,
        note,
        created_at,
        updated_at
      FROM debts
      WHERE user_id = ?
      ORDER BY
        CASE
          WHEN status = 'active' THEN 1
          WHEN status = 'overdue' THEN 2
          ELSE 3
        END,
        due_date ASC,
        id DESC`,
      [userId],
    );

    res.json({
      debts: rows,
    });
  } catch (error) {
    console.error('Get debts error:', error.message);

    res.status(500).json({
      message: 'Failed to get debts',
    });
  }
});

// Get single debt
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        person_name,
        type,
        total_amount,
        paid_amount,
        (total_amount - paid_amount) AS remaining_amount,
        due_date,
        status,
        note,
        created_at,
        updated_at
      FROM debts
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Debt not found',
      });
    }

    res.json({
      debt: rows[0],
    });
  } catch (error) {
    console.error('Get debt error:', error.message);

    res.status(500).json({
      message: 'Failed to get debt',
    });
  }
});

// Update debt
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      person_name,
      type,
      total_amount,
      paid_amount,
      due_date,
      status,
      note,
    } = req.body;

    if (!person_name || !type || total_amount === undefined) {
      return res.status(400).json({
        message:
          'person_name, type and total_amount are required',
      });
    }

    if (!['borrowed', 'lent'].includes(type)) {
      return res.status(400).json({
        message: 'Type must be borrowed or lent',
      });
    }

    const totalAmount = Number(total_amount);
    const paidAmount = paid_amount === undefined
      ? 0
      : Number(paid_amount);

    if (!Number.isFinite(totalAmount) || totalAmount <= 0) {
      return res.status(400).json({
        message: 'Total amount must be greater than 0',
      });
    }

    if (!Number.isFinite(paidAmount) || paidAmount < 0) {
      return res.status(400).json({
        message: 'Paid amount cannot be negative',
      });
    }

    if (paidAmount > totalAmount) {
      return res.status(400).json({
        message: 'Paid amount cannot be greater than total amount',
      });
    }

    if (
      status &&
      !['active', 'settled', 'overdue'].includes(status)
    ) {
      return res.status(400).json({
        message: 'Invalid debt status',
      });
    }

    const finalStatus =
      status ||
      (paidAmount >= totalAmount ? 'settled' : 'active');

    const [result] = await pool.execute(
      `UPDATE debts
      SET
        person_name = ?,
        type = ?,
        total_amount = ?,
        paid_amount = ?,
        due_date = ?,
        status = ?,
        note = ?
      WHERE id = ?`,
      [
        person_name.trim(),
        type,
        totalAmount,
        paidAmount,
        due_date || null,
        finalStatus,
        note?.trim() || null,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Debt not found',
      });
    }

    res.json({
      message: 'Debt updated successfully',
    });
  } catch (error) {
    console.error('Update debt error:', error.message);

    res.status(500).json({
      message: 'Failed to update debt',
    });
  }
});

// Mark debt as settled
router.patch('/:id/settle', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT total_amount
       FROM debts
       WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Debt not found',
      });
    }

    const [result] = await pool.execute(
      `UPDATE debts
       SET
         paid_amount = total_amount,
         status = 'settled'
       WHERE id = ?`,
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Debt not found',
      });
    }

    res.json({
      message: 'Debt settled successfully',
    });
  } catch (error) {
    console.error('Settle debt error:', error.message);

    res.status(500).json({
      message: 'Failed to settle debt',
    });
  }
});

// Delete debt
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      'DELETE FROM debts WHERE id = ?',
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Debt not found',
      });
    }

    res.json({
      message: 'Debt deleted successfully',
    });
  } catch (error) {
    console.error('Delete debt error:', error.message);

    res.status(500).json({
      message: 'Failed to delete debt',
    });
  }
});

module.exports = router;