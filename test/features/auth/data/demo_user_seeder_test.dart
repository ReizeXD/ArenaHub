import 'package:arenahub/features/auth/data/datasources/in_memory_user_data_source.dart';
import 'package:arenahub/features/auth/data/seed/demo_user_seeder.dart';
import 'package:arenahub/features/auth/data/services/pbkdf2_password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryUserDataSource dataSource;
  late DemoUserSeeder seeder;

  setUp(() {
    dataSource = InMemoryUserDataSource();
    seeder = DemoUserSeeder(dataSource, Pbkdf2PasswordHasher(iterations: 100));
  });

  test('cria as contas de demonstração com senha em hash', () async {
    await seeder.seed();

    final record = await dataSource.findByEmail('admin@arenahub.com');

    expect(record, isNotNull);
    expect(record!.passwordHash, isNot(contains(DemoUserSeeder.demoPassword)));
  });

  test('rodar duas vezes não duplica nem re-hasheia', () async {
    await seeder.seed();
    final first = (await dataSource.findByEmail('admin@arenahub.com'))!;

    await seeder.seed();
    final second = (await dataSource.findByEmail('admin@arenahub.com'))!;

    expect(second.passwordHash, first.passwordHash);
  });
}
