import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';

abstract class PatientSessionVault {
  Future<String?> read();
  Future<void> write(String value);
}
class SecurePatientSessionVault implements PatientSessionVault {
  SecurePatientSessionVault(this.namespace);
  final String namespace;
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  String? _webValue;
  String get _key => 'digital_lab_patient_sessions_v1_' + Uri.encodeComponent(namespace);
  @override Future<String?> read() async {
    if (kIsWeb) return _webValue;
    return await _storage.read(key: _key);
  }
  @override Future<void> write(String value) async {
    if (kIsWeb) { _webValue = value; } else { await _storage.write(key: _key, value: value); }
  }
}
class LinkedPatient {
  LinkedPatient({required this.token, required this.patientId, required this.labId,
    required this.name, required this.labName, required this.expiresAt});
  final String token, name, labName;
  final int patientId, labId;
  final DateTime expiresAt;
  String get key => '$labId:$patientId';
  factory LinkedPatient.fromJson(Map<String, dynamic> json) => LinkedPatient(
    token: json['token'] as String, patientId: (json['patient']['id'] as num).toInt(),
    labId: (json['lab']['id'] as num).toInt(), name: (json['patient']['name'] ?? '').toString(),
    labName: (json['lab']['name'] ?? '').toString(), expiresAt: DateTime.parse(json['expires_at'] as String));
  Map<String, dynamic> toJson() => {'token':token, 'patient':{'id':patientId,'name':name},
    'lab':{'id':labId,'name':labName},'expires_at':expiresAt.toUtc().toIso8601String()};
}
class LinkedPatientStore extends ChangeNotifier {
  LinkedPatientStore(this.api, this.vault);
  final PatientApi api;
  final PatientSessionVault vault;
  List<LinkedPatient> profiles = [];
  LinkedPatient? selected;
  Map<String, dynamic>? overview;
  List<Map<String, dynamic>> reports = [], ledger = [];
  int? nextReports, nextPoints;
  bool restoring = true, loading = false, paging = false, linking = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  void changed() { if (!_disposed) notifyListeners(); }
  Future<void> restore() async {
    try {
      final saved = await vault.read();
      if (_disposed) return;
      if (saved != null) {
        profiles = (jsonDecode(saved) as List).map((j) => LinkedPatient.fromJson(Map<String,dynamic>.from(j)))
            .where((p) => p.expiresAt.isAfter(DateTime.now())).toList();
      }
    } catch (_) { error = 'تعذر استرجاع الربط المحفوظ. يمكنك ربط ملفك من جديد.'; }
    restoring = false; changed();
    if (profiles.isNotEmpty) await select(profiles.first);
  }
  Future<void> _save(List<LinkedPatient> next) => vault.write(jsonEncode(next.map((p)=>p.toJson()).toList()));
  Future<void> link(String phone, String code) async {
    if (linking) return;
    linking = true; error = null; changed();
    try {
      final data = await api.call('POST','exchange',body:{'phone':phone,'code':code});
      final profile = LinkedPatient.fromJson(data);
      final previous = profiles.where((p)=>p.key==profile.key).firstOrNull;
      final next = [...profiles.where((p)=>p.key!=profile.key),profile];
      try { await _save(next); }
      catch (_) {
        try { await api.call('DELETE','session',token:profile.token); } catch (_) {}
        throw const PatientApiException(0,'تعذر حفظ الربط بأمان. أنشئ رمزاً جديداً وحاول مرة أخرى.');
      }
      if (_disposed) return;
      profiles = next;
      if (previous != null) { try { await api.call('DELETE','session',token:previous.token); } catch (_) {} }
      await select(profile);
    } on PatientApiException catch (e) { error = e.message; rethrow; }
    catch (_) {
      error = 'تعذر إكمال الربط. خذ رمزاً جديداً من البوابة وحاول مرة أخرى.';
      throw PatientApiException(0,error!);
    } finally { linking = false; changed(); }
  }
  Future<void> select(LinkedPatient profile) async {
    final generation = ++_generation;
    selected = profile; overview = null; reports = []; ledger = [];
    nextReports = null; nextPoints = null; loading = true; paging = false; error = null; changed();
    try {
      final data = await api.call('GET','me',token:profile.token);
      final points = await api.call('GET','points',token:profile.token);
      if (_disposed || generation != _generation) return;
      overview = data; reports = _items(data['reports']);
      nextReports = data['reports']['next_page'] as int?;
      ledger = _items(points); nextPoints = points['next_page'] as int?;
    } on PatientApiException catch (e) {
      if (generation != _generation || _disposed) return;
      error = e.message;
      if (e.status == 401) await _forget(profile);
    } catch (_) { if (generation == _generation) error = 'تعذر تحميل الملف. أعد المحاولة.'; }
    finally { if (generation == _generation) { loading = false; changed(); } }
  }
  List<Map<String,dynamic>> _items(dynamic data) =>
      (data['items'] as List).map((j)=>Map<String,dynamic>.from(j)).toList();
  Future<void> more({bool points = false}) async {
    final page = points ? nextPoints : nextReports, profile = selected;
    final generation = _generation;
    if (page == null || profile == null || paging) return;
    paging = true; error = null; changed();
    try {
      final path = (points ? 'points':'reports') + '?page=$page';
      final data = await api.call('GET',path,token:profile.token);
      if (_disposed || generation != _generation) return;
      if (points) { ledger.addAll(_items(data)); nextPoints = data['next_page'] as int?; }
      else { reports.addAll(_items(data)); nextReports = data['next_page'] as int?; }
    } on PatientApiException catch (e) {
      if (generation == _generation) { error = e.message; if (e.status == 401) await _forget(profile); }
    } catch (_) { if (generation == _generation) error = 'تعذر تحميل المزيد. أعد المحاولة.'; }
    finally { if (generation == _generation) { paging = false; changed(); } }
  }
  Future<void> _forget(LinkedPatient profile) async {
    profiles = profiles.where((p)=>p.token!=profile.token).toList();
    if (selected?.token == profile.token) {
      selected = null; overview = null; reports = []; ledger = []; nextReports = null; nextPoints = null;
    }
    try { await _save(profiles); } catch (_) { error = 'تعذر تحديث التخزين الآمن. الجلسة غير صالحة على السيرفر.'; }
  }
  Future<void> logout() async {
    final profile = selected;
    if (profile == null) return;
    error = null; loading = true; changed();
    try {
      try { await api.call('DELETE','session',token:profile.token); }
      on PatientApiException catch (e) { if (e.status != 401) rethrow; }
      ++_generation; await _forget(profile); loading = false; changed();
      if (profiles.isNotEmpty) await select(profiles.first);
    } on PatientApiException catch (e) { error = e.message; loading = false; changed(); }
  }
  @override void dispose() { _disposed = true; _generation++; api.close(); super.dispose(); }
}
