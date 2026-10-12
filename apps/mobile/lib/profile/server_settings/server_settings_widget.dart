import '/auth/base_auth_user_provider.dart';
import '/custom_code/actions/sign_out_and_clear_local_data.dart';
import '/custom_code/server/server_config.dart';
import '/custom_code/server/server_strings.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/onboarding/builtin_sign_in/builtin_sign_in_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'server_settings_model.dart';
export 'server_settings_model.dart';

class ServerSettingsWidget extends StatefulWidget {
  const ServerSettingsWidget({super.key, this.requiredSetup = false});

  /// First-launch gate: there is no server yet, so the back button is hidden.
  final bool requiredSetup;

  static String routeName = 'ServerSettings';
  static String routePath = '/serverSettings';

  @override
  State<ServerSettingsWidget> createState() => _ServerSettingsWidgetState();
}

class _ServerSettingsWidgetState extends State<ServerSettingsWidget> {
  late ServerSettingsModel _model;
  final _apiController = TextEditingController();
  final _wsController = TextEditingController();
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();
  bool _wsEdited = false;
  bool _fillingWs = false;
  bool _busy = false;
  String? _error;
  String? _status;
  String? _provider;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ServerSettingsModel());
    final config = ServerConfig.instance;
    _apiController.text = config.apiBaseUrl;
    _wsController.text = config.wsUrl;
    _supabaseUrlController.text = config.supabaseUrl;
    _supabaseKeyController.text = config.supabaseAnonKey;
    _provider = config.provider.isEmpty ? null : config.provider;
    _wsEdited = config.wsUrl.isNotEmpty;
    _apiController.addListener(_onApiChanged);
  }

  @override
  void dispose() {
    _apiController.removeListener(_onApiChanged);
    _apiController.dispose();
    _wsController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onApiChanged() {
    if (_wsEdited) return;
    final api = normalizeHttpBase(_apiController.text);
    if (api == null) return;
    final derived = deriveWsUrl(api);
    if (_wsController.text == derived) return;
    _fillingWs = true;
    _wsController.value = TextEditingValue(
      text: derived,
      selection: TextSelection.collapsed(offset: derived.length),
    );
    _fillingWs = false;
  }

  Future<void> _save() async {
    final strings = ServerStrings.of(context);
    final previousApi = ServerConfig.instance.apiBaseUrl;
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    try {
      final probe = await probeServer(
        _apiController.text,
        wsRaw: _wsEdited ? _wsController.text : '',
      );
      final wasLoggedIn = loggedIn;
      final switching = wasLoggedIn && previousApi.isNotEmpty && previousApi != probe.apiBaseUrl;
      await ServerConfig.instance.save(
        apiBaseUrl: probe.apiBaseUrl,
        wsUrl: probe.wsUrl,
        provider: probe.provider,
        allowSignup: probe.allowSignup,
        requireEmailVerification: probe.requireEmailVerification,
        supabaseUrl: _supabaseUrlController.text.trim(),
        supabaseAnonKey: _supabaseKeyController.text.trim(),
      );
      if (switching) {
        await signOutAndClearLocalData();
      }
      if (!mounted) return;
      final needsSupabaseKeys = probe.provider == 'supabase' &&
          (_supabaseUrlController.text.trim().isEmpty ||
              _supabaseKeyController.text.trim().isEmpty);
      setState(() {
        _provider = probe.provider;
        _wsController.text = probe.wsUrl;
        _apiController.text = probe.apiBaseUrl;
        _status = needsSupabaseKeys
            ? strings.supabaseRequired
            : (probe.provider == 'supabase'
                ? strings.supabaseRestart
                : strings.saved);
      });
      if (probe.provider != 'builtin') return;
      if (wasLoggedIn && !switching) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      } else {
        context.goNamed(BuiltinSignInWidget.routeName);
      }
    } on ServerProbeException catch (e) {
      if (!mounted) return;
      setState(() => _error = _probeMessage(strings, e.message));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _probeMessage(ServerStrings strings, String code) {
    switch (code) {
      case 'invalid_url':
        return strings.invalidUrl;
      case 'invalid_ws':
        return strings.invalidWs;
      case 'bad_response':
        return strings.badResponse;
      default:
        return strings.unreachable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final strings = ServerStrings.of(context);
    final showSupabase = _provider == 'supabase' ||
        _supabaseUrlController.text.isNotEmpty;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          automaticallyImplyLeading: false,
          leading: widget.requiredSetup
              ? const SizedBox.shrink()
              : Align(
                  alignment: const AlignmentDirectional(1.0, 0.0),
                  child: FlutterFlowIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 10.0,
                    borderWidth: 1.0,
                    buttonSize: 40.0,
                    fillColor: theme.primaryBackground,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: theme.secondaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      context.safePop();
                    },
                  ),
                ),
          title: Text(
            strings.serverTitle,
            style: theme.titleLarge.override(
              font: GoogleFonts.sourceSans3(
                fontWeight: theme.titleLarge.fontWeight,
                fontStyle: theme.titleLarge.fontStyle,
              ),
              letterSpacing: 0.0,
              fontWeight: theme.titleLarge.fontWeight,
              fontStyle: theme.titleLarge.fontStyle,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 32.0),
            children: [
              Text(
                strings.help,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.sourceSans3(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 16.0),
              _field(
                context,
                label: strings.apiLabel,
                hint: strings.apiHint,
                controller: _apiController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12.0),
              _field(
                context,
                label: strings.wsLabel,
                hint: strings.wsHint,
                controller: _wsController,
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  if (!_fillingWs) _wsEdited = true;
                },
              ),
              if (loggedIn) ...[
                const SizedBox(height: 8.0),
                Text(
                  strings.signedOutNote,
                  style: theme.bodySmall.override(
                    font: GoogleFonts.sourceSans3(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
              if (showSupabase) ...[
                const SizedBox(height: 16.0),
                Text(
                  strings.supabaseRequired,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.sourceSans3(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                _field(
                  context,
                  label: strings.supabaseUrlLabel,
                  hint: 'https://YOUR-PROJECT.supabase.co',
                  controller: _supabaseUrlController,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12.0),
                _field(
                  context,
                  label: strings.supabaseKeyLabel,
                  hint: 'eyJ...',
                  controller: _supabaseKeyController,
                ),
              ],
              if (_provider != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _provider == 'builtin'
                      ? '${strings.providerBuiltin} · ${ServerConfig.instance.allowSignup ? strings.signupOpen : strings.signupClosed}'
                      : strings.providerSupabase,
                  style: theme.bodySmall.override(
                    font: GoogleFonts.sourceSans3(),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _error!,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.sourceSans3(),
                    color: theme.error,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _status!,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.sourceSans3(),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
              const SizedBox(height: 20.0),
              SizedBox(
                height: 48.0,
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _save();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    _busy ? strings.testing : strings.testSave,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.bodyMedium.override(
            font: GoogleFonts.sourceSans3(fontWeight: FontWeight.w600),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          style: theme.bodyMedium.override(
            font: GoogleFonts.sourceSans3(),
            color: theme.primaryText,
            letterSpacing: 0.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.bodyMedium.override(
              font: GoogleFonts.sourceSans3(),
              color: theme.secondaryText,
              letterSpacing: 0.0,
            ),
            filled: true,
            fillColor: theme.primaryBackground,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(14.0, 14.0, 14.0, 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.alternate),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.alternate),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
