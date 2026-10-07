const express = require('express');
const crypto = require('crypto');
const pool = require('../config/database');

const router = express.Router();

const PASSCODE_HASH_PREFIX = 'sha256:';

function normalizePasscode(passcode) {
  return String(passcode ?? '').trim();
}

function hashPasscode(passcode) {
  return (
    PASSCODE_HASH_PREFIX +
    crypto.createHash('sha256').update(passcode).digest('hex')
  );
}

function isValidPasscode(passcode) {
  return /^\d{6}$/.test(passcode);
}

function verifyPasscode(passcode, storedPasscode) {
  if (!storedPasscode) return false;

  const hashed = hashPasscode(passcode);

  if (storedPasscode === hashed) {
    return true;
  }

  // Supports an older/plain passcode if one was ever stored.
  return storedPasscode === passcode;
}

// ============================================================
// CREATE USER
// ============================================================

router.post('/', async (req, res) => {
  try {
    const {
      full_name,
      phone,
      email,
      profile_image,
      currency,
      passcode,
    } = req.body;

    if (!full_name) {
      return res.status(400).json({
        message: 'Full name is required',
      });
    }

    if (!phone) {
      return res.status(400).json({
        message: 'Phone number is required',
      });
    }

    const normalizedPasscode = normalizePasscode(passcode);

    if (!isValidPasscode(normalizedPasscode)) {
      return res.status(400).json({
        message: 'A 6-digit passcode is required',
      });
    }

    const [existingUsers] = await pool.execute(
      'SELECT id FROM users WHERE phone = ? LIMIT 1',
      [phone],
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        message: 'This phone number is already registered. Please login.',
      });
    }

    const hashedPasscode = hashPasscode(normalizedPasscode);

    const [result] = await pool.execute(
      `INSERT INTO users
      (full_name, phone, email, profile_image, currency, passcode)
      VALUES (?, ?, ?, ?, ?, ?)`,
      [
        full_name,
        phone,
        email || null,
        profile_image || null,
        currency || 'INR',
        hashedPasscode,
      ],
    );

    res.status(201).json({
      message: 'User created successfully',
      user_id: result.insertId,
    });
  } catch (error) {
    console.error('Create user error:', error.message);

    res.status(500).json({
      message: 'Failed to create user',
    });
  }
});

// ============================================================
// LOGIN WITH PHONE + PASSCODE
// ============================================================

router.post('/login', async (req, res) => {
  try {
    const { phone, passcode } = req.body;
    const normalizedPasscode = normalizePasscode(passcode);

    if (!phone) {
      return res.status(400).json({
        message: 'Phone number is required',
      });
    }

    if (!isValidPasscode(normalizedPasscode)) {
      return res.status(400).json({
        message: 'A 6-digit passcode is required',
      });
    }

    const [rows] = await pool.execute(
      `SELECT
        id,
        full_name,
        phone,
        email,
        profile_image,
        currency,
        passcode
      FROM users
      WHERE phone = ?
      LIMIT 1`,
      [phone],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'No account found. Please register first.',
      });
    }

    const user = rows[0];

    if (!verifyPasscode(normalizedPasscode, user.passcode)) {
      return res.status(401).json({
        message: 'Incorrect passcode. Please try again.',
      });
    }

    delete user.passcode;

    res.status(200).json({
      message: 'Login successful',
      user,
    });
  } catch (error) {
    console.error('Login error:', error.message);

    res.status(500).json({
      message: 'Login failed',
    });
  }
});

// ============================================================
// FORGOT PASSCODE
// PHONE OR EMAIL REQUIRED
// ============================================================

router.put('/forgot-passcode', async (req, res) => {
  try {
    const phone = String(req.body.phone ?? '').trim();
    const email = String(req.body.email ?? '').trim().toLowerCase();
    const newPasscode = normalizePasscode(req.body.newPasscode);

    // At least phone OR email must be provided.
    if (!phone && !email) {
      return res.status(400).json({
        message: 'Phone number or email is required',
      });
    }

    if (!isValidPasscode(newPasscode)) {
      return res.status(400).json({
        message: 'A 6-digit new passcode is required',
      });
    }

    let rows;

    // Both phone and email provided.
    if (phone && email) {
      const [result] = await pool.execute(
        `SELECT id
         FROM users
         WHERE phone = ? OR LOWER(email) = ?
         LIMIT 1`,
        [phone, email],
      );

      rows = result;
    }

    // Only phone provided.
    else if (phone) {
      const [result] = await pool.execute(
        `SELECT id
         FROM users
         WHERE phone = ?
         LIMIT 1`,
        [phone],
      );

      rows = result;
    }

    // Only email provided.
    else {
      const [result] = await pool.execute(
        `SELECT id
         FROM users
         WHERE LOWER(email) = ?
         LIMIT 1`,
        [email],
      );

      rows = result;
    }

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        message: 'No account found with the provided phone number or email.',
      });
    }

    const hashedPasscode = hashPasscode(newPasscode);

    await pool.execute(
      `UPDATE users
       SET passcode = ?
       WHERE id = ?`,
      [hashedPasscode, rows[0].id],
    );

    return res.status(200).json({
      message: 'Passcode reset successfully',
    });
  } catch (error) {
    console.error('Forgot passcode error:', error.message);

    return res.status(500).json({
      message: 'Failed to reset passcode',
    });
  }
});

// ============================================================
// CHANGE PASSCODE WHILE LOGGED IN
// ============================================================

router.put('/:id/passcode', async (req, res) => {
  try {
    const { id } = req.params;

    const currentPasscode = normalizePasscode(
      req.body.currentPasscode,
    );

    const newPasscode = normalizePasscode(
      req.body.newPasscode,
    );

    if (
      !isValidPasscode(currentPasscode) ||
      !isValidPasscode(newPasscode)
    ) {
      return res.status(400).json({
        message: 'Current and new passcodes must contain exactly 6 digits',
      });
    }

    if (currentPasscode === newPasscode) {
      return res.status(400).json({
        message: 'New passcode must be different from the current passcode',
      });
    }

    const [rows] = await pool.execute(
      `SELECT id, passcode
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'User not found',
      });
    }

    if (!verifyPasscode(currentPasscode, rows[0].passcode)) {
      return res.status(401).json({
        message: 'Current passcode is incorrect',
      });
    }

    const hashedPasscode = hashPasscode(newPasscode);

    await pool.execute(
      `UPDATE users
       SET passcode = ?
       WHERE id = ?`,
      [hashedPasscode, id],
    );

    return res.status(200).json({
      message: 'Passcode changed successfully',
    });
  } catch (error) {
    console.error('Change passcode error:', error.message);

    return res.status(500).json({
      message: 'Failed to change passcode',
    });
  }
});

// ============================================================
// GET USER BY ID
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      `SELECT
        id,
        full_name,
        phone,
        email,
        profile_image,
        currency,
        created_at,
        updated_at
      FROM users
      WHERE id = ?`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'User not found',
      });
    }

    res.status(200).json({
      user: rows[0],
    });
  } catch (error) {
    console.error('Get user error:', error.message);

    res.status(500).json({
      message: 'Failed to get user',
    });
  }
});

// ============================================================
// UPDATE USER
// ============================================================

router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const {
      full_name,
      phone,
      email,
      profile_image,
      currency,
      passcode,
    } = req.body;

    if (!full_name) {
      return res.status(400).json({
        message: 'Full name is required',
      });
    }

    if (!phone) {
      return res.status(400).json({
        message: 'Phone number is required',
      });
    }

    if (passcode !== undefined && passcode !== null) {
      const normalizedPasscode = normalizePasscode(passcode);

      if (!isValidPasscode(normalizedPasscode)) {
        return res.status(400).json({
          message: 'Passcode must contain exactly 6 digits',
        });
      }
    }

    const [existingUsers] = await pool.execute(
      `SELECT id
       FROM users
       WHERE phone = ?
       AND id != ?
       LIMIT 1`,
      [phone, id],
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        message: 'This phone number is already registered to another user.',
      });
    }

    let query;
    let params;

    if (passcode !== undefined && passcode !== null) {
      const normalizedPasscode = normalizePasscode(passcode);
      const hashedPasscode = hashPasscode(normalizedPasscode);

      query = `UPDATE users
       SET full_name = ?,
           phone = ?,
           email = ?,
           profile_image = ?,
           currency = ?,
           passcode = ?
       WHERE id = ?`;

      params = [
        full_name,
        phone,
        email || null,
        profile_image || null,
        currency || 'INR',
        hashedPasscode,
        id,
      ];
    } else {
      query = `UPDATE users
       SET full_name = ?,
           phone = ?,
           email = ?,
           profile_image = ?,
           currency = ?
       WHERE id = ?`;

      params = [
        full_name,
        phone,
        email || null,
        profile_image || null,
        currency || 'INR',
        id,
      ];
    }

    const [result] = await pool.execute(
      query,
      params,
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'User not found',
      });
    }

    res.status(200).json({
      message: 'User updated successfully',
    });
  } catch (error) {
    console.error('Update user error:', error.message);

    res.status(500).json({
      message: 'Failed to update user',
    });
  }
});

module.exports = router;