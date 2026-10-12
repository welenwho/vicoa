import { describe, expect, it } from 'vitest';
import { deriveWsUrl, normalizeHttpUrl, normalizeWsUrl } from './selfhost-endpoints';

describe('normalizeHttpUrl', () => {
  it('adds https and drops a trailing slash', () => {
    expect(normalizeHttpUrl(' vicoa.example.com:10086/ ')).toBe(
      'https://vicoa.example.com:10086'
    );
  });

  it('keeps an explicit http URL and a path prefix', () => {
    expect(normalizeHttpUrl('http://192.168.1.10:8000/vicoa/')).toBe(
      'http://192.168.1.10:8000/vicoa'
    );
  });

  it('rejects blank and non-http schemes', () => {
    expect(normalizeHttpUrl('')).toBeNull();
    expect(normalizeHttpUrl('ftp://files.example.com')).toBeNull();
    expect(normalizeHttpUrl('not a url')).toBeNull();
  });
});

describe('deriveWsUrl', () => {
  it('keeps the API port and appends /ws', () => {
    expect(deriveWsUrl('https://vicoa-api.example.com:10086')).toBe(
      'wss://vicoa-api.example.com:10086/ws'
    );
    expect(deriveWsUrl('http://127.0.0.1:8000')).toBe('ws://127.0.0.1:8000/ws');
  });
});

describe('normalizeWsUrl', () => {
  it('rewrites https and fills an empty path', () => {
    expect(normalizeWsUrl('https://api.example.com:10086')).toBe(
      'wss://api.example.com:10086/ws'
    );
  });

  it('keeps an explicit socket path', () => {
    expect(normalizeWsUrl('wss://api.example.com/agent/ws')).toBe(
      'wss://api.example.com/agent/ws'
    );
  });
});
