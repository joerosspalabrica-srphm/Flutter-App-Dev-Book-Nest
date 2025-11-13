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
    final width = size.width;
    
    // Responsive breakpoints
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    // Responsive sizing variables
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 28.0 : 36.0));
    final headerVerticalPadding = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final backButtonPadding = isSmallMobile ? 8.0 : (isMobile ? 9.0 : 10.0);
    final backIconSize = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 24.0);
    final titleFontSize = isSmallMobile ? 24.0 : (isMobile ? 26.0 : (isTablet ? 28.0 : 32.0));
    final titleSpacing = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final spacing = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: headerVerticalPadding,
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
                      padding: EdgeInsets.all(backButtonPadding),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003060),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: backIconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: titleSpacing),
                  Text(
                    'Postings',
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003060),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            // Category Filter Chips
            SizedBox(
              height: isSmallMobile ? 40.0 : (isMobile ? 42.0 : 45.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  final categoryPaddingH = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 24.0);
                  final categoryPaddingV = isSmallMobile ? 8.0 : (isMobile ? 9.0 : 10.0);
                  final categoryFontSize = isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0);
                  final categorySpacing = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
                  
                  return Padding(
                    padding: EdgeInsets.only(right: categorySpacing),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: categoryPaddingH,
                          vertical: categoryPaddingV,
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
                            fontSize: categoryFontSize,
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
                  ? Center(
                      child: SizedBox(
                        width: isSmallMobile ? 36.0 : (isMobile ? 40.0 : 48.0),
                        height: isSmallMobile ? 36.0 : (isMobile ? 40.0 : 48.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFFD67730),
                          strokeWidth: isSmallMobile ? 3.0 : (isMobile ? 3.5 : 4.0),
                        ),
                      ),
                    )
                  : filteredBooks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books_outlined,
                                  size: isSmallMobile ? 64.0 : (isMobile ? 72.0 : 80.0),
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: spacing),
                                Text(
                                  selectedCategory == 'All'
                                      ? 'You have no postings'
                                      : 'No books in $selectedCategory',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallMobile ? 18.0 : (isMobile ? 19.0 : 20.0),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: spacing * 0.5),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallMobile ? 24.0 : (isMobile ? 36.0 : 48.0),
                                  ),
                                  child: Text(
                                    selectedCategory == 'All'
                                        ? 'Start posting books to share with others'
                                        : 'You haven\'t posted any books in this category yet',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0),
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: spacing,
                          ),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isSmallMobile ? 2 : (isMobile ? 2 : (isTablet ? 3 : 4)),
                              childAspectRatio: isSmallMobile ? 0.60 : (isMobile ? 0.65 : 0.70),
                              crossAxisSpacing: isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0),
                              mainAxisSpacing: isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0),
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              return _buildBookCard(filteredBooks[index], isSmallMobile, isMobile);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, bool isSmallMobile, bool isMobile) {
    final cardRadius = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final overlayPadding = isSmallMobile ? 6.0 : (isMobile ? 7.0 : 8.0);
    final iconSize = isSmallMobile ? 40.0 : (isMobile ? 45.0 : 50.0);
    final titleFontSize = isSmallMobile ? 11.0 : (isMobile ? 11.5 : 12.0);
    final genreFontSize = isSmallMobile ? 9.0 : (isMobile ? 9.5 : 10.0);
    final textSpacing = isSmallMobile ? 1.0 : (isMobile ? 1.5 : 2.0);
    
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
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
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
                          child: Icon(
                            Icons.book,
                            size: iconSize,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.book,
                        size: iconSize,
                        color: Colors.grey,
                      ),
                    ),
              // Gradient overlay for better text visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(overlayPadding),
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
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: textSpacing),
                      Text(
                        book['genre'] ?? 'Unknown Genre',
                        style: GoogleFonts.poppins(
                          fontSize: genreFontSize,
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