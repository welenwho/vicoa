'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { getDesktopAuthBridge, type ServerProbeResult } from '@/lib/desktop-auth';
import { getDesktopConfig } from '@/lib/runtime-config';
import { deriveWsUrl, normalizeHttpUrl, normalizeWsUrl } from '@/lib/selfhost-endpoints';
import { DRAG_REGION } from '@/lib/app-region';

/**
 * First-launch and later editor for the self-hosted addresses.
 *
 * The published desktop app bakes vicoa.ai into the sign-in URL. This screen
 * writes `~/.vicoa/desktop.json` through the shell and relaunches, so the
 * daemon, the sign-in page, and the auth provider all follow what was typed.
 */
export default function DesktopServerPage() {
  const [zh, setZh] = useState(false);
  const copy = zh ? zhCopy : enCopy;
  const [webUrl, setWebUrl] = useState('');
  const [apiUrl, setApiUrl] = useState('');
  const [wsUrl, setWsUrl] = useState('');
  const [supabaseUrl, setSupabaseUrl] = useState('');
  const [supabaseAnonKey, setSupabaseAnonKey] = useState('');
  useEffect(() => {
    setZh(navigator.language.toLowerCase().startsWith('zh'));
    const saved = getDesktopConfig();
    if (!saved) return;
    if (saved.cloudWebUrl) setWebUrl(saved.cloudWebUrl);
    if (saved.cloudApiBase) setApiUrl(saved.cloudApiBase);
    if (saved.cloudWsUrl) setWsUrl(saved.cloudWsUrl);
    if (saved.supabaseUrl) setSupabaseUrl(saved.supabaseUrl);
    if (saved.supabaseAnonKey) setSupabaseAnonKey(saved.supabaseAnonKey);
  }, []);
  const [probe, setProbe] = useState<ServerProbeResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<'probe' | 'save' | null>(null);

  const wsPreview = (() => {
    const typed = wsUrl.trim();
    if (typed) return normalizeWsUrl(typed);
    const api = normalizeHttpUrl(apiUrl);
    return api ? deriveWsUrl(api) : null;
  })();

  async function test(): Promise<ServerProbeResult | null> {
    const bridge = getDesktopAuthBridge();
    if (!bridge?.probeServer) {
      setError(copy.noBridge);
      return null;
    }
    const api = normalizeHttpUrl(apiUrl);
    if (!api) {
      setError(copy.badApi);
      return null;
    }
    setBusy('probe');
    setError(null);
    try {
      const result = await bridge.probeServer({ apiUrl: api });
      if (!result.ok || (result.provider !== 'builtin' && result.provider !== 'supabase')) {
        setProbe(null);
        setError(result.error || copy.badResponse);
        return null;
      }
      setProbe(result);
      return result;
    } catch (err) {
      setProbe(null);
      setError(err instanceof Error ? err.message : copy.unreachable);
      return null;
    } finally {
      setBusy(null);
    }
  }

  async function save() {
    const web = normalizeHttpUrl(webUrl);
    const api = normalizeHttpUrl(apiUrl);
    if (!web) {
      setError(copy.badWeb);
      return;
    }
    if (!api) {
      setError(copy.badApi);
      return;
    }
    const socket = wsUrl.trim() ? normalizeWsUrl(wsUrl) : deriveWsUrl(api);
    if (!socket) {
      setError(copy.badWs);
      return;
    }
    const found = probe?.apiUrl === api ? probe : await test();
    if (!found?.provider) return;
    if (found.provider === 'supabase') {
      if (!normalizeHttpUrl(supabaseUrl) || supabaseAnonKey.trim() === '') {
        setError(copy.supabaseRequired);
        return;
      }
    }
    const bridge = getDesktopAuthBridge();
    if (!bridge?.saveServerConfig) {
      setError(copy.noBridge);
      return;
    }
    setBusy('save');
    setError(null);
    const result = await bridge.saveServerConfig({
      webUrl: web,
      apiUrl: api,
      wsUrl: socket,
      authProvider: found.provider,
      ...(found.provider === 'supabase'
        ? { supabaseUrl: normalizeHttpUrl(supabaseUrl) ?? '', supabaseAnonKey: supabaseAnonKey.trim() }
        : {}),
    });
    if (!result.ok) {
      setBusy(null);
      setError(result.error || copy.saveFailed);
    }
  }

  return (
    <div className="flex h-screen flex-col bg-background">
      <div style={DRAG_REGION} className="h-11 shrink-0" />
      <div className="flex flex-1 flex-col items-center justify-center overflow-y-auto px-4 pb-11">
        <div className="flex w-full max-w-md flex-col items-center">
          <Image
            src="/images/vicoa-light.webp"
            alt="Vicoa"
            width={0}
            height={0}
            sizes="100vw"
            className="h-12 w-auto opacity-90"
          />
          <h2 className="mt-6 text-center text-3xl text-foreground">{copy.title}</h2>
          <p className="mt-2 text-center text-sm text-muted-foreground">{copy.help}</p>
          <div className="mt-8 flex w-full flex-col gap-4">
            <Field label={copy.webLabel} value={webUrl} onChange={setWebUrl} placeholder="https://vicoa.example.com:10086" />
            <Field label={copy.apiLabel} value={apiUrl} onChange={setApiUrl} placeholder="https://vicoa-api.example.com:10086" />
            <Field
              label={copy.wsLabel}
              value={wsUrl}
              onChange={setWsUrl}
              placeholder={wsPreview ?? 'wss://vicoa-api.example.com:10086/ws'}
            />
            {wsPreview && wsUrl.trim() === '' && (
              <p className="text-xs text-muted-foreground">{copy.wsPreview(wsPreview)}</p>
            )}
            {probe?.provider === 'supabase' && (
              <>
                <Field label="Supabase URL" value={supabaseUrl} onChange={setSupabaseUrl} placeholder="https://project.supabase.co" />
                <Field label="Supabase anon key" value={supabaseAnonKey} onChange={setSupabaseAnonKey} placeholder="eyJ..." />
              </>
            )}
            {probe?.provider && (
              <p className="text-sm text-muted-foreground">
                {probe.provider === 'builtin' ? copy.providerBuiltin : copy.providerSupabase}
                {probe.allowSignup ? ` · ${copy.signupOpen}` : ` · ${copy.signupClosed}`}
              </p>
            )}
            {error && <p className="text-sm text-destructive">{error}</p>}
            <div className="flex gap-3">
              <Button type="button" variant="outline" className="flex-1" disabled={busy !== null} onClick={() => void test()}>
                {busy === 'probe' && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {copy.test}
              </Button>
              <Button type="button" className="flex-1" disabled={busy !== null} onClick={() => void save()}>
                {busy === 'save' && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {busy === 'save' ? copy.saving : copy.save}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
}) {
  return (
    <label className="flex flex-col gap-1.5 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <input
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        spellCheck={false}
        autoCapitalize="off"
        autoCorrect="off"
        className="rounded-md border border-border bg-background px-3 py-2 font-mono text-sm text-foreground outline-none focus:ring-2 focus:ring-ring"
      />
    </label>
  );
}

const zhCopy = {
  title: '自建服务器',
  help: '网页、API、WebSocket 可以是不同地址。WebSocket 留空时，使用 API 的主机和端口，并加上 /ws。',
  webLabel: '网页地址',
  apiLabel: 'API 地址',
  wsLabel: 'WebSocket 地址（可选）',
  wsPreview: (url: string) => `留空将使用 ${url}`,
  test: '测试连接',
  save: '保存并重启',
  saving: '正在重启…',
  badWeb: '请填写网页地址，例如 https://vicoa.example.com:10086',
  badApi: '请填写 API 地址，例如 https://vicoa-api.example.com:10086',
  badWs: 'WebSocket 地址无效。留空会按 API 地址生成。',
  badResponse: '这个地址没有返回 Vicoa 的登录配置。',
  unreachable: '连不上这个 API 地址。请检查主机、端口和证书。',
  noBridge: '请在桌面应用里打开这个页面。',
  saveFailed: '没能保存服务器地址。',
  providerBuiltin: '登录方式：内置账号',
  providerSupabase: '登录方式：Supabase',
  signupOpen: '允许注册',
  signupClosed: '已关闭注册',
  supabaseRequired: '这台服务器使用 Supabase。请填写项目 URL 和 anon key。',
};

const enCopy = {
  title: 'Self-hosted server',
  help: 'The web, API, and WebSocket addresses can differ. Leave WebSocket blank to use the API host and port with /ws.',
  webLabel: 'Web address',
  apiLabel: 'API address',
  wsLabel: 'WebSocket address (optional)',
  wsPreview: (url: string) => `Blank uses ${url}`,
  test: 'Test connection',
  save: 'Save and restart',
  saving: 'Restarting…',
  badWeb: 'Enter the web address, for example https://vicoa.example.com:10086',
  badApi: 'Enter the API address, for example https://vicoa-api.example.com:10086',
  badWs: 'That WebSocket address is invalid. Leave it blank to fill it from the API address.',
  badResponse: 'That address did not return a Vicoa auth config.',
  unreachable: 'Could not reach that API address. Check the host, port, and certificate.',
  noBridge: 'Open this page in the desktop app.',
  saveFailed: 'Could not save the server address.',
  providerBuiltin: 'Sign-in: built-in accounts',
  providerSupabase: 'Sign-in: Supabase',
  signupOpen: 'Sign-up is open',
  signupClosed: 'Sign-up is closed',
  supabaseRequired: 'This server uses Supabase. Enter the project URL and anon key.',
};
