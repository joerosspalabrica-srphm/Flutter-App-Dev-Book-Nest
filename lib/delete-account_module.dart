import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'get_started_module.dart';

class DeleteAccountModule {
  static Future<void> showDeleteAccountDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _DeleteAccountDialog();
      },
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _countdown = 10;
  Timer? _timer;
  bool _canDelete = false;
  bool _showPasswordConfirmation = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canDelete = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _confirmDeleteAccount() async {
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user with email and password
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Create credential for re-authentication
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);
      print('DEBUG: User re-authenticated successfully');

      // Delete user data from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        print('DEBUG: User data deleted from Firestore');
      } catch (e) {
        print('DEBUG: Error deleting Firestore data: $e');
        // Continue even if Firestore deletion fails
      }

      // Delete the user account
      await user.delete();
      print('DEBUG: User account deleted successfully');

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        
        // Navigate to Get Started page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BookNestScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException: ${e.code}');
      
      setState(() {
        _isDeleting = false;
        if (e.code == 'wrong-password') {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'Too many failed attempts. Please try again later.';
        } else if (e.code == 'requires-recent-login') {
          _errorMessage = 'Please log out and log back in, then try again.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      print('DEBUG: Error deleting account: $e');
      
      setState(() {
        _isDeleting = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPasswordConfirmation) {
      return _buildPasswordConfirmationDialog();
    }
    return _buildCountdownDialog();
  }

  Widget _buildCountdownDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      title: Text(
        'Delete Account',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003060),
          fontSize: 24,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to delete your account?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_canDelete)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: const Color(0xFFD67730),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_countdown seconds',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD67730),
                    ),
                  ),
                ],
              ),
            ),
          if (_canDelete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This action cannot be undone',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'No',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canDelete
              ? () {
                  setState(() {
                    _showPasswordConfirmation = true;
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canDelete ? Colors.red : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey[400],
            disabledForegroundColor: Colors.white,
          ),
          child: Text(
            'Yes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordConfirmationDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      title: Column(
        children: [
          Icon(
            Icons.lock_outline,
            color: const Color(0xFF003060),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Confirm Password',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003060),
              fontSize: 24,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter your password to confirm account deletion',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Password TextField
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null 
                    ? Colors.red.shade400 
                    : const Color(0xFF003060).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              enabled: !_isDeleting,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF003060),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: const Color(0xFF003060).withOpacity(0.6),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF003060).withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _confirmDeleteAccount(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () {
                  setState(() {
                    _showPasswordConfirmation = false;
                    _passwordController.clear();
                    _errorMessage = null;
                  });
                },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Back',
            style: GoogleFonts.poppins(
              color: _isDeleting ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _confirmDeleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDeleting ? Colors.grey[400] : Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey[400],
            disabledForegroundColor: Colors.white,
          ),
          child: _isDeleting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}