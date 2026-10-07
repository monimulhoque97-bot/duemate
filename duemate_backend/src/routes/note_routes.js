const express = require('express');
const router = express.Router();

const pool = require('../config/database');

// ============================================================
// CREATE NOTE
// POST /api/notes
// ============================================================
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      title,
      content,
      pinned = false,
    } = req.body;

    if (!user_id) {
      return res.status(400).json({
        message: 'user_id is required',
      });
    }

    if (!title || title.trim().isEmpty) {
      return res.status(400).json({
        message: 'title is required',
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO notes (
        user_id,
        title,
        content,
        pinned
      )
      VALUES (?, ?, ?, ?)
      `,
      [
        user_id,
        title.trim(),
        content ?? null,
        pinned ? 1 : 0,
      ],
    );

    const [rows] = await db.query(
      `
      SELECT *
      FROM notes
      WHERE id = ?
      `,
      [result.insertId],
    );

    return res.status(201).json({
      message: 'Note created successfully',
      note: rows[0],
    });
  } catch (error) {
    console.error('Create note error:', error);

    return res.status(500).json({
      message: 'Failed to create note',
      error: error.message,
    });
  }
});

// ============================================================
// GET ALL NOTES FOR USER
// GET /api/notes/user/:userId
// ============================================================
router.get('/user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const [rows] = await db.query(
      `
      SELECT *
      FROM notes
      WHERE user_id = ?
      ORDER BY pinned DESC, updated_at DESC
      `,
      [userId],
    );

    return res.status(200).json({
      notes: rows,
    });
  } catch (error) {
    console.error('Get notes error:', error);

    return res.status(500).json({
      message: 'Failed to load notes',
      error: error.message,
    });
  }
});

// ============================================================
// GET SINGLE NOTE
// GET /api/notes/:id
// ============================================================
router.get('/:id', async (req, res) => {
  try {
    const noteId = req.params.id;

    const [rows] = await db.query(
      `
      SELECT *
      FROM notes
      WHERE id = ?
      `,
      [noteId],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Note not found',
      });
    }

    return res.status(200).json({
      note: rows[0],
    });
  } catch (error) {
    console.error('Get note error:', error);

    return res.status(500).json({
      message: 'Failed to load note',
      error: error.message,
    });
  }
});

// ============================================================
// UPDATE NOTE
// PUT /api/notes/:id
// ============================================================
router.put('/:id', async (req, res) => {
  try {
    const noteId = req.params.id;

    const {
      title,
      content,
      pinned,
    } = req.body;

    if (!title || title.trim().isEmpty) {
      return res.status(400).json({
        message: 'title is required',
      });
    }

    const [result] = await db.query(
      `
      UPDATE notes
      SET
        title = ?,
        content = ?,
        pinned = ?
      WHERE id = ?
      `,
      [
        title.trim(),
        content ?? null,
        pinned ? 1 : 0,
        noteId,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Note not found',
      });
    }

    const [rows] = await db.query(
      `
      SELECT *
      FROM notes
      WHERE id = ?
      `,
      [noteId],
    );

    return res.status(200).json({
      message: 'Note updated successfully',
      note: rows[0],
    });
  } catch (error) {
    console.error('Update note error:', error);

    return res.status(500).json({
      message: 'Failed to update note',
      error: error.message,
    });
  }
});

// ============================================================
// TOGGLE PIN
// PATCH /api/notes/:id/pin
// ============================================================
router.patch('/:id/pin', async (req, res) => {
  try {
    const noteId = req.params.id;

    const [rows] = await db.query(
      `
      SELECT pinned
      FROM notes
      WHERE id = ?
      `,
      [noteId],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Note not found',
      });
    }

    const newPinnedValue = rows[0].pinned ? 0 : 1;

    await db.query(
      `
      UPDATE notes
      SET pinned = ?
      WHERE id = ?
      `,
      [newPinnedValue, noteId],
    );

    const [updatedRows] = await db.query(
      `
      SELECT *
      FROM notes
      WHERE id = ?
      `,
      [noteId],
    );

    return res.status(200).json({
      message: newPinnedValue
        ? 'Note pinned successfully'
        : 'Note unpinned successfully',
      note: updatedRows[0],
    });
  } catch (error) {
    console.error('Toggle note pin error:', error);

    return res.status(500).json({
      message: 'Failed to update note pin',
      error: error.message,
    });
  }
});

// ============================================================
// DELETE NOTE
// DELETE /api/notes/:id
// ============================================================
router.delete('/:id', async (req, res) => {
  try {
    const noteId = req.params.id;

    const [result] = await db.query(
      `
      DELETE FROM notes
      WHERE id = ?
      `,
      [noteId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Note not found',
      });
    }

    return res.status(200).json({
      message: 'Note deleted successfully',
    });
  } catch (error) {
    console.error('Delete note error:', error);

    return res.status(500).json({
      message: 'Failed to delete note',
      error: error.message,
    });
  }
});

module.exports = router;