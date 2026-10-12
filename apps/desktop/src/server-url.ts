/**
 * Normalize the addresses a person types into the desktop server screen.
 *
 * The shell is the authority on save. The renderer has a matching copy in
 * `apps/web/lib/selfhost-endpoints.ts` so the form can preview a WebSocket
 * address before the save round-trip. Keep the two in step.
 */

export type AuthProviderName = 'builtin' | 'supabase';

/** http(s) base with no trailing slash. A bare host:port becomes https. */
export function normalizeHttpUrl(raw: string): string | null {
  const text = raw.trim();
  if (text === '' || /\s/.test(text)) return null;
  let candidate = text;
  if (!candidate.includes('://')) candidate = `https://${candidate}`;
  let url: URL;
  try {
    url = new URL(candidate);
  } catch {
    return null;
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
  if (url.hostname === '') return null;
  url.hash = '';
  url.search = '';
  url.pathname = url.pathname.replace(/\/+$/, '');
  if (url.pathname === '/') url.pathname = '';
  return url.toString().replace(/\/$/, '');
}

/** ws(s) URL. An empty path becomes `/ws`. http(s) is rewritten to ws(s). */
export function normalizeWsUrl(raw: string): string | null {
  const text = raw.trim();
  if (text === '' || /\s/.test(text)) return null;
  let candidate = text;
  if (!candidate.includes('://')) candidate = `wss://${candidate}`;
  if (candidate.startsWith('http://')) candidate = `ws://${candidate.slice('http://'.length)}`;
  if (candidate.startsWith('https://')) candidate = `wss://${candidate.slice('https://'.length)}`;
  let url: URL;
  try {
    url = new URL(candidate);
  } catch {
    return null;
  }
  if (url.protocol !== 'ws:' && url.protocol !== 'wss:') return null;
  if (url.hostname === '') return null;
  url.hash = '';
  url.search = '';
  const path = url.pathname.replace(/\/+$/, '');
  url.pathname = path === '' || path === '/' ? '/ws' : path;
  return url.toString();
}

/**
 * WebSocket on the same host and port as the API, scheme swapped, `/ws` appended.
 * A reverse proxy that publishes REST and the agent socket on different hosts
 * is entered by hand; this does not rewrite 8000 to 8080.
 */
export function deriveWsUrl(apiUrl: string): string | null {
  try {
    const url = new URL(apiUrl);
    url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
    url.pathname = `${url.pathname.replace(/\/+$/, '')}/ws`;
    url.search = '';
    url.hash = '';
    return url.toString();
  } catch {
    return null;
  }
}

export function isAuthProviderName(value: unknown): value is AuthProviderName {
  return value === 'builtin' || value === 'supabase';
}
