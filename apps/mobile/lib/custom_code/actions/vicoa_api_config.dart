// Automatic FlutterFlow imports
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/server/server_config.dart';

/// Returns the base URL for the Vicoa backend API based on build mode.
///
/// A saved self-hosted address wins over the hosted default. The debug-mode
/// lines below stay in the shape `scripts/backend_toggle.py` edits.
///
/// - Debug mode: Uses local backend (Android emulator uses 10.0.2.2, others use localhost)
/// - Release mode: Always uses production URL (https://api.vicoa.ai) unless a
///   self-hosted address was saved in the app.
String getVicoaApiBaseUrl() {
  final override = ServerConfig.instance.apiBaseUrl;
  if (override.isNotEmpty) return override;

  if (kDebugMode) {
    // Android emulator routes 10.0.2.2 to the host machine's localhost
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    // return 'http://$host:8000';
    return 'https://api.vicoa.ai';
  }

  return 'https://api.vicoa.ai';
}

/// Returns the `/ws` WebSocket endpoint URL (websocket-migration plan §2.1).
///
/// The endpoint lives on the agent-facing `server` process, served on port 443
/// under the canonical hostname `agents.vicoa.ai` — a different host than the
/// REST base URL above.
String getVicoaWsUrl() {
  final override = ServerConfig.instance.wsUrl;
  if (override.isNotEmpty) return override;

  if (kDebugMode) {
    // Android emulator routes 10.0.2.2 to the host machine's localhost.
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    // return 'ws://$host:8080/ws';
    return 'wss://agents.vicoa.ai/ws';
  }

  return 'wss://agents.vicoa.ai/ws';
}
