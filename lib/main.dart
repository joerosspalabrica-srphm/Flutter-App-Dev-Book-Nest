import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'get_started_module.dart' as start;

void main() {
	WidgetsFlutterBinding.ensureInitialized();
	runApp(const AppEntry());
}

Future<FirebaseApp> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      // Web requires explicit Firebase options.
      // To run on web, you must first run: flutterfire configure
      // This will generate lib/firebase_options.dart with the proper config
      throw UnsupportedError(
        'Web platform requires firebase_options.dart. Run: flutterfire configure'
      );
    }

    // For Android/iOS: Use platform-specific configuration files
    // (google-services.json on Android, GoogleService-Info.plist on iOS)
    debugPrint('Initializing Firebase using platform-specific config (google-services.json/GoogleService-Info.plist)');
    final app = await Firebase.initializeApp();
    
    // Configure Realtime Database with your specific URL
    FirebaseDatabase.instance.databaseURL = 'https://book-nest-1e814-default-rtdb.asia-southeast1.firebasedatabase.app/';
    debugPrint('Realtime Database configured: ${FirebaseDatabase.instance.databaseURL}');
    
    return app;
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
            theme: ThemeData(fontFamily: 'Poppins'),
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

				return MaterialApp(
					theme: ThemeData(fontFamily: 'Poppins'),
					home: const Scaffold(
						body: Center(child: CircularProgressIndicator()),
					),
				);
			},
		);
	}
}
