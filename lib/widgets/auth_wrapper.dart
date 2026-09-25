import 'package:flutter/material.dart';
import 'package:nwt_app/services/biometric_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final BiometricService _biometricService = BiometricService.to;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final isAvailable = await _biometricService.isBiometricsAvailable();
    if (!isAvailable) {
      setState(() => _isAuthenticated = true);
      return;
    }

    final authenticated = await _biometricService.authenticate();
    setState(() => _isAuthenticated = authenticated);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Authentication Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text('Authenticate'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
