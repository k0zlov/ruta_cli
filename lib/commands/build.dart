import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/process_run.dart';

/// Command for building Ruta server
class BuildCommand extends Command<void> {
  /// Constructor for build command
  /// Adds arguments for the command
  BuildCommand() {
    // Add the optional flag for overwriting the Dockerfile
    argParser.addFlag(
      'overwrite-dockerfile',
      abbr: 'o',
      help:
          'If provided, overwrites the existing Dockerfile. Otherwise, it only generates the Dockerfile if it does not exist.',
    );
  }

  @override
  final name = 'build';
  @override
  final description =
      'Generate the server using build_runner and create a Dockerfile';

  @override
  Future<void> run() async {
    final shell = Shell();

    print('Generating server...');
    try {
      // Run build_runner to generate server code
      await shell.run(
        'dart run build_runner build --delete-conflicting-outputs',
      );
      print('Build completed successfully.');

      // Generate the Dockerfile
      const dockerfileContents = '''
# ========= Stage 1: Dependencies =========
FROM dart:stable AS dependencies

WORKDIR /app

# Copy only dependency files initially to leverage docker caching
COPY pubspec.* ./

# Fetch dependencies
RUN dart pub get
RUN dart pub global activate ruta_cli

# ========= Stage 2: Code Analysis and Tests =========
FROM dependencies AS test

# Copy entire source code into the image for testing
COPY . .

# Run analysis to ensure code quality (linting, analysis, formatting checks)
RUN dart analyze

# Run tests to validate the application before building the executable
RUN dart test

# ========= Stage 3: Build (compile binary) =========
FROM dependencies AS build

# Copy entire codebase again (after tests have passed)
COPY . .

# Generate a production build.
RUN dart pub global run ruta_cli build

# Compile to native executable
RUN dart compile exe .ruta/server.dart -o /app/server

# ========= Stage 4: Runtime =========
FROM scratch

# Copy executable built from previous stage
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server

# Define exposed ports, environment, etc.
EXPOSE 8080

# Start your Dart executable
ENTRYPOINT ["/app/server"]
''';

      final dockerfile = File('Dockerfile');

      // Determine whether to overwrite or skip based on the flag
      final overwrite = argResults!['overwrite-dockerfile'] as bool;

      if (overwrite || !dockerfile.existsSync()) {
        await dockerfile.writeAsString(dockerfileContents);
        print('Dockerfile created successfully.');
      } else {
        print(
          'Dockerfile already exists. Use --overwrite-dockerfile to overwrite it.',
        );
      }
    } catch (e) {
      throw Exception('Error running build_runner or creating Dockerfile: $e');
    }
  }
}
