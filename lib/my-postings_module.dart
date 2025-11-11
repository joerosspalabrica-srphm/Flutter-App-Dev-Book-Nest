import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'profile_module.dart' show ProfileScreen;
import 'book-detail-screen_module.dart' show BookDetailScreen;

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
    'Non - Fiction',
    'Mystery',
    'Fiction',
  ];

  List<Map<String, dynamic>> _myBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPostings();
  }

  Future<void> _loadMyPostings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('books')
          .orderByChild('ownerId')
          .equalTo(user.uid)
          .once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map?;
        if (data != null) {
          final List<Map<String, dynamic>> loadedBooks = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              final bookData = Map<String, dynamic>.from(value);
              bookData['id'] = key; // Store the bookId
              loadedBooks.add(bookData);
            }
          });

          // Sort by createdAt timestamp (newest first)
          loadedBooks.sort((a, b) {
            final aTime = a['createdAt'] ?? 0;
            final bTime = b['createdAt'] ?? 0;
            return bTime.compareTo(aTime);
          });

          if (mounted) {
            setState(() {
              _myBooks = loadedBooks;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading my postings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'All') {
      return _myBooks;
    }
    return _myBooks.where((book) => book['genre'] == selectedCategory).toList();
  }

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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD67730),
                      ),
                    )
                  : filteredBooks.isEmpty
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
                                selectedCategory == 'All'
                                    ? 'You have no postings'
                                    : 'No books in $selectedCategory',
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
                                  selectedCategory == 'All'
                                      ? 'Start posting books to share with others'
                                      : 'You haven\'t posted any books in this category yet',
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              return _buildBookCard(filteredBooks[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () {
        // Navigate to book detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              book: book,
              bookId: book['id'] ?? '',
            ),
          ),
        ).then((_) {
          // Reload postings when returning from detail screen
          _loadMyPostings();
        });
      },
      child: Container(
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
              book['imageUrl'] != null && (book['imageUrl'] as String).isNotEmpty
                  ? Image.memory(
                      base64Decode(book['imageUrl']),
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
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.book,
                        size: 50,
                        color: Colors.grey,
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book['title'] ?? 'Untitled',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book['genre'] ?? 'Unknown Genre',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}