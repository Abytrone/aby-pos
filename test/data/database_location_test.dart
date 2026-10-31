import 'dart:io';

import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root, from, to;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aby_location_');
    from = Directory(p.join(root.path, 'Documents'))..createSync();
    to = Directory(p.join(root.path, 'support'));
  });

  tearDown(() => root.delete(recursive: true));

  void write(Directory d, String name, String text) => File(p.join(d.path, name)).writeAsStringSync(text);
  String? read(Directory d, String name) {
    final f = File(p.join(d.path, name));
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  test('moves the database with its journal files and the training copy', () async {
    write(from, 'aby_pos.sqlite', 'main');
    write(from, 'aby_pos.sqlite-wal', 'wal');
    write(from, 'aby_pos.sqlite-shm', 'shm');
    write(from, 'aby_pos_training.sqlite', 'training');
    write(from, 'aby_pos.training', '');

    await moveDatabaseFiles(from: from.path, to: to.path);

    expect(read(to, 'aby_pos.sqlite'), 'main');
    expect(read(to, 'aby_pos.sqlite-wal'), 'wal');
    expect(read(to, 'aby_pos.sqlite-shm'), 'shm');
    expect(read(to, 'aby_pos_training.sqlite'), 'training');
    expect(read(to, 'aby_pos.training'), '');
    expect(from.listSync(), isEmpty);
  });

  test('never replaces a database already moved', () async {
    write(from, 'aby_pos.sqlite', 'old');
    to.createSync();
    write(to, 'aby_pos.sqlite', 'new');

    await moveDatabaseFiles(from: from.path, to: to.path);

    expect(read(to, 'aby_pos.sqlite'), 'new');
    expect(read(from, 'aby_pos.sqlite'), 'old');
  });

  test('nothing to move: nothing happens', () async {
    await moveDatabaseFiles(from: from.path, to: to.path);
    expect(to.listSync(), isEmpty);
  });

  test('moving again changes nothing', () async {
    write(from, 'aby_pos.sqlite', 'main');
    await moveDatabaseFiles(from: from.path, to: to.path);
    await moveDatabaseFiles(from: from.path, to: to.path);
    expect(read(to, 'aby_pos.sqlite'), 'main');
  });
}
