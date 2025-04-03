import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

/// Command for building and running Ruta server
class RunCommand extends Command<void> {
  /// Adds args for the command
  RunCommand() {
    argParser.addFlag(
      'disable-hot-reload',
      abbr: 'd',
      help: 'Disables hot reload when running.',
    );
  }

  @override
  final name = 'run';
  @override
  final description = 'Build and run the Ruta server';

  @override
  Future<void> run() async {
    try {
      final disableHotReload = argResults!['disable-hot-reload'] as bool;

      print('Starting server...');
      final serverProcess = await Process.start(
        'dart',
        [
          'run',
          '.ruta/server.dart',
          if (!disableHotReload) ...{
            '--enable-vm-service',
            '--hot-reload',
          },
        ],
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
