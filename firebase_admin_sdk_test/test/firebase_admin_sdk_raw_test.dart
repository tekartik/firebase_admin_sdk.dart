import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:test/test.dart';

const mockProjectId = 'mock_project_id';
Future<void> main() async {
  tearDown(() {
    // Clean up all apps after each test
    FirebaseApp.apps.forEach(FirebaseApp.deleteApp);
  });

  test('creates a default app without options', () {
    final app = FirebaseApp.initializeApp();

    expect(app.name, '[DEFAULT]');
    expect(app.wasInitializedFromEnv, isTrue);
    expect(app.isDeleted, isFalse);
  });

  test('creates default app with options', () {
    const options = AppOptions(projectId: mockProjectId);
    final app = FirebaseApp.initializeApp(options: options);

    expect(app.name, '[DEFAULT]');
    expect(app.options.projectId, mockProjectId);
    expect(app.wasInitializedFromEnv, isFalse);
    expect(app.isDeleted, isFalse);
  });

  test('creates named app with options', () {
    const options = AppOptions(projectId: mockProjectId);
    final app = FirebaseApp.initializeApp(options: options, name: 'custom-app');

    expect(app.name, 'custom-app');
    expect(app.options.projectId, mockProjectId);
    expect(app.wasInitializedFromEnv, isFalse);
  });

  test('returns same instance for duplicate initialization', () {
    const options = AppOptions(projectId: mockProjectId);
    final app1 = FirebaseApp.initializeApp(options: options);
    final app2 = FirebaseApp.initializeApp(options: options);

    expect(identical(app1, app2), isTrue);
  });
}
