import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class EmailNotVerifiedScreen extends StatefulWidget {
  final String email;
  final String password;
  const EmailNotVerifiedScreen({super.key, required this.email, required this.password});

  @override
  State<EmailNotVerifiedScreen> createState() => _EmailNotVerifiedScreenState();
}

class _EmailNotVerifiedScreenState extends State<EmailNotVerifiedScreen> {
  bool _isLoading = false;
  String? _message;

  Future<void> _resendVerification() async {
    setState(() { _isLoading = true; _message = null; });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resendEmailVerification();
      setState(() { _message = 'Verification email sent! Please check your inbox.'; });
    } catch (e) {
      setState(() { _message = 'Failed to send verification email.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _tryAgain() async {
    setState(() { _isLoading = true; _message = null; });
    try {
      // Reload the Firebase user to check verification status
      final user = Provider.of<AuthService>(context, listen: false).firebaseAuth.currentUser;
      await user?.reload();
      // After reload, the main.dart Consumer will rebuild and route accordingly
    } catch (e) {
      setState(() { _message = 'Error checking verification status.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Not Verified')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Please verify your email address to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (_message != null) ...[
                Text(_message!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _resendVerification,
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isLoading ? null : _tryAgain,
                child: const Text('I have verified, Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
