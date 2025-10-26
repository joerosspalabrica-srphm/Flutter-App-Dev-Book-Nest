import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
// Import the login / register module so we can navigate to the Register screen
import 'sign-up_and_log-in_module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Nest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BookNestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class BookNestScreen extends StatelessWidget {
  const BookNestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top half with background image and logo
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  // Background Image (top half only) with heavy blur, whitening, and low contrast
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.asset(
                          "assets/background logo.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Image.asset(
                              "assets/logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom half with white background and text
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.08,
                  vertical: MediaQuery.of(context).size.height * 0.04,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Main Title
                    Text(
                      "Where Every Borrowed Book\nTells a New Story.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: MediaQuery.of(context).size.width * 0.055,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                        height: 1.3,
                      ),
                    ),
                    
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    
                    // Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Text(
                        "A book is more than just words on a page. It's a shared experience that can connect people.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                    
                    // Get Started Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the Register screen from the sign-up module
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}