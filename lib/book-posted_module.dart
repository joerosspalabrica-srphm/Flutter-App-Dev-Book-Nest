import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class BookPostedScreen extends StatefulWidget {
  const BookPostedScreen({Key? key}) : super(key: key);

  @override
  State<BookPostedScreen> createState() => _BookPostedScreenState();
}

class _BookPostedScreenState extends State<BookPostedScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Education',
    'Fiction',
    'Non - Fiction',
    'Mystery',
  ];

  TextStyle poppinsStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    // Responsive breakpoints
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    // Responsive sizing
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 32.0 : 40.0));
    final gridCrossAxisCount = isSmallMobile ? 2 : (isMobile ? 2 : (isTablet ? 3 : 4));
    final gridChildAspectRatio = isSmallMobile ? 0.60 : (isMobile ? 0.65 : (isTablet ? 0.70 : 0.75));
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isMobile, horizontalPadding),

            SizedBox(height: isMobile ? 24 : 32),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Text(
                    'Posted Books',
                    style: poppinsStyle(
                      fontSize: isSmallMobile ? 22 : (isMobile ? 28 : (isTablet ? 32 : 36)),
                      color: const Color(0xFF003060),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: isMobile ? 16 : 20),
                  Expanded(
                    child: Container(
                      height: isMobile ? 48 : 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DCE5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search books',
                          hintStyle: poppinsStyle(
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 20 : 24),

            // Category Filters
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                height: isMobile ? 45 : 50,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.only(right: isMobile ? 12 : 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : 28,
                            vertical: isMobile ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD67730)
                                : const Color(0xFF003060),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD67730)
                                  : const Color(0xFF003060),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            category,
                            style: poppinsStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: isMobile ? 14 : 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: isMobile ? 24 : 28),

            // Books Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('books')
                      .orderByChild('createdAt')
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading books',
                          style: poppinsStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final event = snapshot.data;
                    final dataSnapshot = event?.snapshot;
                    final books = <Map<String, dynamic>>[];

                    if (dataSnapshot != null && dataSnapshot.value != null) {
                      final value = dataSnapshot.value;
                      if (value is Map) {
                        value.forEach((key, dynamic rawBook) {
                          if (rawBook is Map) {
                            final bookMap = Map<String, dynamic>.from(rawBook);
                            bookMap['id'] = key.toString();
                            if (bookMap['penalties'] is Map) {
                              bookMap['penalties'] = Map<String, dynamic>.from(
                                bookMap['penalties'] as Map,
                              );
                            }
                            books.add(bookMap);
                          }
                        });
                      }
                    }

                    books.sort((a, b) {
                      final aCreated = (a['createdAt'] ?? 0);
                      final bCreated = (b['createdAt'] ?? 0);
                      final aValue = aCreated is num ? aCreated.toInt() : 0;
                      final bValue = bCreated is num ? bCreated.toInt() : 0;
                      return bValue.compareTo(aValue);
                    });

                    // Filter by category and search
                    final filteredBooks = books.where((book) {
                      final title = (book['title'] ?? '').toString().toLowerCase();
                      final genre = (book['genre'] ?? '').toString();

                      // Filter by search query
                      if (searchQuery.isNotEmpty && 
                          !title.contains(searchQuery.toLowerCase())) {
                        return false;
                      }
                      
                      // Filter by category
                      if (selectedCategory != 'All' && genre != selectedCategory) {
                        return false;
                      }
                      
                      return true;
                    }).toList();

                    if (filteredBooks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No books found',
                              style: poppinsStyle(
                                fontSize: 20,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'No books available in this category',
                              style: poppinsStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: isMobile ? 16 : 20,
                        mainAxisSpacing: isMobile ? 16 : 20,
                        childAspectRatio: gridChildAspectRatio,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        final bookId = (book['id'] ?? '').toString();
                        return _buildBookCard(book, bookId, isMobile, isSmallMobile);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding, 
        vertical: isMobile ? 16 : 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              decoration: BoxDecoration(
                color: const Color(0xFF003060),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isMobile ? 20 : 24,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Text(
            'Posted Books',
            style: poppinsStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, String bookId, bool isMobile, bool isSmallMobile) {
    final condition = book['condition'] ?? 'Used';
    final isNew = condition.toLowerCase().contains('new');
    final imageUrl = book['imageUrl'] as String?;
    final cardImageHeight = isSmallMobile ? 120.0 : (isMobile ? 140.0 : 160.0);
    
    return GestureDetector(
      onTap: () {
        _showBookDetails(book, bookId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover (uploaded image or placeholder with genre color)
            Container(
              height: cardImageHeight,
              decoration: BoxDecoration(
                color: _getGenreColor(book['genre']),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.memory(
                        base64Decode(imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 60,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 60,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book['title'] ?? 'Untitled',
                      style: poppinsStyle(
                        fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 15),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isMobile ? 4 : 6),
                    
                    // Genre
                    Text(
                      book['genre'] ?? '',
                      style: poppinsStyle(
                        fontSize: isSmallMobile ? 10 : (isMobile ? 11 : 12),
                        color: Colors.grey,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Condition Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isNew 
                            ? const Color(0xFFD67730) 
                            : const Color(0xFF003060),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        condition,
                        style: poppinsStyle(
                          fontSize: isSmallMobile ? 9 : (isMobile ? 10 : 11),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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

  Color _getGenreColor(String? genre) {
    switch (genre?.toLowerCase()) {
      case 'education':
        return const Color(0xFF4A90E2);
      case 'fiction':
        return const Color(0xFF9B59B6);
      case 'non - fiction':
        return const Color(0xFF27AE60);
      case 'mystery':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  void _showBookDetails(Map<String, dynamic> book, String bookId) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isSmallMobile = size.width < 360;
    final modalPadding = isSmallMobile ? 20.0 : (isMobile ? 24.0 : 32.0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(modalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: isMobile ? 40 : 50,
                      height: isMobile ? 4 : 5,
                      margin: EdgeInsets.only(bottom: isMobile ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Book Cover Image
                  if (book['imageUrl'] != null && (book['imageUrl'] as String).isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(book['imageUrl']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: isSmallMobile ? 220 : (isMobile ? 250 : 300),
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                  ],
                  
                  // Book Title
                  Text(
                    book['title'] ?? 'Untitled',
                    style: poppinsStyle(
                      fontSize: isSmallMobile ? 20 : (isMobile ? 24 : 28),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003060),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 8 : 12),
                  
                  // Author
                  Text(
                    'by ${book['author'] ?? 'Unknown Author'}',
                    style: poppinsStyle(
                      fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 24 : 28),
                  
                  // Details Grid
                  _buildDetailRow('Genre', book['genre'] ?? 'N/A', isSmallMobile, isMobile),
                  _buildDetailRow('Condition', book['condition'] ?? 'N/A', isSmallMobile, isMobile),
                  _buildDetailRow('Language', book['language'] ?? 'N/A', isSmallMobile, isMobile),
                  _buildDetailRow('Publisher', book['publisher'] ?? 'N/A', isSmallMobile, isMobile),
                  _buildDetailRow('Publication', book['publication'] ?? 'N/A', isSmallMobile, isMobile),
                  _buildDetailRow('Year', book['year'] ?? 'N/A', isSmallMobile, isMobile),
                  
                  SizedBox(height: isMobile ? 24 : 28),
                  
                  // About
                  if (book['about'] != null && book['about'].toString().isNotEmpty) ...[
                    Text(
                      'About',
                      style: poppinsStyle(
                        fontSize: isSmallMobile ? 16 : (isMobile ? 18 : 20),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      book['about'],
                      style: poppinsStyle(
                        fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
                        color: Colors.grey[700] ?? Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 28),
                  ],
                  
                  // Penalties
                  if (book['penalties'] != null) ...[
                    Text(
                      'Penalties',
                      style: poppinsStyle(
                        fontSize: isSmallMobile ? 16 : (isMobile ? 18 : 20),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildPenaltyRow('Late Return', book['penalties']['lateReturn'], isSmallMobile, isMobile),
                    _buildPenaltyRow('Damage', book['penalties']['damage'], isSmallMobile, isMobile),
                    _buildPenaltyRow('Lost/Unreturned', book['penalties']['lost'], isSmallMobile, isMobile),
                    SizedBox(height: isMobile ? 24 : 28),
                  ],
                  
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: book['status'] == 'available'
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: book['status'] == 'available'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          book['status'] == 'available'
                              ? Icons.check_circle
                              : Icons.access_time,
                          color: book['status'] == 'available'
                              ? Colors.green
                              : Colors.orange,
                          size: isMobile ? 20 : 24,
                        ),
                        SizedBox(width: isMobile ? 8 : 10),
                        Text(
                          book['status'] == 'available'
                              ? 'Available'
                              : 'Not Available',
                          style: poppinsStyle(
                            fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
                            color: book['status'] == 'available'
                                ? Colors.green[700]!
                                : Colors.orange[700]!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallMobile, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12.0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 120 : 140,
            child: Text(
              label,
              style: poppinsStyle(
                fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsStyle(
                fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
                color: const Color(0xFF003060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyRow(String label, dynamic amount, bool isSmallMobile, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: poppinsStyle(
              fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
              color: Colors.grey[700] ?? Colors.grey,
            ),
          ),
          Text(
            '₱${amount ?? 0}',
            style: poppinsStyle(
              fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
              color: const Color(0xFFD67730),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
