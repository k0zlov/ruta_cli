import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/process_run.dart';

/// Command for building Ruta server
class BuildCommand extends Command<void> {
  @override
  final name = 'build';
  @override
  final description = 'Generate the server using build_runner';

  @override
  Future<void> run() async {
    final shell = Shell(
      stdout: File(Platform.isWindows ? 'nul' : '/dev/null').openWrite(),
      stderr: File(Platform.isWindows ? 'nul' : '/dev/null').openWrite(),
    );

    print('Generating server...');
    try {
      await shell.run(
        'dart run build_runner build --delete-conflicting-outputs',
      );
      print('Build completed successfully.');
    } catch (e) {
      throw Exception('Error running build_runner: $e');
    }
  }
}
