import '/auth/builtin_auth/builtin_session.dart';
import '/custom_code/server/server_config.dart';
import '/custom_code/server/server_strings.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/profile/server_settings/server_settings_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'builtin_sign_in_model.dart';
export 'builtin_sign_in_model.dart';

class BuiltinSignInWidget extends StatefulWidget {
  const BuiltinSignInWidget({super.key});

  static String routeName = 'BuiltinSignIn';
  static String routePath = '/builtinSignIn';

  @override
  State<BuiltinSignInWidget> createState() => _BuiltinSignInWidgetState();
}

class _BuiltinSignInWidgetState extends State<BuiltinSignInWidget> {
  late BuiltinSignInModel _model;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BuiltinSignInModel());
    _signUp = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ServerStrings.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = strings.missingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = _signUp
          ? await BuiltinSession.instance.signUp(
              email,
              password,
              displayName: _nameController.text,
            )
          : await BuiltinSession.instance.signIn(email, password);
      FFAppState().updateUserStruct(
        (e) => e
          ..id = user.uid
          ..email = user.email
          ..name = user.displayName,
      );
      FFAppState().updateSettingStruct(
        (e) => e
          ..isGuest = false
          ..onboarded = true,
      );
      if (!mounted) return;
      GoRouter.of(context).prepareAuthEvent();
      context.go('/');
    } on BuiltinAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final strings = ServerStrings.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = strings.missingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final message = await BuiltinSession.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() => _notice = message);
    } on BuiltinAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final strings = ServerStrings.of(context);
    final allowSignup = ServerConfig.instance.allowSignup;
    final server = ServerConfig.instance.apiBaseUrl;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24.0, 48.0, 24.0, 32.0),
            children: [
              Text(
                _signUp ? strings.signUpTitle : strings.signInTitle,
                style: theme.headlineMedium.override(
                  font: GoogleFonts.sourceSans3(
                    fontWeight: FontWeight.w700,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                strings.serverLine(server),
                style: theme.bodyMedium.override(
                  font: GoogleFonts.sourceSans3(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 28.0),
              _field(
                context,
                label: strings.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12.0),
              _field(
                context,
                label: strings.password,
                controller: _passwordController,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
              ),
              if (_signUp) ...[
                const SizedBox(height: 12.0),
                _field(
                  context,
                  label: strings.displayName,
                  controller: _nameController,
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
              if (_notice != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _notice!,
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
                          _submit();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    _busy
                        ? strings.working
                        : (_signUp ? strings.signUp : strings.signIn),
                    style: GoogleFonts.sourceSans3(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              if (!_signUp)
                TextButton(
                  onPressed: _busy ? null : _forgot,
                  child: Text(
                    strings.forgotPassword,
                    style: GoogleFonts.sourceSans3(color: theme.secondaryText),
                  ),
                ),
              if (allowSignup)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                          }),
                  child: Text(
                    _signUp ? strings.haveAccount : strings.needAccount,
                    style: GoogleFonts.sourceSans3(color: theme.primaryText),
                  ),
                ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.pushNamed(ServerSettingsWidget.routeName),
                child: Text(
                  strings.changeServer,
                  style: GoogleFonts.sourceSans3(color: theme.secondaryText),
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
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: theme.bodyMedium.override(
        font: GoogleFonts.sourceSans3(),
        color: theme.primaryText,
        letterSpacing: 0.0,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.bodyMedium.override(
          font: GoogleFonts.sourceSans3(),
          color: theme.secondaryText,
          letterSpacing: 0.0,
        ),
        filled: true,
        fillColor: theme.primaryBackground,
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.secondaryText,
                ),
              ),
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
    );
  }
}
