import 'package:flutter_test/flutter_test.dart';
import 'package:vicoa/custom_code/server/server_config.dart';

void main() {
  test('normalizeHttpBase accepts a host:port and strips a trailing slash', () {
    expect(
      normalizeHttpBase('192.168.1.10:8000'),
      'http://192.168.1.10:8000',
    );
    expect(
      normalizeHttpBase('http://192.168.1.10:8000/'),
      'http://192.168.1.10:8000',
    );
    expect(normalizeHttpBase('https://api.example.com'), 'https://api.example.com');
    expect(normalizeHttpBase(''), isNull);
    expect(normalizeHttpBase('ftp://example.com'), isNull);
  });

  test('deriveWsUrl swaps the self-host REST port for the agent port', () {
    expect(
      deriveWsUrl('http://192.168.1.10:8000'),
      'ws://192.168.1.10:8080/ws',
    );
    expect(
      deriveWsUrl('https://vicoa.example.com:8000'),
      'wss://vicoa.example.com:8080/ws',
    );
    expect(deriveWsUrl('https://api.example.com'), 'wss://api.example.com/ws');
    expect(deriveWsUrl('http://[::1]:8000'), 'ws://[::1]:8080/ws');
  });

  test('normalizeWsUrl accepts ws and http schemes and adds /ws', () {
    expect(normalizeWsUrl('ws://192.168.1.10:8080/ws'), 'ws://192.168.1.10:8080/ws');
    expect(normalizeWsUrl('http://192.168.1.10:8080'), 'ws://192.168.1.10:8080/ws');
    expect(normalizeWsUrl('https://agents.example.com/ws'), 'wss://agents.example.com/ws');
    expect(normalizeWsUrl('not a url'), isNull);
  });
}
