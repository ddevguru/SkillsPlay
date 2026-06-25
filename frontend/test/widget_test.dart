import 'package:flutter_test/flutter_test.dart';
import 'package:skillplay/models/models.dart';

void main() {
  test('User.fromJson parses API response', () {
    final user = User.fromJson({
      'id': '123',
      'name': 'Test',
      'email': 'test@example.com',
      'role': 'USER',
      'xp': 100,
      'subscriptionStatus': 'FREE',
    });
    expect(user.name, 'Test');
    expect(user.xp, 100);
    expect(user.hasSubscription, false);
  });

  test('User.hasSubscription is true for PRO', () {
    final user = User.fromJson({
      'id': '1',
      'name': 'Pro',
      'email': 'pro@example.com',
      'subscriptionStatus': 'PRO',
    });
    expect(user.hasSubscription, true);
  });
}
