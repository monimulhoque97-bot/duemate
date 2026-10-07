const express = require('express');

const router = express.Router();

const pool = require('../config/database');

// ============================================================
// CREATE NOTIFICATION
// POST /api/notifications
// ============================================================
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      title,
      message,
      type = 'general',
    } = req.body;

    if (!user_id) {
      return res.status(400).json({
        message: 'user_id is required',
      });
    }

    if (!title || title.trim() === '') {
      return res.status(400).json({
        message: 'title is required',
      });
    }

    const [result] = await db.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type
      )
      VALUES (?, ?, ?, ?)
      `,
      [
        user_id,
        title.trim(),
        message ?? null,
        type,
      ],
    );

    const [rows] = await db.query(
      `
      SELECT *
      FROM notifications
      WHERE id = ?
      `,
      [result.insertId],
    );

    return res.status(201).json({
      message: 'Notification created successfully',
      notification: rows[0],
    });
  } catch (error) {
    console.error('Create notification error:', error);

    return res.status(500).json({
      message: 'Failed to create notification',
      error: error.message,
    });
  }
});

// ============================================================
// GET USER NOTIFICATIONS
// GET /api/notifications/user/:userId
// ============================================================
router.get('/user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const [rows] = await db.query(
      `
      SELECT *
      FROM notifications
      WHERE user_id = ?
      ORDER BY created_at DESC
      `,
      [userId],
    );

    return res.status(200).json({
      notifications: rows,
    });
  } catch (error) {
    console.error('Get notifications error:', error);

    return res.status(500).json({
      message: 'Failed to load notifications',
      error: error.message,
    });
  }
});

// ============================================================
// GET UNREAD NOTIFICATIONS
// GET /api/notifications/user/:userId/unread
// ============================================================
router.get(
  '/user/:userId/unread',
  async (req, res) => {
    try {
      const userId = req.params.userId;

      const [rows] = await db.query(
        `
        SELECT *
        FROM notifications
        WHERE user_id = ?
          AND is_read = FALSE
        ORDER BY created_at DESC
        `,
        [userId],
      );

      return res.status(200).json({
        notifications: rows,
        unread_count: rows.length,
      });
    } catch (error) {
      console.error(
        'Get unread notifications error:',
        error,
      );

      return res.status(500).json({
        message: 'Failed to load unread notifications',
        error: error.message,
      });
    }
  },
);

// ============================================================
// GET SINGLE NOTIFICATION
// GET /api/notifications/:id
// ============================================================
router.get('/:id', async (req, res) => {
  try {
    const notificationId = req.params.id;

    const [rows] = await db.query(
      `
      SELECT *
      FROM notifications
      WHERE id = ?
      `,
      [notificationId],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'Notification not found',
      });
    }

    return res.status(200).json({
      notification: rows[0],
    });
  } catch (error) {
    console.error(
      'Get notification error:',
      error,
    );

    return res.status(500).json({
      message: 'Failed to load notification',
      error: error.message,
    });
  }
});

// ============================================================
// MARK ONE NOTIFICATION AS READ
// PATCH /api/notifications/:id/read
// ============================================================
router.patch('/:id/read', async (req, res) => {
  try {
    const notificationId = req.params.id;

    const [result] = await db.query(
      `
      UPDATE notifications
      SET is_read = TRUE
      WHERE id = ?
      `,
      [notificationId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Notification not found',
      });
    }

    const [rows] = await db.query(
      `
      SELECT *
      FROM notifications
      WHERE id = ?
      `,
      [notificationId],
    );

    return res.status(200).json({
      message: 'Notification marked as read',
      notification: rows[0],
    });
  } catch (error) {
    console.error(
      'Mark notification read error:',
      error,
    );

    return res.status(500).json({
      message: 'Failed to mark notification as read',
      error: error.message,
    });
  }
});

// ============================================================
// MARK ALL NOTIFICATIONS AS READ
// PATCH /api/notifications/user/:userId/read-all
// ============================================================
router.patch(
  '/user/:userId/read-all',
  async (req, res) => {
    try {
      const userId = req.params.userId;

      await db.query(
        `
        UPDATE notifications
        SET is_read = TRUE
        WHERE user_id = ?
          AND is_read = FALSE
        `,
        [userId],
      );

      return res.status(200).json({
        message: 'All notifications marked as read',
      });
    } catch (error) {
      console.error(
        'Mark all notifications read error:',
        error,
      );

      return res.status(500).json({
        message:
            'Failed to mark all notifications as read',
        error: error.message,
      });
    }
  },
);

// ============================================================
// DELETE ONE NOTIFICATION
// DELETE /api/notifications/:id
// ============================================================
router.delete('/:id', async (req, res) => {
  try {
    const notificationId = req.params.id;

    const [result] = await db.query(
      `
      DELETE FROM notifications
      WHERE id = ?
      `,
      [notificationId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Notification not found',
      });
    }

    return res.status(200).json({
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    console.error(
      'Delete notification error:',
      error,
    );

    return res.status(500).json({
      message: 'Failed to delete notification',
      error: error.message,
    });
  }
});

// ============================================================
// DELETE ALL USER NOTIFICATIONS
// DELETE /api/notifications/user/:userId
// ============================================================
router.delete(
  '/user/:userId',
  async (req, res) => {
    try {
      const userId = req.params.userId;

      await db.query(
        `
        DELETE FROM notifications
        WHERE user_id = ?
        `,
        [userId],
      );

      return res.status(200).json({
        message: 'All notifications deleted successfully',
      });
    } catch (error) {
      console.error(
        'Delete all notifications error:',
        error,
      );

      return res.status(500).json({
        message:
            'Failed to delete all notifications',
        error: error.message,
      });
    }
  },
);

module.exports = router;