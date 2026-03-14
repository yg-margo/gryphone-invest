const config = {
  port: Number(process.env.PORT || 3000),
  jwtSecret: process.env.JWT_SECRET || 'change-me-in-production',
  clientOrigin: process.env.CLIENT_ORIGIN || '*',
  yahooTimeoutMs: Number(process.env.YAHOO_TIMEOUT_MS || 15000),
};

module.exports = config;
