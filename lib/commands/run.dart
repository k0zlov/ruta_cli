import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

/// Command for building and running Ruta server
class RunCommand extends Command<void> {
  @override
  final name = 'run';
  @override
  final description = 'Build and run the Ruta server';

  @override
  Future<void> run() async {
    try {
      print('Starting server...');
      final serverProcess = await Process.start(
        'dart',
        ['run', '--enable-vm-service', '.ruta/server.dart'],
      );

      unawaited(serverProcess.stdout.pipe(stdout));
      unawaited(serverProcess.stderr.pipe(stderr));

      // Handle Ctrl+C
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
