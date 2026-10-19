import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

class SignUp with CorextraValidatable {
  SignUp({this.name, this.email});

  final String? name;
  final String? email;

  @override
  Map<String, String?> validate() => {
    'name': FormValidators.required(name),
    'email': FormValidators.optional(FormValidators.email)(email),
  };
}

void main() {
  test('valid when every check passes', () {
    final form = SignUp(name: 'Ashiq', email: 'ashiq@example.com');
    expect(form.validation.isValid, isTrue);
    expect(form.validation.errors, isEmpty);
    expect(form.validation.firstError, isNull);
  });

  test('lists only the fields that failed', () {
    final form = SignUp(email: 'not-an-email');
    expect(form.validation.isValid, isFalse);
    expect(form.validation.errors.keys, ['name', 'email']);
    expect(form.validation.firstError, FormValidators.required(null));
    expect(
      form.validation.errorFor('email'),
      FormValidators.email('not-an-email'),
    );
    expect(SignUp(name: 'A').validation.errorFor('email'), isNull);
  });
}
