const { Client } = require('pg');
const crypto = require('crypto');

const client = new Client({
  host: 'localhost', port: 5433, database: 'music', user: 'user', password: 'password',
});

const BATCH = 5000;

// ── helpers ──────────────────────────────────────────────────

function zipf(n) {
  return Math.min(Math.floor(n / (Math.random() * (n - 1) + 1)), n);
}

function wchoice(items, weights) {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = Math.random() * total;
  for (let i = 0; i < items.length; i++) {
    r -= weights[i];
    if (r <= 0) return items[i];
  }
  return items[items.length - 1];
}

function nullable(prob, val) {
  return Math.random() < prob ? null : val;
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randDate(start, daysRange) {
  const d = new Date(start);
  d.setDate(d.getDate() + randInt(0, daysRange));
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

function randTimestamp(start, daysRange) {
  const d = new Date(start);
  d.setDate(d.getDate() + randInt(0, daysRange));
  d.setSeconds(d.getSeconds() + randInt(0, 86399));
  return d.toISOString().slice(0, 19).replace('T', ' ');
}

function addDays(dateStr, days) {
  const d = new Date(dateStr);
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}

function md5(str) {
  return crypto.createHash('md5').update(str).digest('hex');
}

// ── batch insert ─────────────────────────────────────────────

async function batchInsert(sql, rows, colCount) {
  for (let i = 0; i < rows.length; i += BATCH) {
    const chunk = rows.slice(i, i + BATCH);
    const values = [];
    const placeholders = [];
    let idx = 1;

    for (const row of chunk) {
      const ph = [];
      for (const val of row) {
        ph.push(`$${idx++}`);
        values.push(val);
      }
      placeholders.push(`(${ph.join(',')})`);
    }

    await client.query(`${sql} VALUES ${placeholders.join(',')}`, values);
  }
}

// ── constants ────────────────────────────────────────────────

const COUNTRIES = ['RU', 'US', 'UK', 'DE', 'JP'];
const COUNTRY_W = [40, 25, 15, 12, 8];
const MOODS = ['happy', 'sad', 'energetic', 'calm'];
const DEVICES = ['mobile', 'desktop', 'tablet', 'smart_speaker'];
const DEVICE_W = [55, 25, 12, 8];
const PLATFORMS = ['android', 'ios', 'web'];
const PLATFORM_W = [45, 35, 20];
const QUALITIES = ['low', 'normal', 'high', 'lossless'];
const QUALITY_W = [10, 45, 30, 15];
const SOURCES = ['playlist', 'album', 'search', 'radio', 'recommend'];
const TAG_SETS = [
  ['rock', 'alternative'], ['pop', 'dance'], ['hip-hop', 'trap'],
  ['electronic', 'ambient'], ['jazz', 'fusion'], ['indie', 'folk'],
];
const TRACK_TAGS = [
  ['pop', 'summer'], ['rock', 'guitar'], ['chill', 'lofi'],
  ['dance', 'edm'], ['acoustic'], ['rap', 'beats'], ['classical', 'piano'], ['indie', 'alt'],
];
const KEYS = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
const COMMENTS_TEXT = [
  'Amazing track!', 'Solid production.', 'Incredible bass!',
  'Perfect mood.', 'Just discovered this!', 'Lyrics speak to me.',
  'Great energy!', 'Beautiful melody.', 'A masterpiece.', 'Good vibes.',
];
const RATING_POOL = [1, 2, 3, 3, 4, 4, 4, 5, 5, 5];
const STATUS_POOL = [...Array(8).fill('visible'), 'hidden', 'deleted'];
const LANGS = ['ru', 'en', 'de', 'ja'];

// ── main ─────────────────────────────────────────────────────

async function main() {
  await client.connect();

  // 1. Справочники
  console.log('1/7  subscriptions + genres');
  await client.query(`
    INSERT INTO subscription (name, price, duration_months, features) VALUES
    ('free',    0.00, NULL, '{"offline":false,"ads":true}'),
    ('basic',   4.99, 1,   '{"offline":false,"ads":false}'),
    ('premium', 9.99, 1,   '{"offline":true,"hifi":true}'),
    ('family', 14.99, 1,   '{"offline":true,"members":6}'),
    ('student', 4.99, 1,   '{"offline":true,"hifi":false}')
  `);
  const genres = ['Rock','Pop','Hip-Hop','Electronic','Jazz','Classical',
    'R&B','Metal','Folk','Blues','Country','Reggae','Latin','Indie','Punk'];
  for (const g of genres) {
    await client.query('INSERT INTO genre (name) VALUES ($1)', [g]);
  }

  // 2. Users: 250 000
  console.log('2/7  users (250 000)');
  let rows = [];
  for (let i = 1; i <= 250000; i++) {
    const subId = wchoice([1, 2, 3, 4, 5], [45, 25, 15, 10, 5]);
    const subStart = `2024-01-${String((i % 28) + 1).padStart(2, '0')}`;
    const subEnd = addDays(subStart, 30);
    rows.push([
      `u${i}@mail.com`,
      `user_${i}`,
      md5(String(i)),
      wchoice(COUNTRIES, COUNTRY_W),
      randDate('2018-01-01', 2557),
      subId,
      nullable(0.15, `+7${String((i * 7) % 10000000000).padStart(10, '0')}`),
      nullable(0.10, JSON.stringify({ theme: i % 2 === 0 ? 'dark' : 'light', lang: LANGS[i % 4] })),
      `{${1 + i % 15},${1 + (i * 3) % 15}}`,
      subId === 1 ? null : `[${subStart},${subEnd})`,
    ]);
  }
  await batchInsert(
    `INSERT INTO "user" (email,username,password_hash,country,date_joined,
     subscription_id,phone_number,preferences,favorite_genres,subscription_period)`, rows);

  // 3. Artists: 5 000
  console.log('3/7  artists (5 000)');
  rows = [];
  for (let i = 1; i <= 5000; i++) {
    rows.push([
      `Artist_${i}`,
      COUNTRIES[i % 5],
      nullable(0.15, `Description of Artist_${i}`),
      nullable(0.95, randInt(1, 250000)),
      1950 + i % 75,
      `{${TAG_SETS[i % TAG_SETS.length].join(',')}}`,
      JSON.stringify({ twitter: `@a${i}`, insta: `@a${i}_m` }),
    ]);
  }
  await batchInsert(
    'INSERT INTO artist (name,country,description,user_id,start_year,tags,social_links)', rows);

  // 4. Albums: 25 000
  console.log('4/7  albums (25 000)');
  rows = [];
  for (let i = 1; i <= 25000; i++) {
    rows.push([
      `Album_${i}`,
      randDate('2000-01-01', 9125),
      zipf(5000),
      randInt(1, 15),
    ]);
  }
  await batchInsert('INSERT INTO album (title,release_date,artist_id,genre_id)', rows);

  // 5. Tracks: 250 000
  console.log('5/7  tracks (250 000)');
  rows = [];
  for (let i = 1; i <= 250000; i++) {
    const hasLyrics = Math.random() >= 0.15;
    rows.push([
      `Track_${i}`,
      randInt(30, 600),
      zipf(25000),
      zipf(5000),
      randInt(1, 15),
      MOODS[i % 4],
      Math.floor(Math.pow(Math.random(), 3) * 10000000),
      hasLyrics ? `Lyrics for track ${i}. Words about life.` : null,
      `{${TRACK_TAGS[i % TRACK_TAGS.length].join(',')}}`,
      nullable(0.10, JSON.stringify({ bpm: 60 + i % 140, key: KEYS[i % 7], explicit: i % 5 === 0 })),
    ]);
  }
  await batchInsert(
    'INSERT INTO track (title,duration_seconds,album_id,artist_id,genre_id,mood,play_count,lyrics,tags,metadata)', rows);
  await client.query("UPDATE track SET search_vector = to_tsvector('english', title)");
  await client.query("UPDATE track SET search_vector = to_tsvector('english', title || ' ' || lyrics) WHERE lyrics IS NOT NULL");

  // 6. Listening History: 250 000
  console.log('6/7  listening_history (250 000)');
  rows = [];
  for (let i = 1; i <= 250000; i++) {
    const lng = (-180 + Math.random() * 360).toFixed(4);
    const lat = (-90 + Math.random() * 180).toFixed(4);
    rows.push([
      zipf(250000),
      zipf(250000),
      randTimestamp('2023-01-01', 730),
      wchoice(DEVICES, DEVICE_W),
      wchoice(PLATFORMS, PLATFORM_W),
      Math.random() < 0.80,
      nullable(0.70, randInt(0, 300)),
      nullable(0.15, `(${lng},${lat})`),
      `[0,${randInt(30, 600)})`,
      nullable(0.10, JSON.stringify({ source: SOURCES[i % 5], shuffle: i % 3 === 0 })),
      wchoice(QUALITIES, QUALITY_W),
    ]);
  }
  await batchInsert(
    `INSERT INTO listening_history (user_id,track_id,listened_at,device,
     platform,completed,skip_position,location,listen_duration,context,quality)`, rows);

  // 7. Comments: 250 000
  console.log('7/7  comments (250 000)');
  rows = [];
  for (let i = 1; i <= 250000; i++) {
    let parentId = null;
    if (Math.random() >= 0.80 && i > 100) {
      parentId = randInt(1, Math.min(i - 1, 100000));
    }
    rows.push([
      zipf(250000),
      zipf(250000),
      `${COMMENTS_TEXT[i % 10]} (#${i})`,
      randTimestamp('2023-01-01', 730),
      nullable(0.95, randDate('2024-01-01', 365)),
      parentId,
      RATING_POOL[i % 10],
      STATUS_POOL[i % 10],
      nullable(0.10, JSON.stringify({ like: i % 50, fire: i % 20 })),
      nullable(0.85, `{${1 + (i * 7) % 250000}}`),
    ]);
  }
  await batchInsert(
    `INSERT INTO comment (user_id,track_id,content,created_at,edited_at,
     parent_id,rating,status,reactions,mentioned_users)`, rows);
  await client.query("UPDATE comment SET search_vector = to_tsvector('english', content)");

  await client.end();
  console.log('Done! ~1 030 000 rows inserted.');
}

main().catch(err => { console.error(err); process.exit(1); });
