import 'package:flutter/widgets.dart';

/// Copy for the self-hosted server screens.
///
/// Kept next to the feature so a locale switch does not require regenerating
/// the FlutterFlow localization files. Follows the app language (zh / en).
class ServerStrings {
  ServerStrings._(this.zh);

  final bool zh;

  factory ServerStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return ServerStrings._(code.startsWith('zh'));
  }

  String get profileServer => zh ? '自建服务器' : 'Self-hosted server';
  String get serverTitle => zh ? '自建服务器' : 'Self-hosted server';
  String get apiLabel => zh ? '后端 API 地址' : 'Backend API address';
  String get apiHint => 'http://192.168.1.10:8000';
  String get wsLabel => zh ? 'WebSocket 地址' : 'WebSocket address';
  String get wsHint => 'ws://192.168.1.10:8080/ws';
  String get help => zh
      ? '填写 backend 服务地址，通常是端口 8000，不是网页仪表盘（3000）。WebSocket 会按端口 8080 自动填好，反向代理用了别的域名时再改。局域网可以用 http，公网请用受信任的 https。'
      : 'Use the backend service, usually port 8000, not the web dashboard on port 3000. The WebSocket address is filled in from port 8080; edit it if your reverse proxy uses another host. http works on a LAN. Public servers need a trusted https certificate.';
  String get testSave => zh ? '测试并保存' : 'Test and save';
  String get testing => zh ? '正在连接…' : 'Connecting…';
  String get saved => zh ? '已保存，可以用这个服务器登录。' : 'Saved. You can sign in to this server.';
  String get unreachable => zh
      ? '连不上这个地址。确认手机能访问它，并且填的是 backend（通常 :8000），不是网页地址。'
      : 'Could not reach that address. Confirm the phone can reach it, and that it is the backend (usually :8000), not the web dashboard.';
  String get badResponse => zh
      ? '这个地址没有返回 Vicoa 的登录配置。请检查是不是 backend 的根地址。'
      : 'That address did not return a Vicoa auth config. Check that it is the backend root.';
  String get invalidUrl => zh
      ? '请输入有效的服务器地址，例如 http://192.168.1.10:8000'
      : 'Enter a valid server address, for example http://192.168.1.10:8000';
  String get invalidWs => zh
      ? 'WebSocket 地址无效。留空会自动生成，或填写 ws://主机:8080/ws'
      : 'That WebSocket address is invalid. Leave it blank to fill it in, or use ws://host:8080/ws';
  String get providerBuiltin => zh ? '登录方式：内置账号' : 'Sign-in: built-in accounts';
  String get providerSupabase => zh ? '登录方式：Supabase' : 'Sign-in: Supabase';
  String get signupOpen => zh ? '允许注册' : 'Sign-up is open';
  String get signupClosed => zh ? '已关闭注册' : 'Sign-up is closed';
  String get supabaseUrlLabel => 'Supabase URL';
  String get supabaseKeyLabel => zh ? 'Supabase anon key' : 'Supabase anon key';
  String get supabaseRequired => zh
      ? '这台服务器使用 Supabase。请填写项目 URL 和 anon key，保存后重新打开 App 再登录。'
      : 'This server uses Supabase. Enter the project URL and anon key, then restart the app before signing in.';
  String get supabaseRestart => zh
      ? '已保存。请完全退出并重新打开 App，再用 Supabase 登录。'
      : 'Saved. Fully quit and reopen the app, then sign in with Supabase.';
  String get signedOutNote =>
      zh ? '更换服务器会退出当前账号。' : 'Saving a different server signs you out.';
  String get changeServer => zh ? '更换服务器' : 'Change server';
  String get signInTitle => zh ? '登录' : 'Sign in';
  String get signUpTitle => zh ? '注册' : 'Create account';
  String get email => zh ? '邮箱' : 'Email';
  String get password => zh ? '密码' : 'Password';
  String get displayName => zh ? '显示名称（可选）' : 'Display name (optional)';
  String get signIn => zh ? '登录' : 'Sign in';
  String get signUp => zh ? '创建账号' : 'Create account';
  String get needAccount => zh ? '没有账号？注册' : 'Need an account? Sign up';
  String get haveAccount => zh ? '已有账号？登录' : 'Already have an account? Sign in';
  String get forgotPassword => zh ? '忘记密码' : 'Forgot password';
  String get working => zh ? '请稍候…' : 'Please wait…';
  String get missingFields => zh ? '请填写邮箱和密码。' : 'Enter your email and password.';
  String serverLine(String url) => zh ? '服务器 $url' : 'Server $url';
}
