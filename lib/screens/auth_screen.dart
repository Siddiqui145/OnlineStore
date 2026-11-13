import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController();
  final email = TextEditingController(), pass = TextEditingController();
  bool signup = false, busy = false, hide = true;
  String? err;

  String _msg(String code) => switch (code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Email or password is incorrect.',
        'email-already-in-use' => 'An account with this email already exists. Sign in instead.',
        'weak-password' => 'Use a password with at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
        _ => 'Something went wrong ($code). Try again.',
      };

  Future<void> submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      busy = true;
      err = null;
    });
    try {
      if (signup) {
        await Repo.signUp(name.text, phone.text, email.text, pass.text);
      } else {
        await Repo.signIn(email.text, pass.text);
      }
    } on FirebaseAuthException catch (e) {
      err = _msg(e.code);
    } catch (e) {
      err = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _key,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(signup ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 6),
              Text(signup ? 'Order spare parts and book services.' : 'Sign in to continue.',
                  style: const TextStyle(color: kMuted)),
              const SizedBox(height: 28),
              if (signup) ...[
                TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: req),
                const SizedBox(height: 14),
                TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    validator: req),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: pass,
                obscureText: hide,
                onFieldSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => hide = !hide),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              if (err != null) ...[
                const SizedBox(height: 14),
                Text(err!, style: const TextStyle(color: Color(0xFFB42318))),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(signup ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  signup = !signup;
                  err = null;
                }),
                child: Text(signup ? 'Already have an account? Sign in' : 'New here? Create an account'),
              ),
            ]),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: wide
          ? Row(children: [
              Expanded(
                child: Container(
                  color: kInk,
                  padding: const EdgeInsets.all(56),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.settings, size: 32, color: kInk),
                    ),
                    const SizedBox(height: 28),
                    const Text('DeshmukhAutoMobiles',
                        style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const Text(
                      'Genuine spare parts and on-site service,\none request away.',
                      style: TextStyle(color: Color(0xFFB8C2D1), fontSize: 18, height: 1.5),
                    ),
                  ]),
                ),
              ),
              Expanded(child: form),
            ])
          : form,
    );
  }
}
