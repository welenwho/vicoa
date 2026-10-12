/**
 * Addresses for a self-hosted Vicoa the desktop app should talk to.
 *
 * Mirrors `apps/desktop/src/server-url.ts`. The form previews with this copy;
 * the shell normalizes again on save.
 */

export type SelfHostAuthProvider = 'builtin' | 'supabase';

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

/** Same host and port as the API. Does not rewrite 8000 to 8080. */
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

export interface AuthConfigProbe {
  provider: SelfHostAuthProvider;
  allowSignup: boolean;
  requireEmailVerification: boolean;
}
