import 'package:corextra/corextra.dart';

enum Role { admin, member }

/// A value with normal fields: `==`, `hashCode` and `toString` come from `fields`.
class GeoPoint with CorextraDataClass {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  Map<String, Object?> get fields => {'lat': lat, 'lng': lng};
}

class AddressModel with CorextraJsonModel {
  AddressModel.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  String? get city => read('city');
  double? get lat => read('lat');
  double? get lng => read('lng');

  // Built once from two fields, then reused.
  GeoPoint? get location => cached('location', () {
    final lat = this.lat;
    final lng = this.lng;
    return lat == null || lng == null ? null : GeoPoint(lat, lng);
  });
}

/// An API model with no constructor body, fromJson, toJson or copyWith written by hand.
class UserModel with CorextraJsonModel, CorextraSortable, CorextraValidatable {
  UserModel.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  int? get id => read('id');
  String get name => read('name') ?? '';
  String? get email => read('user_email', fallbackKeys: ['email']);
  Role get role => readEnum('role', Role.values) ?? Role.member;
  DateTime? get joinedAt => read('joined_at');
  AddressModel? get address => readModel('address', AddressModel.fromJson);

  @override
  List<Object?> get sortBy => [name];

  @override
  Map<String, String?> validate() => {
    'name': FormValidators.required(name),
    'email': FormValidators.email(email),
  };
}

/// A messy API response on purpose: ids as text, mixed key names and letter case.
const sampleUsersJson = [
  {
    'id': '7',
    'name': 'Ashiq',
    'email': 'ashiq@example.com',
    'role': 'ADMIN',
    'joined_at': '2026-01-15T10:00:00Z',
    'address': {'city': 'Dubai', 'lat': '25.2', 'lng': 55.27},
  },
  {'id': 3, 'name': 'Sara', 'user_email': 'sara@example.com'},
  {'id': 12.0, 'name': 'Ali', 'user_email': 'not-an-email'},
];
