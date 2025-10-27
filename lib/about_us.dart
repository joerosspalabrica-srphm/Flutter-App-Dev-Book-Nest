import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutBookNestScreen extends StatelessWidget {
  const AboutBookNestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Logo (watermark style)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/background logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003060),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 5),
                
                // Logo
                Container(
                  width: isSmallScreen ? 200 : 250,
                  height: isSmallScreen ? 200 : 250,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.menu_book,
                        size: 140,
                        color: Color(0xFF003060),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: size.height * 0.02),
                
                // About Container
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.all(size.width * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF003060),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Us!',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF003060),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Book Nest is a peer-to-peer book sharing platform created for students who want an easier and more affordable way to access learning materials. It allows users to lend and borrow textbooks, reference materials, and leisure reads within their academic community.',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          height: 1.6,
                          color: const Color(0xFF003060),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Each member is verified through their school credentials to ensure a safe and trustworthy environment. With organized book categories, direct messaging, tracking features, and a fair penalty system for damaged or unreturned books, Book Nest promotes collaboration, sustainability, and a stronger reading culture among students.',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          height: 1.6,
                          color: const Color(0xFF003060),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: size.height * 0.01),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
