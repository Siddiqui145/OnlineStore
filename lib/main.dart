import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'screens/admin/admin_home.dart';
import 'screens/auth_screen.dart';
import 'screens/customer/customer_home.dart';
import 'services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DeshmukhAutoMobiles());
}

class DeshmukhAutoMobiles extends StatelessWidget {
  const DeshmukhAutoMobiles({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DeshmukhAutoMobiles',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      );
}

/// Routes to login, customer app or admin dashboard based on auth + role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: Repo.auth.authStateChanges(),
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) return const _Loading();
          final user = auth.data;
          if (user == null) return const AuthScreen();
          return StreamBuilder<AppUser?>(
            stream: Repo.userStream(user.uid),
            builder: (context, snap) {
              if (snap.hasError) {
                return Scaffold(body: Center(child: Text('Could not load profile: ${snap.error}')));
              }
              final profile = snap.data;
              if (profile == null) {
                Future.microtask(() => Repo.ensureUser(user));
                return const _Loading();
              }
              return profile.isAdmin ? AdminHome(user: profile) : CustomerHome(user: profile);
            },
          );
        },
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
