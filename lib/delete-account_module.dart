import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Navigator.of(context).pop(); // Close the dialog
                  // Navigate to sign-up and log-in module
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
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
}
