import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

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
  
  // Avatar
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedAvatar();
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadSavedAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in, cannot load avatar in edit profile');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final avatarKey = 'avatar_base64_${user.uid}';
      final base64String = prefs.getString(avatarKey);
      
      if (base64String != null && base64String.isNotEmpty) {
        try {
          // Decode base64 to bytes
          final bytes = base64Decode(base64String);
          print('DEBUG: Decoded base64 to ${bytes.length} bytes in edit profile');
          
          // Create a temporary file from bytes
          final tempDir = await Directory.systemTemp.createTemp('flutter_avatar_edit');
          final avatarFile = File('${tempDir.path}/avatar.png');
          await avatarFile.writeAsBytes(bytes);
          
          if (mounted) {
            setState(() {
              _avatarImage = avatarFile;
            });
            print('DEBUG: Loaded saved avatar from base64 in edit profile');
          }
        } catch (decodeError) {
          print('DEBUG: Error decoding base64 in edit profile: $decodeError');
        }
      }
    } catch (e) {
      print('DEBUG: Error loading saved avatar in edit profile: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load username from Realtime Database
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}')
            .once();
        
        if (snapshot.snapshot.exists) {
          final data = snapshot.snapshot.value as Map?;
          setState(() {
            usernameController.text = data?['username'] ?? data?['name'] ?? user.displayName ?? '';
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

      // Update Realtime Database
      await FirebaseDatabase.instance
          .ref('users/${user.uid}')
          .update({
        'username': usernameController.text.trim(),
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    // Responsive breakpoints
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    // Responsive sizing
    final horizontalPadding = isSmallMobile ? 12.0 : (isMobile ? 16.0 : (isTablet ? 24.0 : 32.0));
    final avatarSize = isSmallMobile ? 80.0 : (isMobile ? 100.0 : (isTablet ? 120.0 : 140.0));
    final avatarFontSize = isSmallMobile ? 32.0 : (isMobile ? 40.0 : (isTablet ? 48.0 : 56.0));
    final checkIconSize = isSmallMobile ? 14.0 : (isMobile ? 16.0 : 18.0);
    final nameFontSize = isSmallMobile ? 20.0 : (isMobile ? 24.0 : (isTablet ? 28.0 : 32.0));
    final labelFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 16.0);
    final counterFontSize = isSmallMobile ? 11.0 : (isMobile ? 12.0 : 13.0);
    final hintFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 16.0);
    final iconSize = isSmallMobile ? 20.0 : (isMobile ? 24.0 : 28.0);
    final buttonFontSize = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final resetFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);
    final cardPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final cardMarginH = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 40.0 : 60.0));
    final spacing = isSmallMobile ? 20.0 : (isMobile ? 30.0 : 40.0);
    final fieldSpacing = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final buttonPaddingH = isSmallMobile ? 32.0 : (isMobile ? 40.0 : 50.0);
    final buttonPaddingV = isSmallMobile ? 12.0 : (isMobile ? 15.0 : 18.0);
    final buttonGap = isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0);
    
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
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: iconSize,
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
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: isMobile ? 20 : 30),
            
            // Profile Avatar
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3E0),
                    shape: BoxShape.circle,
                    image: _avatarImage != null
                        ? DecorationImage(
                            image: FileImage(_avatarImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarImage == null
                      ? Center(
                          child: Text(
                            (usernameController.text.isNotEmpty 
                                ? usernameController.text[0] 
                                : user?.email?[0] ?? 'U').toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: avatarFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(isSmallMobile ? 3 : 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: checkIconSize,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // User Name
            Text(
              usernameController.text.isNotEmpty 
                  ? usernameController.text 
                  : user?.displayName ?? 'User',
              style: GoogleFonts.poppins(
                fontSize: nameFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: spacing),
            
            // Edit Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: cardMarginH, vertical: 10),
              padding: EdgeInsets.all(cardPadding),
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
                          fontSize: labelFontSize,
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
                              fontSize: counterFontSize,
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
                        fontSize: hintFontSize,
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
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(
                          Icons.edit,
                          color: const Color(0xFFFF6B35),
                          size: iconSize,
                        ),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: hintFontSize,
                      color: Colors.black,
                    ),
                  ),
                  
                  SizedBox(height: fieldSpacing),
                  
                  // Current Password Field
                  Text(
                    'Current Password:',
                    style: GoogleFonts.poppins(
                      fontSize: labelFontSize,
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
                        fontSize: hintFontSize,
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
                              size: iconSize,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Icon(
                              Icons.edit,
                              color: const Color(0xFFFF6B35),
                              size: iconSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: hintFontSize,
                      color: Colors.black,
                    ),
                  ),
                  
                  SizedBox(height: fieldSpacing),
                  
                  // New Password Field
                  Text(
                    'New Password:',
                    style: GoogleFonts.poppins(
                      fontSize: labelFontSize,
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
                        fontSize: hintFontSize,
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
                              size: iconSize,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Icon(
                              Icons.edit,
                              color: const Color(0xFFFF6B35),
                              size: iconSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: hintFontSize,
                      color: Colors.black,
                    ),
                  ),
                  
                  SizedBox(height: fieldSpacing),
                  
                  // Confirm Password Field
                  Text(
                    'Confirm New Password:',
                    style: GoogleFonts.poppins(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: confirmPasswordController,
                    builder: (context, value, child) {
                      return TextField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: hintFontSize,
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
                                  size: iconSize,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Icon(
                                  Icons.edit,
                                  color: const Color(0xFFFF6B35),
                                  size: iconSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: hintFontSize,
                          color: Colors.black,
                        ),
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
              icon: Icon(Icons.refresh, color: const Color(0xFF003060), size: iconSize),
              label: Text(
                'Reset Changes',
                style: GoogleFonts.poppins(
                  fontSize: resetFontSize,
                  color: const Color(0xFF003060),
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 10 : 15),
            
            // Action Buttons Row (Cancel and Done)
            Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 20 : 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003060), width: 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPaddingH,
                        vertical: buttonPaddingV,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: buttonGap),
                  
                  // Done Button with Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onDonePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: EdgeInsets.symmetric(
                          horizontal: buttonPaddingH + 10,
                          vertical: buttonPaddingV,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isMobile ? 20 : 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
