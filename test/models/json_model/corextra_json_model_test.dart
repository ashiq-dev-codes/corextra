import 'package:corextra/corextra.dart';
import 'package:corextra/models/util/json_warnings.dart';
import 'package:flutter_test/flutter_test.dart';

enum Role { admin, member }

class Address with CorextraJsonModel {
  Address.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  String? get city => read('city');
  set city(String? value) => write('city', value);
}

class User with CorextraJsonModel {
  User.fromJson(this.json);

  User({int? id, String? name}) : json = {'id': id, 'name': name};

  @override
  final Map<String, dynamic> json;

  int? get id => read('id');
  int? get explicitNullable => read<int?>('id');
  String get name => read('name') ?? '';
  set name(String value) => write('name', value);
  double? get wallet => read('wallet');
  num? get score => read('score');
  bool? get isNew => read('is_new');
  DateTime? get joinedAt => read('joined_at');
  set joinedAt(DateTime? value) => write('joined_at', value);
  Map<String, dynamic>? get meta => read('meta');
  Role? get role => readEnum('role', Role.values);
  set role(Role? value) => write('role', value);
  List<String>? get tags => readList('tags');
  List<int>? get scores => readList('scores');
  Address? get address => readModel('address', Address.fromJson);
  set address(Address? value) => write('address', value);
  List<Address>? get addresses => readModelList('addresses', Address.fromJson);
  String? get email => read('user_email', fallbackKeys: ['email', 'userEmail']);
  set email(String? value) => write('user_email', value);
  Address? get home =>
      readModel('home', Address.fromJson, fallbackKeys: ['home_address']);
  set user(Map<String, dynamic>? value) => write('user', value);
  String? get userName => read('user.name');
  double? get userRating =>
      read('user.red_padel_rating', fallbackKeys: ['user.rating']);
  Address? get userAddress => readModel('user.address', Address.fromJson);
  String? get plan => read('settings.plan');
  String? get dottedKey => read('a.b');
  Address? get meta2 => readModel('meta_text', Address.fromJson);
  List<String>? get weekdays => readList('weekdays');
  List<Address>? get places => readModelList('places', Address.fromJson);
  DateTime? get startsAt => read('starts_at');
  DateTime? get startTime => readDate('start_time', format: 'HH:mm:ss');
  set startTime(DateTime? value) => write('start_time', value);

  int buildCount = 0;
  String get greeting => cached('greeting', () {
    buildCount++;
    return 'Hi $name';
  });
}

class Broken with CorextraJsonModel {
  Broken.fromJson(this.json) {
    if (json['fail'] == true) throw const FormatException('bad data');
  }

  @override
  final Map<String, dynamic> json;
}

class Holder with CorextraJsonModel {
  Holder.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  Broken? get item => readModel('item', Broken.fromJson);
}

class Coupon with CorextraJsonModel {
  Coupon.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  int? get id => read('id');

  @override
  bool operator ==(Object other) => other is Coupon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class BaseEntity {
  String get kind => 'entity';
}

class Court extends BaseEntity with CorextraJsonModel {
  Court.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  String? get name => read('name');
}

void main() {
  group('read', () {
    test('reads the type from the getter and accepts loose values', () {
      final user = User.fromJson({
        'id': '7',
        'wallet': 12,
        'score': '4.5',
        'is_new': 1,
        'joined_at': '2026-01-15T10:00:00.000Z',
        'meta': {'plan': 'pro'},
      });
      expect(user.id, 7);
      expect(user.explicitNullable, 7);
      expect(user.wallet, 12.0);
      expect(user.score, 4.5);
      expect(user.isNew, isTrue);
      expect(user.joinedAt, DateTime.utc(2026, 1, 15, 10));
      expect(user.meta, {'plan': 'pro'});
    });

    test('accepts whole doubles for ints but never drops a fraction', () {
      expect(User.fromJson({'id': 7.0}).id, 7);
      expect(User.fromJson({'id': '7.0'}).id, 7);
      expect(User.fromJson({'id': 7.5}).id, isNull);
    });

    test('reads booleans from common API shapes', () {
      for (final value in [true, 'true', 'TRUE', 1, 1.0, '1', 'yes', ' Yes ']) {
        expect(
          User.fromJson({'is_new': value}).isNew,
          isTrue,
          reason: '$value',
        );
      }
      for (final value in [false, 'false', 0, '0', 'no']) {
        expect(
          User.fromJson({'is_new': value}).isNew,
          isFalse,
          reason: '$value',
        );
      }
      expect(User.fromJson({'is_new': 'maybe'}).isNew, isNull);
      expect(User.fromJson({'is_new': 2}).isNew, isNull);
    });

    test('turns numbers into text but never maps or lists', () {
      expect(User.fromJson({'name': 42}).name, '42');
      expect(
        User.fromJson({
          'name': {'first': 'A'},
        }).name,
        '',
      );
      expect(
        User.fromJson({
          'name': ['A'],
        }).name,
        '',
      );
    });

    test('returns null for missing or wrong values instead of throwing', () {
      final user = User.fromJson({'id': 'abc', 'joined_at': 'yesterday'});
      expect(user.id, isNull);
      expect(user.joinedAt, isNull);
      expect(user.wallet, isNull);
      expect(user.name, '');
      expect(User.fromJson({}).tags, isNull);
    });

    test('tries fallbackKeys in order until one has a usable value', () {
      expect(User.fromJson({'user_email': 'a@x.com'}).email, 'a@x.com');
      expect(User.fromJson({'email': 'b@x.com'}).email, 'b@x.com');
      expect(User.fromJson({'userEmail': 'c@x.com'}).email, 'c@x.com');
      expect(
        User.fromJson({'user_email': null, 'email': 'b@x.com'}).email,
        'b@x.com',
      );
      final home =
          User.fromJson({
            'home': 'not a map',
            'home_address': {'city': 'Dubai'},
          }).home;
      expect(home?.city, 'Dubai');
    });
  });

  group('lists, models and enums', () {
    test('readList converts items and skips the ones that do not fit', () {
      final user = User.fromJson({
        'tags': ['a', 'b'],
        'scores': [1, '2', 3.0, 'x', 4.5, null],
      });
      expect(user.tags, ['a', 'b']);
      expect(user.scores, [1, 2, 3]);
      expect(User.fromJson({'tags': 'a,b'}).tags, isNull);
    });

    test('readModel parses nested models once', () {
      final user = User.fromJson({
        'address': {'city': 'Dubai'},
      });
      expect(user.address?.city, 'Dubai');
      expect(identical(user.address, user.address), isTrue);
      expect(User.fromJson({'address': 'Dubai'}).address, isNull);
    });

    test('readModel accepts maps with non-string keys', () {
      final user = User.fromJson({
        'address': <dynamic, dynamic>{'city': 'Doha'},
      });
      expect(user.address?.city, 'Doha');
    });

    test('readModel returns null when the nested fromJson throws', () {
      expect(
        Holder.fromJson({
          'item': {'fail': true},
        }).item,
        isNull,
      );
      expect(Holder.fromJson({'item': <String, dynamic>{}}).item, isNotNull);
    });

    test('readModelList skips invalid items', () {
      final user = User.fromJson({
        'addresses': [
          {'city': 'Dubai'},
          'junk',
          null,
          {'city': 'Doha'},
        ],
      });
      expect(user.addresses?.map((a) => a.city), ['Dubai', 'Doha']);
    });

    test('readEnum matches names in any letter case', () {
      expect(User.fromJson({'role': 'admin'}).role, Role.admin);
      expect(User.fromJson({'role': ' MEMBER '}).role, Role.member);
      expect(User.fromJson({'role': 'owner'}).role, isNull);
      expect(User.fromJson({'role': 1}).role, isNull);
    });
  });

  group('nested paths', () {
    test('a dotted key reads inside nested maps', () {
      final user = User.fromJson({
        'user': {
          'name': 'Ashiq',
          'rating': '4.5',
          'address': {'city': 'Dubai'},
        },
      });
      expect(user.userName, 'Ashiq');
      expect(user.userRating, 4.5);
      expect(user.userAddress?.city, 'Dubai');
    });

    test('a missing or wrong-shaped parent reads as null', () {
      expect(User.fromJson({}).userName, isNull);
      expect(User.fromJson({'user': 'Ashiq'}).userName, isNull);
      expect(
        User.fromJson({
          'user': ['Ashiq'],
        }).userName,
        isNull,
      );
    });

    test('an exact key with a dot wins over the path', () {
      final user = User.fromJson({
        'a.b': 'exact',
        'a': {'b': 'nested'},
      });
      expect(user.dottedKey, 'exact');
    });

    test('a path walks through JSON sent as text', () {
      expect(User.fromJson({'settings': '{"plan": "pro"}'}).plan, 'pro');
    });

    test('writing the parent updates path reads', () {
      final user = User.fromJson({
        'user': {'name': 'Ashiq'},
      });
      expect(user.userName, 'Ashiq');
      user.user = {'name': 'Ali'};
      expect(user.userName, 'Ali');
    });
  });

  group('JSON sent as text', () {
    test('a nested model can arrive as text', () {
      expect(
        User.fromJson({'meta_text': '{"city": "Dubai"}'}).meta2?.city,
        'Dubai',
      );
    });

    test('lists can arrive as text', () {
      final user = User.fromJson({
        'weekdays': '["mon", "tue"]',
        'places': '[{"city": "Dubai"}]',
      });
      expect(user.weekdays, ['mon', 'tue']);
      expect(user.places?.single.city, 'Dubai');
    });

    test('broken JSON text reads as null without throwing', () {
      final user = User.fromJson({'meta_text': '{not json', 'weekdays': '['});
      expect(user.meta2, isNull);
      expect(user.weekdays, isNull);
    });

    test('a text field that looks like JSON stays text', () {
      expect(User.fromJson({'name': '[draft] hello'}).name, '[draft] hello');
      expect(User.fromJson({'name': '[1, 2]'}).name, '[1, 2]');
    });

    test('toJson sends untouched text back unchanged', () {
      const text = '{ "city" : "Dubai" }';
      final user = User.fromJson({'meta_text': text});
      expect(user.meta2?.city, 'Dubai');
      expect(user.toJson()['meta_text'], text);
    });

    test('toJson sends a changed nested model back as text', () {
      final user = User.fromJson({'meta_text': '{"city": "Dubai"}'});
      user.meta2?.city = 'Doha';
      expect(user.toJson()['meta_text'], '{"city":"Doha"}');
    });
  });

  group('dates', () {
    test('reads Unix timestamps in seconds or milliseconds', () {
      final expected = DateTime.fromMillisecondsSinceEpoch(1751328000000);
      expect(User.fromJson({'starts_at': 1751328000}).startsAt, expected);
      expect(User.fromJson({'starts_at': '1751328000'}).startsAt, expected);
      expect(User.fromJson({'starts_at': 1751328000000}).startsAt, expected);
    });

    test('reads ISO dates and ignores bad values', () {
      expect(
        User.fromJson({'starts_at': '2026-01-15T10:00:00Z'}).startsAt,
        DateTime.utc(2026, 1, 15, 10),
      );
      expect(User.fromJson({'starts_at': 'soon'}).startsAt, isNull);
      expect(User.fromJson({'starts_at': 1e300}).startsAt, isNull);
    });

    test('readDate reads a custom format', () {
      final time = User.fromJson({'start_time': '18:30:00'}).startTime;
      expect(time?.hour, 18);
      expect(time?.minute, 30);
      expect(User.fromJson({'start_time': 'late'}).startTime, isNull);
    });

    test('readDate returns a date set with a setter', () {
      final user = User.fromJson({'start_time': '18:30:00'});
      user.startTime = DateTime(2026, 1, 1, 9);
      expect(user.startTime, DateTime(2026, 1, 1, 9));
    });
  });

  group('cached and write', () {
    test('cached builds once and rebuilds after a write', () {
      final user = User.fromJson({'name': 'Ashiq'});
      expect(user.greeting, 'Hi Ashiq');
      expect(user.greeting, 'Hi Ashiq');
      expect(user.buildCount, 1);
      user.name = 'Ali';
      expect(user.greeting, 'Hi Ali');
      expect(user.buildCount, 2);
    });

    test('write never modifies the original json, even a const one', () {
      const source = {'name': 'Ashiq'};
      final user = User.fromJson(source);
      user.name = 'Ali';
      expect(user.name, 'Ali');
      expect(source['name'], 'Ashiq');
      expect(user.toJson()['name'], 'Ali');
    });

    test('changing a map read from the model leaves the json untouched', () {
      final source = <String, dynamic>{
        'meta': {'plan': 'pro'},
      };
      User.fromJson(source).meta?['plan'] = 'free';
      expect(source['meta'], {'plan': 'pro'});
    });

    test('a written null wins over fallbackKeys', () {
      final user = User.fromJson({'email': 'b@x.com'});
      user.email = null;
      expect(user.email, isNull);
    });
  });

  group('toJson', () {
    test('converts nested models, dates and enums to plain JSON', () {
      final user = User.fromJson({'id': 1});
      user.role = Role.admin;
      user.joinedAt = DateTime.utc(2026, 1, 15);
      user.address = Address.fromJson({'city': 'Dubai'});
      expect(user.toJson(), {
        'id': 1,
        'role': 'admin',
        'joined_at': '2026-01-15T00:00:00.000Z',
        'address': {'city': 'Dubai'},
      });
    });

    test('includes changes made inside nested models', () {
      final user = User.fromJson({
        'address': {'city': 'Dubai'},
      });
      user.address?.city = 'Doha';
      expect(user.toJson()['address'], {'city': 'Doha'});
    });

    test('includes changes made inside a list of nested models', () {
      final user = User.fromJson({
        'addresses': [
          {'city': 'Dubai'},
        ],
      });
      user.addresses?.first.city = 'Doha';
      expect(user.toJson()['addresses'], [
        {'city': 'Doha'},
      ]);
    });

    test('gives the same output whether or not a getter ran', () {
      final json = {
        'id': '7',
        'scores': ['1', 2],
        'meta': {'plan': 'pro'},
      };
      final untouched = User.fromJson(json).toJson();
      final read = User.fromJson(json);
      read
        ..id
        ..scores
        ..meta;
      expect(read.toJson(), untouched);
      expect(untouched, json);
    });

    test('keeps keys the model does not declare', () {
      expect(User.fromJson({'extra': 'kept'}).toJson()['extra'], 'kept');
    });

    test('returns a copy that cannot change the model', () {
      final user = User.fromJson({
        'meta': {'plan': 'pro'},
      });
      (user.toJson()['meta'] as Map)['plan'] = 'free';
      expect(user.toJson()['meta'], {'plan': 'pro'});
    });

    test('a typed constructor round-trips', () {
      final user = User(id: 3, name: 'Sara');
      expect(User.fromJson(user.toJson()), user);
    });

    test('copyWith is a spread over toJson, and can clear a field', () {
      final user = User.fromJson({'id': 1, 'name': 'Ashiq'});
      final copy = User.fromJson({...user.toJson(), 'name': 'Ali'});
      expect(copy.name, 'Ali');
      expect(copy.id, 1);
      expect(User.fromJson({...user.toJson(), 'id': null}).id, isNull);
    });
  });

  group('equality and toString', () {
    test('equal when the data matches', () {
      final a = User.fromJson({
        'id': 1,
        'tags': ['a'],
      });
      final b = User.fromJson({
        'id': 1,
        'tags': ['a'],
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
      expect(a == User.fromJson({'id': 2}), isFalse);
    });

    test('different model types are never equal', () {
      expect(
        Address.fromJson({'city': 'Dubai'}),
        isNot(Court.fromJson({'city': 'Dubai'})),
      );
    });

    test('a class can override equality, for example by id', () {
      expect(
        Coupon.fromJson({'id': 1, 'code': 'A'}),
        Coupon.fromJson({'id': 1}),
      );
    });

    test('toString shows the type and data', () {
      expect(User.fromJson({'id': 1}).toString(), 'User{id: 1}');
    });
  });

  test('leaves extends free for another base class', () {
    final court = Court.fromJson({'name': 'Center'});
    expect(court.kind, 'entity');
    expect(court.name, 'Center');
  });

  group('debug warnings', () {
    final messages = <String>[];
    final originalSink = jsonModelWarningSink;

    setUp(() {
      messages.clear();
      resetJsonModelWarnings();
      CorextraJsonModel.debugWarnings = true;
      jsonModelWarningSink = (message) => messages.add(message());
    });

    tearDown(() {
      jsonModelWarningSink = originalSink;
      CorextraJsonModel.debugWarnings = true;
    });

    test('a value that exists but cannot be read warns with a clear message', () {
      expect(User.fromJson({'id': 'abc'}).id, isNull);
      expect(messages, [
        'User: "id" should be int, but the JSON has text "abc". It reads as null.',
      ]);
    });

    test('warns once per model type and key, not once per model', () {
      for (var i = 0; i < 3; i++) {
        User.fromJson({'id': 'abc'}).id;
      }
      expect(messages, hasLength(1));
    });

    test('missing, blank and valid values never warn', () {
      User.fromJson({}).id;
      User.fromJson({'id': '  '}).id;
      User.fromJson({'id': '7'}).id;
      expect(messages, isEmpty);
    });

    test('a nested fromJson that throws warns with the reason', () {
      Holder.fromJson({
        'item': {'fail': true},
      }).item;
      expect(messages.single, contains('Holder: "item" should be Broken'));
      expect(messages.single, contains('bad data'));
    });

    test('can be turned off', () {
      CorextraJsonModel.debugWarnings = false;
      User.fromJson({'id': 'abc'}).id;
      expect(messages, isEmpty);
    });
  });

  group('self-checking cache', () {
    test('notices when the original json changes after a read', () {
      final source = <String, dynamic>{'name': 'Ashiq'};
      final user = User.fromJson(source);
      expect(user.name, 'Ashiq');
      source['name'] = 'Ali';
      expect(user.name, 'Ali');
    });

    test(
      'lists from getters are copies, so editing one never changes the model',
      () {
        final user = User.fromJson({
          'tags': ['a'],
        });
        user.tags?.add('x');
        expect(user.tags, ['a']);
        expect(user.toJson()['tags'], ['a']);
      },
    );

    test('maps from getters are copies too', () {
      final user = User.fromJson({
        'meta': {'plan': 'pro'},
      });
      user.meta?['plan'] = 'free';
      expect(user.meta, {'plan': 'pro'});
    });

    test(
      'nested models stay the same objects, so their changes still count',
      () {
        final user = User.fromJson({
          'addresses': [
            {'city': 'Dubai'},
          ],
        });
        expect(identical(user.addresses?.first, user.addresses?.first), isTrue);
        user.addresses?.first.city = 'Doha';
        expect(user.addresses?.first.city, 'Doha');
      },
    );
  });
}
