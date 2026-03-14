const path = require('path');
const Database = require('better-sqlite3');

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'app.db');
const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

const initStatements = [
  `
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    surname TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
  `,
  `
  CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  )
  `,
  `
  CREATE TABLE IF NOT EXISTS portfolios (
    user_id INTEGER PRIMARY KEY,
    cash REAL NOT NULL DEFAULT 100000,
    positions_json TEXT NOT NULL DEFAULT '[]',
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  )
  `,
];

for (const statement of initStatements) {
  db.prepare(statement).run();
}

function sanitizeUser(user) {
  if (!user) return null;

  return {
    id: user.id,
    name: user.name,
    surname: user.surname,
    login: user.login,
    email: user.email,
    createdAt: user.created_at,
  };
}

function ensurePortfolioForUser(userId) {
  db.prepare(
    `
      INSERT INTO portfolios (user_id, cash, positions_json)
      VALUES (?, 100000, '[]')
      ON CONFLICT(user_id) DO NOTHING
    `,
  ).run(userId);
}

function getPortfolioByUserId(userId) {
  ensurePortfolioForUser(userId);

  const row = db
    .prepare('SELECT user_id, cash, positions_json, updated_at FROM portfolios WHERE user_id = ?')
    .get(userId);

  if (!row) {
    return {
      userId,
      cash: 100000,
      positions: [],
      updatedAt: new Date().toISOString(),
    };
  }

  let positions = [];
  try {
    const parsed = JSON.parse(row.positions_json);
    if (Array.isArray(parsed)) {
      positions = parsed;
    }
  } catch (_) {
    positions = [];
  }

  return {
    userId: row.user_id,
    cash: Number(row.cash) || 100000,
    positions,
    updatedAt: row.updated_at,
  };
}

function savePortfolioForUser({ userId, cash, positions }) {
  const positionsJson = JSON.stringify(Array.isArray(positions) ? positions : []);
  const normalizedCash = Number.isFinite(Number(cash)) ? Number(cash) : 100000;

  db.prepare(
    `
      INSERT INTO portfolios (user_id, cash, positions_json, updated_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(user_id)
      DO UPDATE SET
        cash = excluded.cash,
        positions_json = excluded.positions_json,
        updated_at = CURRENT_TIMESTAMP
    `,
  ).run(userId, normalizedCash, positionsJson);

  return getPortfolioByUserId(userId);
}

module.exports = {
  db,
  sanitizeUser,
  ensurePortfolioForUser,
  getPortfolioByUserId,
  savePortfolioForUser,
};
