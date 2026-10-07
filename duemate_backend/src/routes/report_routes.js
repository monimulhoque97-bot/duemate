const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// ============================================================
// REPORT SUMMARY
// ============================================================

router.get('/user/:userId/summary', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        COALESCE(SUM(
          CASE
            WHEN type = 'income' THEN amount
            ELSE 0
          END
        ), 0) AS total_income,

        COALESCE(SUM(
          CASE
            WHEN type = 'expense' THEN amount
            ELSE 0
          END
        ), 0) AS total_expense,

        COUNT(*) AS total_transactions

      FROM transactions
      WHERE user_id = ?`,
      [userId],
    );

    const result = rows[0];

    const totalIncome =
      Number(result.total_income) || 0;

    const totalExpense =
      Number(result.total_expense) || 0;

    res.json({
      total_income: totalIncome,
      total_expense: totalExpense,
      balance: totalIncome - totalExpense,
      total_transactions:
          Number(result.total_transactions) || 0,
    });
  } catch (error) {
    console.error(
      'Report summary error:',
      error.message,
    );

    res.status(500).json({
      message: 'Failed to load report summary',
    });
  }
});

// ============================================================
// CATEGORY REPORT
// ============================================================

router.get(
  '/user/:userId/categories',
  async (req, res) => {
    try {
      const { userId } = req.params;

      const [rows] = await pool.execute(
        `SELECT
          c.id AS category_id,
          c.name AS category_name,
          c.icon,
          c.color,
          c.type,
          COALESCE(SUM(t.amount), 0) AS total_amount,
          COUNT(t.id) AS transaction_count

        FROM categories c

        LEFT JOIN transactions t
          ON t.category_id = c.id
          AND t.user_id = c.user_id
          AND t.type = 'expense'

        WHERE c.user_id = ?
          AND c.type = 'expense'

        GROUP BY
          c.id,
          c.name,
          c.icon,
          c.color,
          c.type

        ORDER BY total_amount DESC`,
        [userId],
      );

      res.json({
        categories: rows,
      });
    } catch (error) {
      console.error(
        'Category report error:',
        error.message,
      );

      res.status(500).json({
        message:
          'Failed to load category report',
      });
    }
  },
);

// ============================================================
// MONTHLY REPORT
// ============================================================

router.get(
  '/user/:userId/monthly',
  async (req, res) => {
    try {
      const { userId } = req.params;

      const [rows] = await pool.execute(
        `SELECT
          DATE_FORMAT(
            transaction_date,
            '%Y-%m'
          ) AS month,

          COALESCE(SUM(
            CASE
              WHEN type = 'income'
              THEN amount
              ELSE 0
            END
          ), 0) AS income,

          COALESCE(SUM(
            CASE
              WHEN type = 'expense'
              THEN amount
              ELSE 0
            END
          ), 0) AS expense

        FROM transactions

        WHERE user_id = ?

        GROUP BY
          DATE_FORMAT(
            transaction_date,
            '%Y-%m'
          )

        ORDER BY month ASC`,
        [userId],
      );

      const monthly = rows.map((row) => {
        const income =
          Number(row.income) || 0;

        const expense =
          Number(row.expense) || 0;

        return {
          month: row.month,
          income,
          expense,
          balance: income - expense,
        };
      });

      res.json({
        monthly,
      });
    } catch (error) {
      console.error(
        'Monthly report error:',
        error.message,
      );

      res.status(500).json({
        message:
          'Failed to load monthly report',
      });
    }
  },
);

// ============================================================
// WEEKLY REPORT
// ============================================================

router.get(
  '/user/:userId/weekly',
  async (req, res) => {
    try {
      const { userId } = req.params;

      const [rows] = await pool.execute(
        `SELECT
          YEARWEEK(
            transaction_date,
            1
          ) AS week,

          MIN(
            DATE(transaction_date)
          ) AS week_start,

          COALESCE(SUM(
            CASE
              WHEN type = 'income'
              THEN amount
              ELSE 0
            END
          ), 0) AS income,

          COALESCE(SUM(
            CASE
              WHEN type = 'expense'
              THEN amount
              ELSE 0
            END
          ), 0) AS expense

        FROM transactions

        WHERE user_id = ?

        GROUP BY
          YEARWEEK(
            transaction_date,
            1
          )

        ORDER BY week ASC`,
        [userId],
      );

      const weekly = rows.map((row) => {
        const income =
          Number(row.income) || 0;

        const expense =
          Number(row.expense) || 0;

        return {
          week: row.week,
          week_start: row.week_start,
          income,
          expense,
          balance: income - expense,
        };
      });

      res.json({
        weekly,
      });
    } catch (error) {
      console.error(
        'Weekly report error:',
        error.message,
      );

      res.status(500).json({
        message:
          'Failed to load weekly report',
      });
    }
  },
);

// ============================================================
// TOP SPENDING CATEGORIES
// ============================================================

router.get(
  '/user/:userId/top-categories',
  async (req, res) => {
    try {
      const { userId } = req.params;

      const [rows] = await pool.execute(
        `SELECT
          c.id AS category_id,
          c.name AS category_name,
          c.icon,
          c.color,
          COALESCE(
            SUM(t.amount),
            0
          ) AS total_amount,
          COUNT(t.id) AS transaction_count

        FROM transactions t

        LEFT JOIN categories c
          ON c.id = t.category_id

        WHERE t.user_id = ?
          AND t.type = 'expense'

        GROUP BY
          c.id,
          c.name,
          c.icon,
          c.color

        ORDER BY total_amount DESC

        LIMIT 10`,
        [userId],
      );

      res.json({
        categories: rows,
      });
    } catch (error) {
      console.error(
        'Top categories report error:',
        error.message,
      );

      res.status(500).json({
        message:
          'Failed to load top spending categories',
      });
    }
  },
);

// ============================================================
// REPORT FOR CURRENT MONTH
// ============================================================

router.get(
  '/user/:userId/current-month',
  async (req, res) => {
    try {
      const { userId } = req.params;

      const [rows] = await pool.execute(
        `SELECT
          COALESCE(SUM(
            CASE
              WHEN type = 'income'
              THEN amount
              ELSE 0
            END
          ), 0) AS income,

          COALESCE(SUM(
            CASE
              WHEN type = 'expense'
              THEN amount
              ELSE 0
            END
          ), 0) AS expense,

          COUNT(*) AS transactions

        FROM transactions

        WHERE user_id = ?

        AND YEAR(transaction_date)
          = YEAR(CURRENT_DATE())

        AND MONTH(transaction_date)
          = MONTH(CURRENT_DATE())`,
        [userId],
      );

      const income =
        Number(rows[0].income) || 0;

      const expense =
        Number(rows[0].expense) || 0;

      res.json({
        income,
        expense,
        balance: income - expense,
        transactions:
            Number(rows[0].transactions) || 0,
      });
    } catch (error) {
      console.error(
        'Current month report error:',
        error.message,
      );

      res.status(500).json({
        message:
          'Failed to load current month report',
      });
    }
  },
);

module.exports = router;