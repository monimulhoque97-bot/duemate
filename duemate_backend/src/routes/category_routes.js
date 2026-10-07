const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// ============================================================
// GET ALL CATEGORIES FOR USER
// ============================================================

router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        icon,
        color,
        type,
        created_at
      FROM categories
      WHERE user_id = ?
      ORDER BY type ASC, name ASC`,
      [userId]
    );

    res.status(200).json({
      categories: rows,
    });
  } catch (error) {
    console.error('Get categories error:', error);

    res.status(500).json({
      message: 'Failed to get categories',
      error: error.message,
    });
  }
});

// ============================================================
// GET SINGLE CATEGORY
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        icon,
        color,
        type,
        created_at
      FROM categories
      WHERE id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Category not found',
      });
    }

    res.status(200).json({
      category: rows[0],
    });
  } catch (error) {
    console.error('Get category error:', error);

    res.status(500).json({
      message: 'Failed to get category',
      error: error.message,
    });
  }
});

// ============================================================
// CREATE CATEGORY
// ============================================================

router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      name,
      icon,
      color,
      type,
    } = req.body;

    if (!user_id || !name) {
      return res.status(400).json({
        message: 'user_id and name are required',
      });
    }

    const categoryType = type || 'expense';

    if (!['expense', 'income'].includes(categoryType)) {
      return res.status(400).json({
        message: 'Type must be expense or income',
      });
    }

    const trimmedName = name.toString().trim();

    if (!trimmedName) {
      return res.status(400).json({
        message: 'Category name cannot be empty',
      });
    }

    // Check whether user exists
    const [user] = await pool.execute(
      `SELECT id
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [user_id]
    );

    if (user.length === 0) {
      return res.status(404).json({
        message: 'User not found',
      });
    }

    // Prevent duplicate category names
    // for the same user and type.
    const [existing] = await pool.execute(
      `SELECT id
       FROM categories
       WHERE user_id = ?
         AND LOWER(name) = LOWER(?)
         AND type = ?
       LIMIT 1`,
      [
        user_id,
        trimmedName,
        categoryType,
      ]
    );

    if (existing.length > 0) {
      return res.status(409).json({
        message: 'A category with this name already exists',
      });
    }

    const [result] = await pool.execute(
      `INSERT INTO categories
      (
        user_id,
        name,
        icon,
        color,
        type
      )
      VALUES (?, ?, ?, ?, ?)`,
      [
        user_id,
        trimmedName,
        icon || 'category',
        color || '19A974',
        categoryType,
      ]
    );

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        icon,
        color,
        type,
        created_at
      FROM categories
      WHERE id = ?`,
      [result.insertId]
    );

    res.status(201).json({
      message: 'Category created successfully',
      category: rows[0],
    });
  } catch (error) {
    console.error('Create category error:', error);

    res.status(500).json({
      message: 'Failed to create category',
      error: error.message,
    });
  }
});

// ============================================================
// UPDATE CATEGORY
// ============================================================

router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      name,
      icon,
      color,
      type,
    } = req.body;

    if (!name) {
      return res.status(400).json({
        message: 'Category name is required',
      });
    }

    const trimmedName = name.toString().trim();

    if (!trimmedName) {
      return res.status(400).json({
        message: 'Category name cannot be empty',
      });
    }

    // Get existing category
    const [existingCategory] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        icon,
        color,
        type
      FROM categories
      WHERE id = ?`,
      [id]
    );

    if (existingCategory.length === 0) {
      return res.status(404).json({
        message: 'Category not found',
      });
    }

    const existing = existingCategory[0];

    const updatedType = type || existing.type;

    if (!['expense', 'income'].includes(updatedType)) {
      return res.status(400).json({
        message: 'Type must be expense or income',
      });
    }

    // Prevent duplicate category names
    // for the same user and type.
    const [duplicate] = await pool.execute(
      `SELECT id
       FROM categories
       WHERE user_id = ?
         AND LOWER(name) = LOWER(?)
         AND type = ?
         AND id != ?
       LIMIT 1`,
      [
        existing.user_id,
        trimmedName,
        updatedType,
        id,
      ]
    );

    if (duplicate.length > 0) {
      return res.status(409).json({
        message: 'A category with this name already exists',
      });
    }

    await pool.execute(
      `UPDATE categories
       SET
         name = ?,
         icon = ?,
         color = ?,
         type = ?
       WHERE id = ?`,
      [
        trimmedName,
        icon || existing.icon || 'category',
        color || existing.color || '19A974',
        updatedType,
        id,
      ]
    );

    const [rows] = await pool.execute(
      `SELECT
        id,
        user_id,
        name,
        icon,
        color,
        type,
        created_at
      FROM categories
      WHERE id = ?`,
      [id]
    );

    res.status(200).json({
      message: 'Category updated successfully',
      category: rows[0],
    });
  } catch (error) {
    console.error('Update category error:', error);

    res.status(500).json({
      message: 'Failed to update category',
      error: error.message,
    });
  }
});

// ============================================================
// DELETE CATEGORY
// ============================================================

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Check category
    const [category] = await pool.execute(
      `SELECT
        id,
        user_id
      FROM categories
      WHERE id = ?`,
      [id]
    );

    if (category.length === 0) {
      return res.status(404).json({
        message: 'Category not found',
      });
    }

    // Remove category reference from transactions
    await pool.execute(
      `UPDATE transactions
       SET category_id = NULL
       WHERE category_id = ?`,
      [id]
    );

    const [result] = await pool.execute(
      `DELETE FROM categories
       WHERE id = ?`,
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Category not found',
      });
    }

    res.status(200).json({
      message: 'Category deleted successfully',
    });
  } catch (error) {
    console.error('Delete category error:', error);

    res.status(500).json({
      message: 'Failed to delete category',
      error: error.message,
    });
  }
});

module.exports = router;