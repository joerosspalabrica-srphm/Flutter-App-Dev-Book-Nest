import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_module.dart' show ProfileScreen;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Nest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF003060),
      ),
      home: const PostingsScreen(),
    );
  }
}

class PostingsScreen extends StatefulWidget {
  const PostingsScreen({Key? key}) : super(key: key);

  @override
  State<PostingsScreen> createState() => _PostingsScreenState();
}

class _PostingsScreenState extends State<PostingsScreen> {
  String selectedCategory = 'All';
  
  final List<String> categories = [
    'All',
    'Education',
    'Non-Fiction',
    'Mystery',
    'Fiction',
  ];

  final List<Map<String, String>> books = [];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: 20,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                  const SizedBox(width: 20),
                  Text(
                    'Postings',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003060),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category Filter Chips
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD67730)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD67730)
                                : const Color(0xFF003060),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF003060),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Books Grid or Empty State
            Expanded(
              child: books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You have no postings',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Start posting books to share with others',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.05,
                        vertical: 20,
                      ),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(books[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, String> book) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              book['image']!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.book,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            // Gradient overlay for better text visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  book['title']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}