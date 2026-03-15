const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');

dotenv.config();

const app = express();
app.set('trust proxy', 1);

const newsRoute = require('./routes/news_route');
const {
  db,
  ensurePortfolioForUser,
  getPortfolioByUserId,
  sanitizeUser,
  savePortfolioForUser,
} = require('./db');

const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || 'change-me-in-production';
const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || '*';
const YAHOO_TIMEOUT_MS = Number(process.env.YAHOO_TIMEOUT_MS || 15000);

if (JWT_SECRET === 'change-me-in-production') {
  console.warn(
    '[SECURITY] JWT_SECRET is using a default insecure value. Set JWT_SECRET in environment.',
  );
}

app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }),
);

app.use(
  cors({
    origin: CLIENT_ORIGIN === '*' ? true : CLIENT_ORIGIN,
    methods: ['GET', 'POST', 'PUT', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);

app.use(express.json({ limit: '1mb' }));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/v1/auth', authLimiter);

app.use('/api/v1/news', newsRoute);
app.use('/api/v1/yahoo/news', newsRoute);

function normalizeSymbol(symbol) {
  return String(symbol || '').trim().toUpperCase().replace(/\./g, '-');
}

function createJwt(user) {
  return jwt.sign(
    {
      sub: user.id,
      login: user.login,
      email: user.email,
    },
    JWT_SECRET,
    { expiresIn: '7d' },
  );
}

function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = {
      id: Number(payload.sub),
      login: payload.login,
      email: payload.email,
    };
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

function getUserByLoginOrEmail(value) {
  const normalized = String(value || '').trim();
  const normalizedEmail = normalized.toLowerCase();
  return db
    .prepare('SELECT * FROM users WHERE login = ? OR email = ?')
    .get(normalized, normalizedEmail);
}

function yahooHeaders() {
  return {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
    Accept: 'application/json,text/plain,*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    Referer: 'https://finance.yahoo.com/',
    Origin: 'https://finance.yahoo.com',
  };
}

async function fetchYahooJson(url) {
  const abortController = new AbortController();
  const timeout = setTimeout(() => abortController.abort(), YAHOO_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: yahooHeaders(),
      signal: abortController.signal,
    });

    const text = await response.text();

    return {
      ok: response.ok,
      status: response.status,
      text,
      contentType: response.headers.get('content-type') || 'application/json',
    };
  } finally {
    clearTimeout(timeout);
  }
}

function validPassword(password) {
  return typeof password === 'string' && password.length >= 6;
}

function validEmail(email) {
  return /^[\w.+-]+@[\w-]+\.[A-Za-z]{2,}$/.test(String(email || '').trim());
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'gryphone-api',
    timestamp: new Date().toISOString(),
  });
});

app.post('/api/v1/auth/register', (req, res) => {
  const { name, surname, login, email, password } = req.body || {};

  if (!name || !surname || !login || !email || !password) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  if (!validEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  if (!validPassword(password)) {
    return res
      .status(400)
      .json({ error: 'Password must be at least 6 characters' });
  }

  try {
    const passwordHash = bcrypt.hashSync(password, 12);

    const createdUser = db.transaction(() => {
      const result = db
        .prepare(
          `
          INSERT INTO users (name, surname, login, email, password_hash)
          VALUES (?, ?, ?, ?, ?)
          `,
        )
        .run(
          String(name).trim(),
          String(surname).trim(),
          String(login).trim(),
          String(email).trim().toLowerCase(),
          passwordHash,
        );

      ensurePortfolioForUser(result.lastInsertRowid);

      return db.prepare('SELECT * FROM users WHERE id = ?').get(result.lastInsertRowid);
    })();

    const safeUser = sanitizeUser(createdUser);
    const token = createJwt(createdUser);
    const portfolio = getPortfolioByUserId(createdUser.id);

    return res.status(201).json({
      token,
      user: safeUser,
      portfolio,
    });
  } catch (error) {
    if (String(error.message).includes('UNIQUE')) {
      return res.status(409).json({ error: 'Login or email already exists' });
    }
    return res.status(500).json({ error: 'register_error' });
  }
});

app.post('/api/v1/auth/login', (req, res) => {
  const { login, password } = req.body || {};

  if (!login || !password) {
    return res.status(400).json({ error: 'Login and password are required' });
  }

  const user = getUserByLoginOrEmail(login);

  if (!user || !bcrypt.compareSync(String(password), user.password_hash)) {
    return res.status(401).json({ error: 'invalid' });
  }

  ensurePortfolioForUser(user.id);

  return res.json({
    token: createJwt(user),
    user: sanitizeUser(user),
    portfolio: getPortfolioByUserId(user.id),
  });
});

app.post('/api/v1/auth/forgot-password', (req, res) => {
  const { email } = req.body || {};
  const normalizedEmail = String(email || '').trim().toLowerCase();

  if (!normalizedEmail) {
    return res.status(400).json({ error: 'Email is required' });
  }

  const user = db
    .prepare('SELECT id, email FROM users WHERE email = ?')
    .get(normalizedEmail);

  if (!user) {
    return res.status(404).json({ error: 'email_not_found' });
  }

  const token = crypto.randomBytes(24).toString('hex');
  const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();

  db.prepare(
    'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
  ).run(user.id, token, expiresAt);

  return res.json({
    ok: true,
    resetToken: token,
    note: 'In production, send resetToken via secure email provider instead of API response.',
  });
});

app.post('/api/v1/auth/reset-password', (req, res) => {
  const { token, password } = req.body || {};

  if (!token || !password) {
    return res.status(400).json({ error: 'Token and password are required' });
  }

  if (!validPassword(password)) {
    return res
      .status(400)
      .json({ error: 'Password must be at least 6 characters' });
  }

  const row = db
    .prepare('SELECT * FROM password_reset_tokens WHERE token = ?')
    .get(String(token).trim());

  if (!row || new Date(row.expires_at).getTime() < Date.now()) {
    return res.status(400).json({ error: 'Invalid or expired token' });
  }

  const passwordHash = bcrypt.hashSync(String(password), 12);

  db.transaction(() => {
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(
      passwordHash,
      row.user_id,
    );
    db.prepare('DELETE FROM password_reset_tokens WHERE user_id = ?').run(row.user_id);
  })();

  return res.json({ ok: true });
});

app.get('/api/v1/portfolio', authMiddleware, (req, res) => {
  const portfolio = getPortfolioByUserId(req.user.id);
  return res.json(portfolio);
});

app.put('/api/v1/portfolio', authMiddleware, (req, res) => {
  const { cash, positions } = req.body || {};
  const saved = savePortfolioForUser({
    userId: req.user.id,
    cash,
    positions,
  });
  return res.json(saved);
});

app.post('/api/v1/portfolio/reset', authMiddleware, (req, res) => {
  const saved = savePortfolioForUser({
    userId: req.user.id,
    cash: 100000,
    positions: [],
  });
  return res.json(saved);
});

app.get('/api/v1/yahoo/quote', async (req, res) => {
  const symbolsParam = String(req.query.symbols || '').trim();

  if (!symbolsParam) {
    return res.status(400).json({ error: 'symbols is required' });
  }

  const symbols = symbolsParam
    .split(',')
    .map((item) => normalizeSymbol(item))
    .filter(Boolean)
    .join(',');

  const url = `https://query1.finance.yahoo.com/v7/finance/quote?symbols=${encodeURIComponent(
    symbols,
  )}&corsDomain=finance.yahoo.com`;

  try {
    const data = await fetchYahooJson(url);
    return res.status(data.status).type(data.contentType).send(data.text);
  } catch (_) {
    return res.status(502).json({ error: 'Yahoo quote proxy failed' });
  }
});

app.get('/api/v1/yahoo/chart/:symbol', async (req, res) => {
  const symbol = normalizeSymbol(req.params.symbol);
  const range = String(req.query.range || '1d');
  const interval = String(req.query.interval || '5m');

  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=${encodeURIComponent(
    range,
  )}&interval=${encodeURIComponent(
    interval,
  )}&includePrePost=false&events=div,splits&corsDomain=finance.yahoo.com`;

  try {
    const data = await fetchYahooJson(url);
    return res.status(data.status).type(data.contentType).send(data.text);
  } catch (_) {
    return res.status(502).json({ error: 'Yahoo chart proxy failed' });
  }
});

app.get('/api/v1/yahoo/company/:symbol', async (req, res) => {
  const symbol = normalizeSymbol(req.params.symbol);
  const modules = 'assetProfile,summaryDetail,defaultKeyStatistics';

  const url = `https://query2.finance.yahoo.com/v10/finance/quoteSummary/${symbol}?modules=${encodeURIComponent(
    modules,
  )}&corsDomain=finance.yahoo.com`;

  try {
    const data = await fetchYahooJson(url);
    return res.status(data.status).type(data.contentType).send(data.text);
  } catch (_) {
    return res.status(502).json({ error: 'Yahoo company proxy failed' });
  }
});

app.use((err, _req, res, _next) => {
  console.error('[SERVER_ERROR]', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Gryphone API listening on port ${PORT}`);
});
