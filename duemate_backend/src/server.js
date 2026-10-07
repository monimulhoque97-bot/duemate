const express = require('express');
const cors = require('cors');
require('dotenv').config();

const pool = require('./config/database');
const userRoutes = require('./routes/user_routes');
const transactionRoutes = require('./routes/transaction_routes');
const emiRoutes = require('./routes/emi_routes');
const debtRoutes = require('./routes/debt_routes');
const billRoutes = require('./routes/bill_routes');
const noteRoutes = require('./routes/note_routes');
const notificationRoutes = require('./routes/notification_routes');
const reportRoutes = require('./routes/report_routes');
const categoryRoutes = require('./routes/category_routes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use('/api/users', userRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/emis', emiRoutes);
app.use('/api/debts', debtRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/categories', categoryRoutes);

app.get('/', (req, res) => {
  res.json({
    message: 'DueMate API is running',
  });
});

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');

    res.json({
      server: 'OK',
      database: 'OK',
    });
  } catch (error) {
    console.error('Database connection error:', error.message);

    res.status(500).json({
      server: 'OK',
      database: 'ERROR',
    });
  }
});

app.listen(PORT, () => {
  console.log(`DueMate API running on http://localhost:${PORT}`);
});