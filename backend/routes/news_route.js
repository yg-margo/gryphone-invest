const express = require('express');
const router  = express.Router();
const https   = require('https');
const http    = require('http');
const { parseStringPromise } = require('xml2js');

const YAHOO_RSS_URL  = 'https://finance.yahoo.com/news/rssindex';
const MAX_ARTICLES   = 20;
const CACHE_TTL_MS   = 10 * 60 * 1000;
const TRANSLATE_SEP  = ' |NSEP| ';
const CHUNK_SIZE     = 6;            

const _cache = new Map();

function get(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.get(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
          'AppleWebKit/537.36 (KHTML, like Gecko) ' +
          'Chrome/124.0.0.0 Safari/537.36',
        Accept: 'application/rss+xml, application/xml, text/xml, */*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
        ...headers,
      },
      timeout: 15_000,
    }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () =>
        resolve({ statusCode: res.statusCode, body: Buffer.concat(chunks).toString('utf8') })
      );
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout: ' + url)); });
  });
}

function stripHtml(html = '') {
  return html
    .replace(/<[^>]*>/g, '')
    .replace(/&amp;/g,  '&')
    .replace(/&lt;/g,   '<')
    .replace(/&gt;/g,   '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g,  "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g,    ' ')
    .trim();
}

function extractImage(item) {
  try {
    const mc = item['media:content']?.[0];
    if (mc?.['$']?.url) return mc['$'].url;
  } catch (_) {}

  try {
    const enc = item['enclosure']?.[0]?.['$'];
    if (enc?.type?.startsWith('image') && enc?.url) return enc.url;
  } catch (_) {}

  try {
    const desc = item['description']?.[0] ?? '';
    const m = desc.match(/src="([^"]+\.(?:jpg|jpeg|png|webp|gif))"/i);
    if (m) return m[1];
  } catch (_) {}

  return null;
}

async function fetchYahooArticles() {
  const { statusCode, body } = await get(YAHOO_RSS_URL);
  if (statusCode !== 200) throw new Error(`Yahoo RSS returned HTTP ${statusCode}`);

  const parsed = await parseStringPromise(body, {
    explicitArray: true,
    trim: true,
    normalize: true,
  });

  const items = parsed?.rss?.channel?.[0]?.item ?? [];
  const articles = [];

  for (let i = 0; i < Math.min(items.length, MAX_ARTICLES); i++) {
    const item  = items[i];
    const title = item.title?.[0] ?? '';
    const link  = item.link?.[0] ?? '';
    if (!title || !link) continue;

    const rawDesc   = item.description?.[0] ?? '';
    const desc      = stripHtml(rawDesc);
    const pubDate   = item.pubDate?.[0] ?? '';
    const imageUrl  = extractImage(item);

    let publishedAt;
    try { publishedAt = new Date(pubDate).toISOString(); }
    catch (_) { publishedAt = new Date().toISOString(); }

    articles.push({
      id:          `yahoo_${i}`,
      title,
      description: desc || title,
      url:         link,
      imageUrl:    imageUrl ?? null,
      source:      'Yahoo Finance',
      publishedAt,
    });
  }

  if (articles.length === 0) throw new Error('Yahoo RSS returned 0 parseable articles');
  return articles;
}

async function translateBatch(texts, targetLang) {
  const joined  = texts.map(t => t || '.').join(TRANSLATE_SEP);
  const encoded = encodeURIComponent(joined);
  const url     =
    `https://translate.googleapis.com/translate_a/single` +
    `?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encoded}`;

  const { statusCode, body } = await get(url, { Accept: 'application/json' });
  if (statusCode !== 200) throw new Error(`Translate HTTP ${statusCode}`);

  const data = JSON.parse(body);
  let out = '';
  for (const seg of (data[0] ?? [])) {
    if (seg?.[0]) out += seg[0];
  }

  const parts = out.split(TRANSLATE_SEP).map(s => s.trim());
  return parts.length === texts.length ? parts : texts;
}

async function translateArticles(articles, targetLang) {
  const result = articles.map(a => ({ ...a }));

  for (let i = 0; i < result.length; i += CHUNK_SIZE) {
    const slice = result.slice(i, i + CHUNK_SIZE);

    const titles = slice.map(a => a.title);
    const descs  = slice.map(a =>
      a.description && a.description !== a.title ? a.description : '.'
    );

    const [trTitles, trDescs] = await Promise.all([
      translateBatch(titles, targetLang),
      translateBatch(descs,  targetLang),
    ]);

    slice.forEach((a, j) => {
      if (trTitles[j] && trTitles[j] !== '.') a.title = trTitles[j];
      if (trDescs[j]  && trDescs[j]  !== '.') a.description = trDescs[j];
    });
  }

  return result;
}

router.get('/', async (req, res) => {
  const lang     = req.query.lang === 'ru' ? 'ru' : 'en';
  const cacheKey = `news_${lang}`;

  const hit = _cache.get(cacheKey);
  if (hit && Date.now() - hit.timestamp < CACHE_TTL_MS) {
    return res.json({ ok: true, articles: hit.articles, cached: true });
  }

  try {
    const raw = await fetchYahooArticles();

    let articles = raw;
    if (lang === 'ru') {
      try {
        articles = await translateArticles(raw, 'ru');
      } catch (translationErr) {
        console.warn('[news] Translation failed, serving English:', translationErr.message);
      }
    }

    _cache.set(cacheKey, { articles, timestamp: Date.now() });
    return res.json({ ok: true, articles });

  } catch (err) {
    console.error('[news] fetchYahooArticles error:', err.message);
    return res.status(502).json({ ok: false, error: err.message });
  }
});

module.exports = router;
