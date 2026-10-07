const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// Create EMI
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      name,
      lender_name,
      total_amount,
      monthly_amount,
      interest_rate,
      total_installments,
      start_date,
      due_day,
    } = req.body;

    if (
      !user_id ||
      !name ||
      total_amount === undefined ||
      monthly_amount === undefined ||
      !total_installments ||
      !start_date ||
      !due_day
    ) {
      return res.status(400).json({
        message:
          'user_id, name, total_amount, monthly_amount, total_installments, start_date and due_day are required',
      });
    }

    if (Number(total_amount) <= 0) {
      return res.status(400).json({
        message: 'Total amount must be greater than 0',
      });
    }

    if (Number(monthly_amount) <= 0) {
      return res.status(400).json({
        message: 'Monthly amount must be greater than 0',
      });
    }

    if (Number(total_installments) <= 0) {
      return res.status(400).json({
        message: 'Total installments must be greater than 0',
      });
    }

    if (Number(due_day) < 1 || Number(due_day) > 31) {
      return res.status(400).json({
        message: 'Due day must be between 1 and 31',
      });
    }

    const [result] = await pool.execute(
      `INSERT INTO emis
      (
        user_id,
        name,
        lender_name,
        total_amount,
        monthly_amount,
        interest_rate,
        total_installments,
        paid_installments,
        start_date,
        due_day,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        user_id,
        name,
        lender_name || null,
        total_amount,
        monthly_amount,
        interest_rate || 0,
        total_installments,
        0,
        start_date,
        due_day,
        'active',
      ],
    );

    res.status(201).json({
      message: 'EMI created successfully',
      emi_id: result.insertId,
    });
  } catch (error) {
    console.error('Create EMI error:', error.message);

    res.status(500).json({
      message: 'Failed to create EMI',
    });
  }
});

// Get all EMIs for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        lender_name,
        total_amount,
        monthly_amount,
        interest_rate,
        total_installments,
        paid_installments,
        start_date,
        due_day,
        status,
        created_at,
        updated_at
      FROM emis
      WHERE user_id = ?
      ORDER BY due_day ASC, id DESC`,
      [userId],
    );

    res.json({
      emis: rows,
    });
  } catch (error) {
    console.error('Get EMIs error:', error.message);

    res.status(500).json({
      message: 'Failed to get EMIs',
    });
  }
});

// Get single EMI
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        lender_name,
        total_amount,
        monthly_amount,
        interest_rate,
        total_installments,
        paid_installments,
        start_date,
        due_day,
        status,
        created_at,
        updated_at
      FROM emis
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'EMI not found',
      });
    }

    res.json({
      emi: rows[0],
    });
  } catch (error) {
    console.error('Get EMI error:', error.message);

    res.status(500).json({
      message: 'Failed to get EMI',
    });
  }
});

// Mark one EMI installment as paid
router.put('/:id/pay', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        total_installments,
        paid_installments,
        status
      FROM emis
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'EMI not found',
      });
    }

    const emi = rows[0];

    if (emi.status === 'completed') {
      return res.status(400).json({
        message: 'This EMI is already completed',
      });
    }

    const newPaidInstallments = Number(emi.paid_installments) + 1;

    let newStatus = 'active';

    if (newPaidInstallments >= Number(emi.total_installments)) {
      newStatus = 'completed';
    }

    await pool.execute(
      `UPDATE emis
       SET paid_installments = ?,
           status = ?
       WHERE id = ?`,
      [
        newPaidInstallments,
        newStatus,
        id,
      ],
    );

    res.json({
      message: 'EMI installment marked as paid',
      paid_installments: newPaidInstallments,
      status: newStatus,
    });
  } catch (error) {
    console.error('Pay EMI error:', error.message);

    res.status(500).json({
      message: 'Failed to update EMI payment',
    });
  }
});

// Update EMI
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      name,
      lender_name,
      total_amount,
      monthly_amount,
      interest_rate,
      total_installments,
      start_date,
      due_day,
      status,
    } = req.body;

    if (!name) {
      return res.status(400).json({
        message: 'EMI name is required',
      });
    }

    if (!['active', 'completed', 'paused'].includes(status)) {
      return res.status(400).json({
        message: 'Invalid EMI status',
      });
    }

    const [result] = await pool.execute(
      `UPDATE emis
       SET name = ?,
           lender_name = ?,
           total_amount = ?,
           monthly_amount = ?,
           interest_rate = ?,
           total_installments = ?,
           start_date = ?,
           due_day = ?,
           status = ?
       WHERE id = ?`,
      [
        name,
        lender_name || null,
        total_amount,
        monthly_amount,
        interest_rate || 0,
        total_installments,
        start_date,
        due_day,
        status,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'EMI not found',
      });
    }

    res.json({
      message: 'EMI updated successfully',
    });
  } catch (error) {
    console.error('Update EMI error:', error.message);

    res.status(500).json({
      message: 'Failed to update EMI',
    });
  }
});

// Delete EMI
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      'DELETE FROM emis WHERE id = ?',
      [id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'EMI not found',
      });
    }

    res.json({
      message: 'EMI deleted successfully',
    });
  } catch (error) {
    console.error('Delete EMI error:', error.message);

    res.status(500).json({
      message: 'Failed to delete EMI',
    });
  }
});

module.exports = router;