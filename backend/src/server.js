const app = require('./app');
const pool = require('./config/database');
const env = require('./config/env');

async function start() {
  await pool.query('SELECT 1');
  app.listen(env.port, () => {
    console.log(`Waka API listening on http://localhost:${env.port}`);
  });
}

start().catch((error) => {
  console.error('Cannot start Waka API:', error.message);
  process.exitCode = 1;
});
