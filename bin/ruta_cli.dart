import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:ruta_cli/commands/build.dart';
import 'package:ruta_cli/commands/run.dart';

void main(List<String> arguments) {
  final runner =
      CommandRunner<dynamic>('ruta', 'A CLI to build and run Ruta servers')
        ..addCommand(BuildCommand())
        ..addCommand(RunCommand());

  runner.run(arguments).catchError((dynamic error) {
    print(error);
    exit(1);
  });
}
