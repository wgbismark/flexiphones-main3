import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/profile/add_phone.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _red = Color(0xFFE5484D);

/// A round profile picture: the photo, else the first letter.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 56,
    this.color = _blue,
  });
  final String name;
  final String? url;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final letter = Text(
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?",
      style: ptstyle(size: size * 0.4, weight: 700, color: color),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child:
          (url ?? "").isEmpty
              ? letter
              : Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => letter,
              ),
    );
  }
}

/// Edit profile for customers and agents: picture, name, phone and
/// address (agents also region and company). Sends only what changed;
/// 422 messages show under their field. Email can't be changed here.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.agent,
    this.complete = false,
    this.needsPhone = false,
    this.phoneAdvice,
  });

  /// After [complete]: go on to the (skippable) phone screen.
  final bool needsPhone;
  final String? phoneAdvice;
  final bool agent;

  /// After a Google/Apple sign-up with `needs_profile`: ask for the missing
  /// phone and address (agents: phone and region) and send them to
  /// auth/google/complete-profile.
  final bool complete;

  static void open(BuildContext context, {required bool agent}) =>
      Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => EditProfileScreen(agent: agent)),
      );

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final SharedProvider p = Provider.of<SharedProvider>(
    context,
    listen: false,
  );
  final _c = <String, TextEditingController>{};
  final _initial = <String, String>{};
  Map<String, String> _errors = {};
  bool _saving = false;
  bool _photoBusy = false;
  String? _photo;
  String _email = "";

  List<String> get _fields =>
      widget.complete
          ? (widget.agent ? const ["region"] : const ["address"])
          : widget.agent
          ? const ["name", "phone", "region", "company", "address"]
          : const ["name", "phone", "address"];

  String? get _token =>
      widget.agent ? p.partnerData?.token : p.userData?.token;

  Options get _opts => Options(
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $_token",
    },
    validateStatus: (_) => true,
  );

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _c[f] = TextEditingController()..addListener(() => setState(() {}));
    }
    if (widget.agent) {
      final a = p.partnerData;
      _fill({
        "name": a?.name ?? "",
        "phone": a?.phone ?? "",
        "region": a?.region ?? "",
        "company": a?.company ?? "",
        "address": a?.address ?? "",
      });
      _photo = a?.photoUrl;
      _email = a?.email ?? "";
      _loadAgent();
    } else {
      final u = p.userData?.data;
      _fill({
        "name": u?.name ?? "",
        "phone": _local(u?.phone ?? ""),
        "address": u?.address ?? "",
      });
      _photo = u?.profilePhoto;
      _email = u?.email ?? "";
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// "+233241234567" -> "0241234567" for editing.
  String _local(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith("233") && d.length == 12) return "0${d.substring(3)}";
    return phone;
  }

  void _fill(Map<String, String> v) {
    for (final e in v.entries) {
      _c[e.key]?.text = e.value;
      _initial[e.key] = e.value;
    }
  }

  Future<void> _loadAgent() async {
    try {
      final r = await p.dio.get(ApiUrls.partnerProfile, options: _opts);
      final d = r.data is Map ? r.data["data"] : null;
      if (r.statusCode == 200 && d is Map && mounted) {
        final m = Map<String, dynamic>.from(d);
        setState(() {
          _fill({
            "name": "${m["name"] ?? ""}",
            "phone": _local("${m["phone"] ?? ""}"),
            "region": "${m["region"] ?? ""}",
            "company": "${m["company"] ?? ""}",
            "address": "${m["address"] ?? ""}",
          });
          _photo = (m["photo_url"] ?? m["google_photo"])?.toString();
          _email = "${m["email"] ?? _email}";
        });
        await p.applyAgentProfile(m);
      }
    } catch (_) {}
  }

  Map<String, String> get _changes => {
    for (final f in _fields)
      if (_c[f]!.text.trim() != (_initial[f] ?? "").trim())
        f: _c[f]!.text.trim(),
  };

  bool get _ready =>
      widget.complete
          ? _fields.every((f) => _c[f]!.text.trim().isNotEmpty)
          : _changes.isNotEmpty;

  Future<void> _save() async {
    final changes = _changes;
    if (!_ready || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final r = await p.dio.post(
        widget.complete
            ? ApiUrls.googleCompleteProfilePST
            : widget.agent
            ? ApiUrls.partnerProfileUpdate
            : ApiUrls.customerProfileUpdate,
        data:
            widget.complete
                ? {
                  for (final f in _fields) f: _c[f]!.text.trim(),
                  "as": widget.agent ? "agent" : "customer",
                }
                : changes,
        options: _opts,
      );
      debugPrint("=== [profileUpdate] ${r.statusCode}: ${r.data}");
      if (!mounted) return;
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200) {
        final d = body["data"];
        if (d is Map) await _store(Map<String, dynamic>.from(d));
        for (final f in changes.keys) {
          _initial[f] = _c[f]!.text.trim();
        }
        HapticFeedback.mediumImpact();
        if (widget.complete) {
          if (widget.needsPhone) {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder:
                    (_) => AddPhoneScreen(
                      agent: widget.agent,
                      advice: widget.phoneAdvice,
                    ),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("${body["message"] ?? "Profile updated."}"),
          ),
        );
        setState(() {});
      } else if (r.statusCode == 422 && body["errors"] is Map) {
        setState(() {
          _errors = {
            for (final e in (body["errors"] as Map).entries)
              "${e.key}":
                  e.value is List && (e.value as List).isNotEmpty
                      ? "${(e.value as List).first}"
                      : "${e.value}",
          };
        });
      } else {
        _snack("${body["message"] ?? "Couldn't save. Try again."}");
      }
    } catch (_) {
      _snack("Check your internet connection and try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Keep the app's copy of the profile in step with the server.
  Future<void> _store(Map<String, dynamic> data) async {
    if (widget.agent) {
      await p.applyAgentProfile(data);
      return;
    }
    try {
      final raw = await DS.storage.read(key: "user");
      if (raw == null) return;
      final saved = Map<String, dynamic>.from(jsonDecode(raw));
      final old =
          saved["data"] is Map
              ? Map<String, dynamic>.from(saved["data"])
              : <String, dynamic>{};
      saved["data"] = {...old, ...data};
      await DS.storage.write(key: "user", value: jsonEncode(saved));
      await p.getUserDetails();
    } catch (e) {
      debugPrint("!!! [profileStore] $e");
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(behavior: SnackBarBehavior.floating, content: Text(m)),
  );

  String get _photoUrl =>
      widget.agent ? ApiUrls.partnerPhoto : ApiUrls.customerPhoto;

  Future<void> _pickPhoto() async {
    final ch = Theme.of(context).colorScheme;
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: ch.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text("Choose from photos"),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text("Take a photo"),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  if ((_photo ?? "").isNotEmpty)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: _red,
                      ),
                      title: const Text(
                        "Remove picture",
                        style: TextStyle(color: _red),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _removePhoto();
                      },
                    ),
                ],
              ),
            ),
          ),
    );
    if (source == null) return;
    final img = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (img == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      final form = FormData.fromMap({
        "photo": await MultipartFile.fromFile(
          img.path,
          filename: "photo.jpg",
        ),
      });
      final r = await p.dio.post(_photoUrl, data: form, options: _opts);
      debugPrint("=== [photo] ${r.statusCode}: ${r.data}");
      final body = r.data is Map ? r.data as Map : const {};
      final url = body["data"] is Map ? body["data"]["photo_url"] : null;
      if (r.statusCode == 200 && url != null) {
        setState(() => _photo = "$url");
        await _store({"photo_url": "$url", "profile_photo": "$url"});
      } else {
        final errs = body["errors"];
        _snack(
          errs is Map && errs["photo"] is List
              ? "${(errs["photo"] as List).first}"
              : "${body["message"] ?? "Couldn't upload the picture."}",
        );
      }
    } catch (_) {
      _snack("Couldn't upload the picture. Try again.");
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoBusy = true);
    try {
      final r = await p.dio.delete(_photoUrl, options: _opts);
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200) {
        final url = body["data"] is Map ? body["data"]["photo_url"] : null;
        setState(() => _photo = url?.toString());
        await _store({"photo_url": url, "profile_photo": url});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final changed = _ready;
    const labels = {
      "name": "Full name",
      "phone": "Phone number",
      "region": "Region",
      "company": "Company (optional)",
      "address": "Address",
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.complete,
        title: Text(
          widget.complete ? "Finish your profile" : "Edit profile",
          style: ptstyle(size: 16, weight: 600),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Center(
              child: GestureDetector(
                onTap: _photoBusy ? null : _pickPhoto,
                child: Stack(
                  children: [
                    ProfileAvatar(
                      name:
                          _c["name"]?.text ??
                          (widget.agent
                              ? p.partnerData?.name
                              : p.userData?.data.name) ??
                          "",
                      url: _photo,
                      size: 96,
                    ),
                    if (_photoBusy)
                      const Positioned.fill(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF5F6F8),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Tap to change your picture",
                style: ptstyle(
                  size: 12,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final f in _fields)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextField(
                        controller: _c[f],
                        keyboardType:
                            f == "phone"
                                ? TextInputType.phone
                                : TextInputType.text,
                        textCapitalization:
                            f == "phone"
                                ? TextCapitalization.none
                                : TextCapitalization.words,
                        maxLines: f == "address" ? 2 : 1,
                        minLines: 1,
                        decoration: InputDecoration(
                          labelText: labels[f],
                          errorText: _errors[f],
                          border: InputBorder.none,
                          labelStyle: ptstyle(
                            size: 13,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                        style: ptstyle(
                          size: 15,
                          weight: 500,
                          color: ch.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: ch.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _email,
                          style: ptstyle(
                            size: 14,
                            weight: 500,
                            color: ch.onSurface,
                          ),
                        ),
                        Text(
                          "Your sign-in email. Contact support to change it.",
                          style: ptstyle(
                            size: 11,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: ch.onSurfaceVariant,
                  ),
                ],
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
                onPressed: changed && !_saving ? _save : null,
                child:
                    _saving
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          "Save",
                          style: ptstyle(
                            size: 15,
                            weight: 700,
                            color: Colors.white,
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
