import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'get_started_module.dart' as start;

void main() {
	WidgetsFlutterBinding.ensureInitialized();
	runApp(const AppEntry());
}

Future<FirebaseApp> _initializeFirebase() async {
  try {
    return await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
    rethrow;
  }
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint('Firebase Init Error (caught in builder): $error');
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Firebase initialization failed:\n\n$error\n\nCheck:\n1. google-services.json in android/app/\n2. Firebase Console Email/Password enabled\n3. Correct project ID & package name\n4. Internet connection',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }				if (snapshot.connectionState == ConnectionState.done) {
					return const start.MyApp();
				}

				return const MaterialApp(
					home: Scaffold(
						body: Center(child: CircularProgressIndicator()),
					),
				);
			},
		);
	}
}
