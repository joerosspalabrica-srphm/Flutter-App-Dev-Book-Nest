import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileLoginScreen extends StatefulWidget {
  const ProfileLoginScreen({Key? key}) : super(key: key);

  @override
  State<ProfileLoginScreen> createState() => _ProfileLoginScreenState();
}

class _ProfileLoginScreenState extends State<ProfileLoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // For reset functionality
  String _originalName = '';
  
  // Character limit for name
  final int _nameMaxLength = 50;
  
  // Animation controller for success
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load username from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            usernameController.text = doc.data()?['name'] ?? user.displayName ?? '';
            _originalName = usernameController.text;
          });
        } else {
          setState(() {
            usernameController.text = user.displayName ?? '';
            _originalName = usernameController.text;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        setState(() {
          usernameController.text = user.displayName ?? '';
          _originalName = usernameController.text;
        });
      }
    }
  }

  void _resetChanges() {
    setState(() {
      usernameController.text = _originalName;
      currentPasswordController.text = '';
      passwordController.text = '';
      confirmPasswordController.text = '';
    });
    _showSnackBar('Changes reset', isError: false);
  }

  Future<void> _onDonePressed() async {
    if (usernameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name', isError: true);
      return;
    }
    
    if (usernameController.text.trim().length > _nameMaxLength) {
      _showSnackBar('Name is too long (max $_nameMaxLength characters)', isError: true);
      return;
    }
    
    // Validate password changes
    if (passwordController.text.isNotEmpty) {
      // Check if current password is provided
      if (currentPasswordController.text.isEmpty) {
        _showSnackBar('Please enter your current password to change it', isError: true);
        return;
      }
      
      // Check if passwords match
      if (passwordController.text != confirmPasswordController.text) {
        _showSnackBar('New passwords do not match', isError: true);
        return;
      }
      
      // Check password length
      if (passwordController.text.length < 6) {
        _showSnackBar('New password must be at least 6 characters', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No user logged in', isError: true);
        return;
      }
      
      // If password change is requested, verify current password first
      if (passwordController.text.isNotEmpty) {
        try {
          // Re-authenticate with current password
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPasswordController.text,
          );
          await user.reauthenticateWithCredential(credential);
        } on FirebaseAuthException {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showSnackBar('Current password is incorrect', isError: true);
          }
          return;
        }
      }

      // Update display name
      await user.updateDisplayName(usernameController.text.trim());

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': usernameController.text.trim(),
      });

      // Update password if provided
      if (passwordController.text.isNotEmpty) {
        await user.updatePassword(passwordController.text);
      }

      if (!mounted) return;

      // Play success animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      _showSnackBar('Profile updated successfully!', isError: false);

      // Navigate back after animation
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Update failed';
      
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use at least 6 characters';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log out and log back in to change your password';
      } else {
        errorMessage = e.message ?? e.code;
      }
      
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar('Update failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? const Color(0xFF003060) : const Color(0xFFD67730),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    currentPasswordController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background logo with transparency
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Transform.scale(
                scale: 2.5,
                child: Image.asset(
                  'assets/background logo.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
            
            // Profile Avatar
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BA3E0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (usernameController.text.isNotEmpty 
                          ? usernameController.text[0] 
                          : user?.email?[0] ?? 'U').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User Name
            Text(
              usernameController.text.isNotEmpty 
                  ? usernameController.text 
                  : user?.displayName ?? 'User',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 30),
            
            // Edit Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Name:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: usernameController,
                        builder: (context, value, child) {
                          final count = value.text.length;
                          final isOverLimit = count > _nameMaxLength;
                          return Text(
                            '$count/$_nameMaxLength',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isOverLimit ? Colors.red : Colors.grey,
                              fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: usernameController,
                    maxLength: _nameMaxLength,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                      ),
                      counterText: '', // Hide default counter
                      suffixIcon: const Icon(
                        Icons.edit,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Current Password Field
                  Text(
                    'Current Password:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      hintText: 'Enter current password',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          const Icon(
                            Icons.edit,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // New Password Field
                  Text(
                    'New Password:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter new password (optional)',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const Icon(
                            Icons.edit,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm Password Field
                  Text(
                    'Confirm New Password:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: confirmPasswordController,
                    builder: (context, value, child) {
                      final confirmText = value.text;
                      final newPasswordText = passwordController.text;
                      final isEmpty = confirmText.isEmpty;
                      final isMatching = confirmText == newPasswordText && confirmText.isNotEmpty;
                      
                      return TextField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey,
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF003366)),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              if (!isEmpty)
                                Icon(
                                  isMatching ? Icons.check_circle : Icons.cancel,
                                  color: isMatching ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Reset Button
            TextButton.icon(
              onPressed: _isLoading ? null : _resetChanges,
              icon: const Icon(Icons.refresh, color: Color(0xFF003060)),
              label: Text(
                'Reset Changes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF003060),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Action Buttons Row (Cancel and Done)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003060), width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Done Button with Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onDonePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
