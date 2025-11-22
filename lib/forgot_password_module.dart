import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordModule {
  static Future<void> showForgotPasswordDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    // Get screen size and define responsive breakpoints
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    // Responsive sizing variables
    final dialogBorderRadius = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final titleFontSize = isSmallMobile ? 20.0 : (isMobile ? 22.0 : (isTablet ? 24.0 : 26.0));
    final contentFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : (isTablet ? 15.0 : 16.0));
    final labelFontSize = isSmallMobile ? 11.0 : 12.0;
    final buttonFontSize = isSmallMobile ? 14.0 : (isMobile ? 15.0 : (isTablet ? 16.0 : 17.0));
    final buttonPaddingH = isSmallMobile ? 20.0 : (isMobile ? 22.0 : (isTablet ? 24.0 : 28.0));
    final buttonPaddingV = isSmallMobile ? 10.0 : (isMobile ? 11.0 : (isTablet ? 12.0 : 13.0));
    final buttonBorderRadius = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final iconSize = isSmallMobile ? 20.0 : 24.0;
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> sendResetEmail() async {
              final email = emailController.text.trim();
              
              if (email.isEmpty) {
                _showSnackBar(
                  context,
                  'Please enter your email address',
                  isError: true,
                );
                return;
              }
              
              if (!email.endsWith('@wvsu.edu.ph')) {
                _showSnackBar(
                  context,
                  'Only @wvsu.edu.ph emails are allowed',
                  isError: true,
                );
                return;
              }

              setState(() {
                isLoading = true;
              });

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!context.mounted) return;

                setState(() {
                  isLoading = false;
                });

                Navigator.of(dialogContext).pop();

                _showSnackBar(
                  context,
                  'Password reset email sent! Check your inbox.',
                  isError: false,
                );
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;

                setState(() {
                  isLoading = false;
                });

                String errorMessage = 'Failed to send reset email';
                
                if (e.code == 'user-not-found') {
                  errorMessage = 'No account found with this email';
                } else if (e.code == 'invalid-email') {
                  errorMessage = 'Invalid email address';
                } else {
                  errorMessage = e.message ?? e.code;
                }

                _showSnackBar(context, errorMessage, isError: true);
              } catch (e) {
                if (!context.mounted) return;

                setState(() {
                  isLoading = false;
                });

                _showSnackBar(
                  context,
                  'An error occurred: ${e.toString()}',
                  isError: true,
                );
              }
            }

            final contentPadding = isMobile ? 20.0 : 24.0;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dialogBorderRadius),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(dialogBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF003060), Color(0xFF004080)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(dialogBorderRadius),
                          topRight: Radius.circular(dialogBorderRadius),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lock_reset,
                              color: Colors.white,
                              size: titleFontSize,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Reset Password',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: titleFontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(contentPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info box
                          Container(
                            padding: EdgeInsets.all(contentPadding * 0.75),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003060).withOpacity(0.05),
                              border: Border.all(
                                color: const Color(0xFF003060).withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF003060),
                                  size: iconSize,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Enter your WVSU email address and we\'ll send you a link to reset your password.',
                                    style: GoogleFonts.poppins(
                                      fontSize: contentFontSize,
                                      color: const Color(0xFF003060),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: contentPadding),
                          // Email input
                          TextFormField(
                            controller: emailController,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'WVSU Email Address',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: labelFontSize,
                                color: Colors.grey.shade600,
                              ),
                              hintText: 'example@wvsu.edu.ph',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: contentFontSize,
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: const Color(0xFFFF6B35),
                                size: iconSize,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6B35),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(fontSize: contentFontSize),
                          ),
                        ],
                      ),
                    ),
                    // Buttons
                    Padding(
                      padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, contentPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop();
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: buttonPaddingH,
                                vertical: buttonPaddingV,
                              ),
                              side: BorderSide(
                                color: isLoading ? Colors.grey.shade300 : const Color(0xFF003060),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonBorderRadius),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: isLoading ? Colors.grey.shade400 : const Color(0xFF003060),
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isLoading ? null : sendResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: buttonPaddingH,
                                vertical: buttonPaddingV,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonBorderRadius),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: iconSize,
                                    height: iconSize,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Send Link',
                                    style: GoogleFonts.poppins(
                                      fontSize: buttonFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showSnackBar(BuildContext context, String message,
      {required bool isError}) {
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
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? const Color(0xFF003060) : const Color(0xFFD67730),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
