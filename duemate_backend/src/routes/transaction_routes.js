const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// Create transaction
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      category_id,
      type,
      amount,
      note,
      transaction_date,
    } = req.body;

    if (!user_id || !type || amount === undefined) {
      return res.status(400).json({
        message: 'user_id, type and amount are required',
      });
    }

    if (!['expense', 'income'].includes(type)) {
      return res.status(400).json({
        message: 'Type must be expense or income',
      });
    }

    if (Number(amount) <= 0) {
      return res.status(400).json({
        message: 'Amount must be greater than 0',
      });
    }

    const [result] = await pool.execute(
      `INSERT INTO transactions
      (user_id, category_id, type, amount, note, transaction_date)
      VALUES (?, ?, ?, ?, ?, ?)`,
      [
        user_id,
        category_id || null,
        type,
        amount,
        note || null,
        transaction_date || new Date(),
      ],
    );

    res.status(201).json({
      message: 'Transaction created successfully',
      transaction_id: result.insertId,
    });
  } catch (error) {
    console.error('Create transaction error:', error.message);

    res.status(500).json({
      message: 'Failed to create transaction',
    });
  }
});

// Get all transactions for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        t.id,
        t.user_id,
        t.category_id,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color,
        t.type,
        t.amount,
        t.note,
        t.transaction_date,
        t.created_at,
        t.updated_at
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ?
      ORDER BY t.transaction_date DESC, t.id DESC`,
      [userId],
    );

    res.json({
      transactions: rows,
    });
  } catch (error) {
    console.error('Get transactions error:', error.message);

    res.status(500).json({
      message: 'Failed to get transactions',
    });
  }
});
// Get single transaction
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        category_id,
        type,
        amount,
        note,
        transaction_date,
        created_at,
        updated_at
      FROM transactions
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Transaction not found',
      });
    }

    res.json({
      transaction: rows[0],
    });
  } catch (error) {
    console.error('Get transaction error:', error.message);

    res.status(500).json({
      message: 'Failed to get transaction',
    });
  }
});

// Update transaction
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      category_id,
      type,
      amount,
      note,
      transaction_date,
    } = req.body;

    if (!type || amount === undefined) {
      return res.status(400).json({
        message: 'Type and amount are required',
      });
    }

    if (!['expense', 'income'].includes(type)) {
      return res.status(400).json({
        message: 'Type must be expense or income',
      });
    }

    if (Number(amount) <= 0) {
      return res.status(400).json({
        message: 'Amount must be greater than 0',
      });
    }

    const [result] = await pool.execute(
      `UPDATE transactions
      SET category_id = ?,
          type = ?,
          amount = ?,
          note = ?,
          transaction_date = ?
      WHERE id = ?`,
      [
        category_id || null,
        type,
        amount,
        note || null,
        transaction_date || new Date(),
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Transaction not found',
      });
    }

    res.json({
      message: 'Transaction updated successfully',
    });
  } catch (error) {
    console.error('Update transaction error:', error.message);

    res.status(500).json({
      message: 'Failed to update transaction',
    });
  }
});

// Delete transaction
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      'DELETE FROM transactions WHERE id = ?',
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Transaction not found',
      });
    }

    res.json({
      message: 'Transaction deleted successfully',
    });
  } catch (error) {
    console.error('Delete transaction error:', error.message);

    res.status(500).json({
      message: 'Failed to delete transaction',
    });
  }
});

module.exports = router;