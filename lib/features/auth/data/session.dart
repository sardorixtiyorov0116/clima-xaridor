/// Kirgan foydalanuvchi sessiyasi.
class Session {
  const Session({
    required this.userId,
    required this.accessToken,
    required this.phone,
    this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String? refreshToken;

  /// `+998901234567`
  final String phone;
}

class UserProfile {
  const UserProfile({required this.id, required this.phone, this.name, this.surname});

  final String id;
  final String phone;
  final String? name;
  final String? surname;

  bool get hasName => (name ?? '').trim().isNotEmpty;

  Map<String, Object?> toJson() => {'id': id, 'phone_number': phone, 'name': name, 'surname': surname};

  String get displayName =>
      [name, surname].where((s) => (s ?? '').trim().isNotEmpty).join(' ');

  String get initials {
    final parts = [name, surname].where((s) => (s ?? '').trim().isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.map((s) => s!.trim()[0].toUpperCase()).take(2).join();
  }

  /// Backend javobi bir xil emas (`name`/`first_name`, `client`/`user` ichida) —
  /// har ikkalasini qabul qilamiz.
  static UserProfile fromJson(Map<String, dynamic> j, {String? fallbackId, String? fallbackPhone}) {
    final src = (j['client'] ?? j['user'] ?? j['data'] ?? j) as Object;
    final m = src is Map<String, dynamic> ? src : j;
    String? s(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty && v.toString() != 'null') {
          return v.toString().trim();
        }
      }
      return null;
    }

    return UserProfile(
      id: s(['id', 'userId']) ?? fallbackId ?? '',
      phone: s(['phone_number', 'phone']) ?? fallbackPhone ?? '',
      name: _clean(s(['name', 'first_name', 'firstName'])),
      surname: _clean(s(['surname', 'last_name', 'lastName'])),
    );
  }

  /// Eski ro'yxatdan o'tish oqimi ism o'rniga telefonni yozib qo'ygan bo'lishi mumkin.
  static String? _clean(String? v) {
    if (v == null) return null;
    if (RegExp(r'^\+?\d[\d\s]{6,}$').hasMatch(v)) return null;
    return v;
  }
}
