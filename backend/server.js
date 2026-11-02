require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/database');

const PORT = process.env.PORT || 5000;

// Connect to MongoDB then listen
connectDB()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`[Server] Expense Tracker API running on http://localhost:${PORT}/api/v1`);
      console.log(`[Server] Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  })
  .catch((err) => {
    console.error('[Server] Failed to connect to database. Starting offline:', err.message);
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`[Server] Running in fallback mode on http://localhost:${PORT}/api/v1`);
    });
  });
