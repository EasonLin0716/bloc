import 'dart:io';

import 'package:hive_ce/hive.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/hive_impl.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Hive interference', () {
    tearDown(() {
      Hive.close();
      (Hive as HiveImpl).homePath = null;
    });

    test('odd singleton interference', () async {
      final cwd = Directory.current.absolute.path;

      var impl1 = HiveImpl()..init(cwd);
      var box1 = await impl1.openBox<dynamic>('impl1');

      final impl2 = HiveImpl()..init(cwd);
      final box2 = await impl2.openBox<dynamic>('impl2');

      await impl1.close();

      expect(box1.isOpen, false);
      expect(box2.isOpen, true);

      impl1 = HiveImpl()..init(cwd);
      box1 = await impl1.openBox<dynamic>('impl1');

      Hive.init(cwd);
      await box1.deleteFromDisk();
      await box2.close();
      await Hive.deleteBoxFromDisk('impl2');
    });

    test('two hive impls beside same directory', () async {
      final cwd = Directory.current.absolute.path;

      final impl1 = Hive..init(cwd);
      var box1 = await impl1.openBox<dynamic>('impl1');

      final impl2 = HiveImpl()..init(cwd);
      var box2 = await impl2.openBox<dynamic>('impl2');

      await box1.put('instance', 'impl1');
      await box2.put('instance', 'impl2');

      await impl1.close();
      await impl2.close();

      box1 = await impl1.openBox<dynamic>('impl1');
      box2 = await impl2.openBox<dynamic>('impl2');

      expect(box1.get('instance'), 'impl1');
      expect(box2.get('instance'), 'impl2');

      await impl1.deleteFromDisk();
      expect(box1.isOpen, false);
      expect(box2.isOpen, true);
      expect(box2.get('instance'), 'impl2');

      await impl2.deleteFromDisk();
      expect(box2.isOpen, false);
    });

    test('two hive impls reside distinct directories', () async {
      final cwd1 = p.join(Directory.current.absolute.path, 'cwd1');
      final cwd2 = p.join(Directory.current.absolute.path, 'cwd2');

      final impl1 = Hive..init(cwd1);
      var box1 = await impl1.openBox<dynamic>('impl1');

      final impl2 = HiveImpl()..init(cwd2);
      var box2 = await impl2.openBox<dynamic>('impl2');

      await box1.put('instance', 'impl1');
      await box2.put('instance', 'impl2');

      await impl1.close();
      await impl2.close();

      box1 = await impl1.openBox<dynamic>('impl1');
      box2 = await impl2.openBox<dynamic>('impl2');

      expect(box1.get('instance'), 'impl1');
      expect(box2.get('instance'), 'impl2');

      await impl1.deleteFromDisk();
      expect(box1.isOpen, false);
      expect(box2.isOpen, true);
      expect(box2.get('instance'), 'impl2');

      await impl2.deleteFromDisk();
      expect(box2.isOpen, false);

      await Directory(cwd1).delete();
      await Directory(cwd2).delete();
    });
  });
}
