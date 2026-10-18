import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

const _blue = Color(0xFF0071E3);
const _red = Color(0xFFE5484D);

/// "Enter the code we emailed you" before a NEW Google/Apple account is
/// created (anti-bot). [submit] sends the same sign-up request with the
/// code; [resend] sends it again without one. Pops with the success body.
class SignupCodeScreen extends StatefulWidget {
  const SignupCodeScreen({
    super.key,
    required this.info,
    required this.submit,
    required this.resend,
  });

  /// The `needs_code` answer: message, email, expires_in, resend_in.
  final Map<String, dynamic> info;
  final Future<Response> Function(String code) submit;
  final Future<Response> Function() resend;

  @override
  State<SignupCodeScreen> createState() => _SignupCodeScreenState();
}

class _SignupCodeScreenState extends State<SignupCodeScreen> {
  final _code = TextEditingController();
  late String _message;
  int _expiresLeft = 600;
  int _resendLeft = 60;
  Timer? _tick;
  bool _busy = false;
  bool _resending = false;
  String? _error;
  bool _offerResend = false;

  int _int(dynamic v, int d) => int.tryParse("${v ?? ""}") ?? d;

  @override
  void initState() {
    super.initState();
    _apply(widget.info);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_expiresLeft > 0) _expiresLeft--;
        if (_resendLeft > 0) _resendLeft--;
        if (_expiresLeft == 0) _offerResend = true;
      });
    });
  }

  void _apply(Map info) {
    _message =
        (info["message"] ?? "").toString().isNotEmpty
            ? info["message"].toString()
            : "We emailed you a 6-digit code. Enter it to create your account.";
    _expiresLeft = _int(info["expires_in"], 600);
    _resendLeft = _int(info["resend_in"], 60);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _code.dispose();
    super.dispose();
  }

  String _mmss(int s) =>
      "${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  String _msg(Response r, String fallback) {
    final m = r.data is Map ? r.data as Map : const {};
    final s = (m["message"] ?? "").toString();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _verify() async {
    final c = _code.text.trim();
    if (c.length != 6 || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.submit(c);
      debugPrint("=== [signupCode] ${r.statusCode}: ${r.data}");
      if (!mounted) return;
      final code = r.statusCode ?? 0;
      final body =
          r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      if (code >= 200 && code < 300 && body["needs_code"] != true) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(body);
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() {
        _code.clear();
        if (code == 429) {
          _error = "Too many attempts. Please try again in an hour.";
        } else if (code == 503) {
          _error = "We could not send the email. Try again in a moment.";
        } else if (code == 401) {
          _error =
              "Your Google/Apple sign-in expired. Go back and sign in again.";
        } else {
          _error = _msg(r, "That code isn't right. Try again.");
          final low = _error!.toLowerCase();
          if (low.contains("expired") || low.contains("too many")) {
            _offerResend = true;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = "Check your internet connection and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resendLeft > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final r = await widget.resend();
      if (!mounted) return;
      final code = r.statusCode ?? 0;
      if (code == 429) {
        setState(
          () => _error = "Too many attempts. Please try again in an hour.",
        );
      } else if (code == 503) {
        setState(
          () =>
              _error = "We could not send the email. Try again in a moment.",
        );
      } else if (r.data is Map) {
        setState(() {
          _apply(r.data as Map);
          _offerResend = false;
          _code.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = "Check your internet connection and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final box = PinTheme(
      width: 48,
      height: 56,
      textStyle: ptstyle(size: 22, weight: 700, color: ch.onSurface),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        scrolledUnderElevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: _blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Check your email",
              style: ptstyle(
                size: 24,
                weight: 700,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.6),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              style: ptstyle(
                size: 13.5,
                weight: 400,
                color: ch.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Pinput(
                length: 6,
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                defaultPinTheme: box,
                focusedPinTheme: box.copyDecorationWith(
                  border: Border.all(color: _blue, width: 1.6),
                ),
                errorPinTheme: box.copyDecorationWith(
                  border: Border.all(color: _red, width: 1.6),
                ),
                forceErrorState: _error != null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: (_) => _verify(),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _expiresLeft > 0
                    ? "Code expires in ${_mmss(_expiresLeft)}"
                    : "This code has expired",
                style: ptstyle(
                  size: 12,
                  weight: 500,
                  color: _expiresLeft > 0 ? ch.onSurfaceVariant : _red,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: ptstyle(size: 12.5, weight: 600, color: _red),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: _blue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed:
                    _code.text.trim().length == 6 && !_busy ? _verify : null,
                child:
                    _busy
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          "Create my account",
                          style: ptstyle(
                            size: 15,
                            weight: 700,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _resendLeft > 0 || _resending ? null : _resend,
                child: Text(
                  _resending
                      ? "Sending…"
                      : _resendLeft > 0
                      ? "Resend code in ${_resendLeft}s"
                      : (_offerResend ? "Send a new code" : "Resend code"),
                  style: ptstyle(
                    size: 13.5,
                    weight: 600,
                    color:
                        _resendLeft > 0 ? ch.onSurfaceVariant : _blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
