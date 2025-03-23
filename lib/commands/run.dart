import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/process_run.dart';

/// Command for building and running Ruta server
class RunCommand extends Command<void> {
  @override
  final name = 'run';
  @override
  final description = 'Build and run the Ruta server';

  @override
  Future<void> run() async {
    final shellSilent = Shell(
      stdout: File(Platform.isWindows ? 'nul' : '/dev/null').openWrite(),
      stderr: File(Platform.isWindows ? 'nul' : '/dev/null').openWrite(),
    );

    print('Generating server...');
    try {
      await shellSilent
          .run('dart run build_runner build --delete-conflicting-outputs');
      print('Build completed successfully.');
    } catch (e) {
      throw Exception('Error running build_runner: $e');
    }

    print('Starting server...');
    try {
      final serverProcess = await Process.start(
        'dart',
        ['run', '--enable-vm-service', '.ruta/server.dart'],
      );

      serverProcess.stdout.pipe(stdout);
      serverProcess.stderr.pipe(stderr);

      ProcessSignal.sigint.watch().listen((_) {
        serverProcess.kill();
        exit(0);
      });

      final exitCode = await serverProcess.exitCode;
      if (exitCode != 0) {
        throw Exception('Server exited with code $exitCode');
      }
    } catch (e) {
      throw Exception('Error starting server: $e');
    }
  }
}
