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

/// A nested model, read with `readModel` and `readModelList`.
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

/// An API model: one line per field, plus the optional extras most models don't need.
class UserModel with CorextraJsonModel, CorextraSortable, CorextraValidatable {
  // ---------------- Constructors ----------------

  UserModel.fromJson(this.json);

  // Optional: build a user in code with typed values.
  UserModel({int? id, String? name, String? email})
    : json = {'id': id, 'name': name, 'user_email': email};

  @override
  final Map<String, dynamic> json;

  // ---------------- Fields ----------------

  int? get id => read('id');
  String get name => read('name') ?? '';
  String? get email => read('user_email', fallbackKeys: ['email']);
  Role get role => readEnum('role', Role.values) ?? Role.member;
  String? get teamName => read('team.name');
  String? get theme => read('settings.theme');

  // ---------------- Dates ----------------

  DateTime? get joinedAt => read('joined_at');
  DateTime? get lastSeen => read('last_seen');
  DateTime? get checkIn => readDate('check_in_time', format: 'HH:mm:ss');

  // ---------------- Lists and nested models ----------------

  List<String>? get tags => readList('tags');
  AddressModel? get address => readModel('address', AddressModel.fromJson);
  List<AddressModel>? get pastAddresses =>
      readModelList('past_addresses', AddressModel.fromJson);

  // ---------------- Changing ----------------

  // Optional: a field you change in place.
  set name(String value) => write('name', value);

  // Optional: a changed copy, listing only the fields you change.
  UserModel copyWith({String? name, Role? role}) =>
      UserModel.fromJson({...toJson(), 'name': ?name, 'role': ?role});

  // ---------------- Sorting and validation ----------------

  @override
  List<Object?> get sortBy => [name];

  @override
  Map<String, String?> validate() => {
    'name': FormValidators.required(name),
    'email': FormValidators.email(email),
  };
}

/// A messy API response on purpose: ids as text, mixed key names and letter case, JSON sent as text, and a junk list item.
const sampleUsersJson = [
  {
    'id': '7',
    'name': 'Ashiq',
    'email': 'ashiq@example.com',
    'role': 'ADMIN',
    'team': {'name': 'Dubai Smashers'},
    'settings': '{"theme": "dark"}',
    'joined_at': '2026-01-15T10:00:00Z',
    'last_seen': 1767225600,
    'check_in_time': '09:30:00',
    'tags': '["padel", "coach"]',
    'address': {'city': 'Dubai', 'lat': '25.2', 'lng': 55.27},
    'past_addresses': [
      {'city': 'Doha'},
      'junk',
      {'city': 'Muscat'},
    ],
  },
  {'id': 3, 'name': 'Sara', 'user_email': 'sara@example.com'},
  {'id': 12.0, 'name': 'Ali', 'user_email': 'not-an-email'},
];
