import 'dotenv/config';
import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { appendFile, readdir, readFile, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, basename } from 'node:path';
import QRCode from 'qrcode';

const app = new Hono();

const {
  PORT = 7777,
  BUDDY_CHANNEL = '/tmp/cctalk.log',
  BUDDY_HOME = join(homedir(), '.buddy'),
  AUTH_TOKEN,
} = process.env;

if (!AUTH_TOKEN) {
  console.error('FATAL: AUTH_TOKEN mangler i .env');
  process.exit(1);
}

const CHANNELS_DIR = join(BUDDY_HOME, 'channels');
const SECRET_PATH = join(BUDDY_HOME, 'channel-secret');
const STATE_PATH = join(homedir(), '.cctalk-state.json');

async function loadLastTarget() {
  try {
    const data = JSON.parse(await readFile(STATE_PATH, 'utf8'));
    return data.lastTarget ?? null;
  } catch {
    return null;
  }
}

async function saveLastTarget(target) {
  await writeFile(STATE_PATH, JSON.stringify({ lastTarget: target }, null, 2));
}

async function loadBuddySecret() {
  try {
    return (await readFile(SECRET_PATH, 'utf8')).trim();
  } catch {
    return null;
  }
}

async function discoverChannels() {
  const fromApi = await discoverChannelsFromBuddy();
  if (fromApi) return fromApi;
  return await discoverChannelsFromDisk();
}

async function discoverChannelsFromBuddy() {
  try {
    const res = await fetch('http://127.0.0.1:4123/api/channels', {
      signal: AbortSignal.timeout(1500),
    });
    if (!res.ok) return null;
    const rows = await res.json();
    if (!Array.isArray(rows)) return null;
    return rows.map((data) => ({
      pid: data.pid,
      port: data.port,
      cwd: data.cwd,
      ccSessionId: data.ccSessionId,
      name: data.sessionName || basename(data.cwd || ''),
      sessionName: data.sessionName || null,
      startedAt: data.startedAt,
    }));
  } catch {
    return null;
  }
}

async function discoverChannelsFromDisk() {
  let files;
  try {
    files = await readdir(CHANNELS_DIR);
  } catch {
    return [];
  }
  const channels = [];
  for (const f of files) {
    if (!f.endsWith('.json')) continue;
    try {
      const data = JSON.parse(await readFile(join(CHANNELS_DIR, f), 'utf8'));
      channels.push({
        pid: data.pid,
        port: data.port,
        cwd: data.cwd,
        ccSessionId: data.ccSessionId,
        name: data.sessionName || basename(data.cwd || ''),
        sessionName: data.sessionName || null,
        startedAt: data.startedAt,
      });
    } catch {
      /* skip malformed */
    }
  }
  return channels;
}

function findChannel(channels, target) {
  if (!target) return null;
  const raw = String(target).trim();
  const pidMatch = raw.match(/\((\d+)\)\s*$/);
  if (pidMatch) {
    const byPid = channels.find((c) => String(c.pid) === pidMatch[1]);
    if (byPid) return byPid;
  }
  const t = raw.toLowerCase();
  return (
    channels.find((c) => String(c.pid) === t) ||
    channels.find((c) => c.ccSessionId === raw) ||
    channels.find((c) => c.name.toLowerCase() === t) ||
    channels.find((c) => (c.cwd || '').toLowerCase() === t) ||
    null
  );
}

function requireAuth(c) {
  const auth = c.req.header('authorization');
  return auth === `Bearer ${AUTH_TOKEN}`;
}

app.get('/health', (c) => c.json({ ok: true, service: 'cctalk' }));

async function resolvePairingHost(reqHost) {
  const override = process.env.PAIRING_HOST;
  if (override) return override;
  const isLoopback =
    !reqHost ||
    reqHost.startsWith('localhost') ||
    reqHost.startsWith('127.') ||
    reqHost.startsWith('[::1]');
  if (!isLoopback) return reqHost;
  try {
    const { execSync } = await import('node:child_process');
    const out = execSync(
      '/Applications/Tailscale.app/Contents/MacOS/Tailscale status --json',
      { timeout: 2000 },
    ).toString();
    const json = JSON.parse(out);
    const dns = json?.Self?.DNSName?.replace(/\.$/, '');
    if (dns) return `${dns}:${PORT}`;
  } catch {
    /* fallthrough */
  }
  return reqHost ?? `localhost:${PORT}`;
}

app.get('/qr', async (c) => {
  const reqHost = c.req.header('host');
  const queryHost = c.req.query('host');
  const host = queryHost || (await resolvePairingHost(reqHost));
  const baseUrl = `http://${host}`;
  const deepLink = `cctalk://config?baseUrl=${encodeURIComponent(baseUrl)}&token=${encodeURIComponent(AUTH_TOKEN)}`;
  const png = await QRCode.toBuffer(deepLink, { width: 512, margin: 2 });
  return new Response(png, {
    headers: {
      'content-type': 'image/png',
      'cache-control': 'no-store',
      'x-cctalk-host': host,
    },
  });
});

function addDisplayNames(channels) {
  const counts = new Map();
  for (const ch of channels) counts.set(ch.name, (counts.get(ch.name) ?? 0) + 1);
  return channels.map((ch) => ({
    ...ch,
    displayName:
      ch.sessionName || (counts.get(ch.name) > 1 ? `${ch.name}#${ch.pid}` : ch.name),
  }));
}

app.get('/sessions', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);
  const channels = addDisplayNames(await discoverChannels());
  return c.json(
    channels
      .map((ch) => ({
        name: ch.name,
        displayName: ch.displayName,
        pid: ch.pid,
        cwd: ch.cwd,
        port: ch.port,
      }))
      .sort((a, b) => a.displayName.localeCompare(b.displayName)),
  );
});

app.get('/sessions.txt', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);
  const channels = await discoverChannels();
  const lines = channels
    .map((ch) => `${ch.name} (${ch.pid})`)
    .sort((a, b) => a.localeCompare(b))
    .join('\n');
  return c.text(lines);
});

app.get('/target', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);
  const target = await loadLastTarget();
  return c.json({ target });
});

app.post('/target', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);
  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'invalid json' }, 400);
  }
  const target = body?.target?.trim();
  if (!target) return c.json({ error: 'empty target' }, 400);
  const channels = await discoverChannels();
  const channel = findChannel(channels, target);
  if (!channel) return c.json({ error: 'target_not_found', target }, 404);
  await saveLastTarget(target);
  return c.json({ ok: true, target, resolved: channel.name, pid: channel.pid });
});

app.post('/speak', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);

  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'invalid json' }, 400);
  }

  const text = body?.text?.trim();
  if (!text) return c.json({ error: 'empty text' }, 400);

  let target = body?.target?.trim();
  if (!target) {
    target = await loadLastTarget();
  } else {
    await saveLastTarget(target);
  }
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] (${target || 'file'}) → ${text}`);

  if (target) {
    const channels = await discoverChannels();
    const channel = findChannel(channels, target);
    if (!channel) {
      return c.json({ error: 'target_not_found', target }, 404);
    }
    const secret = await loadBuddySecret();
    if (!secret) {
      return c.json({ error: 'buddy_secret_missing' }, 500);
    }
    try {
      const res = await fetch(`http://127.0.0.1:${channel.port}/push`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-buddy-key': secret,
        },
        body: JSON.stringify({
          content: `[voice] ${text}`,
          meta: { type: 'voice', source: 'cctalk' },
        }),
      });
      if (!res.ok) {
        const errText = await res.text();
        return c.json(
          { error: 'push_failed', status: res.status, body: errText },
          502,
        );
      }
      return c.json({
        ok: true,
        received: text,
        delivered_to: channel.name,
        pid: channel.pid,
      });
    } catch (err) {
      return c.json({ error: 'push_error', message: err.message }, 502);
    }
  }

  try {
    await appendFile(BUDDY_CHANNEL, text + '\n');
  } catch (err) {
    console.error('Kunne ikke skrive til buddy-channel:', err.message);
    return c.json({ error: 'channel write failed' }, 500);
  }

  return c.json({ ok: true, received: text });
});

serve({ fetch: app.fetch, port: Number(PORT) });
console.log(`cctalk lytter på :${PORT}`);
console.log(`buddy-channel: ${BUDDY_CHANNEL}`);
console.log(`buddy-home: ${BUDDY_HOME}`);
