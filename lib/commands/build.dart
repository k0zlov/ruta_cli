import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/process_run.dart';

/// Command for building Ruta server
class BuildCommand extends Command<void> {
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
# Use the Dart official image as the base for building the application.
FROM dart:stable AS build

# Set the working directory inside the container.
WORKDIR /app

# Copy only pubspec.* files first to leverage Docker build caching for dependencies.
COPY pubspec.* ./

# Install Dart dependencies.
RUN dart pub get

# Copy the rest of the application files into the container.
COPY . .

# Run build_runner to generate server code.
RUN dart run build_runner build --delete-conflicting-outputs

# Build a release version of the application.
RUN dart compile exe .ruta/server.dart -o /app/server

# Use a smaller runtime image for the final container.
FROM dart:stable AS runtime

# Set the working directory inside the container.
WORKDIR /app

# Copy the compiled server from the build stage.
COPY --from=build /app/server /app/server

# Copy essential project files if needed at runtime (optional).
COPY --from=build /app/pubspec.yaml /app/
COPY --from=build /app/pubspec.lock /app/

# Expose the port the server will listen on.
EXPOSE 8080

# Define the entry point to run the server.
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
