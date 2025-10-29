import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 24),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text(
                    'Posted Books',
                    style: poppinsStyle(
                      fontSize: 28,
                      color: const Color(0xFF003060),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
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

            const SizedBox(height: 20),

            // Category Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 45,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Books Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
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

                    final books = snapshot.data?.docs ?? [];
                    
                    // Filter by category and search
                    final filteredBooks = books.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final genre = (data['genre'] ?? '').toString();
                      
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final bookDoc = filteredBooks[index];
                        final book = bookDoc.data() as Map<String, dynamic>;
                        return _buildBookCard(book, bookDoc.id);
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003060),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Posted Books',
            style: poppinsStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, String bookId) {
    final condition = book['condition'] ?? 'Used';
    final isNew = condition.toLowerCase().contains('new');
    final imageUrl = book['imageUrl'] as String?;
    
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
              height: 140,
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
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book['title'] ?? 'Untitled',
                      style: poppinsStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Genre
                    Text(
                      book['genre'] ?? '',
                      style: poppinsStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Condition Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontSize: 10,
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
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
                        height: 250,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Book Title
                  Text(
                    book['title'] ?? 'Untitled',
                    style: poppinsStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003060),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Author
                  Text(
                    'by ${book['author'] ?? 'Unknown Author'}',
                    style: poppinsStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Details Grid
                  _buildDetailRow('Genre', book['genre'] ?? 'N/A'),
                  _buildDetailRow('Condition', book['condition'] ?? 'N/A'),
                  _buildDetailRow('Language', book['language'] ?? 'N/A'),
                  _buildDetailRow('Publisher', book['publisher'] ?? 'N/A'),
                  _buildDetailRow('Publication', book['publication'] ?? 'N/A'),
                  _buildDetailRow('Year', book['year'] ?? 'N/A'),
                  
                  const SizedBox(height: 24),
                  
                  // About
                  if (book['about'] != null && book['about'].toString().isNotEmpty) ...[
                    Text(
                      'About',
                      style: poppinsStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['about'],
                      style: poppinsStyle(
                        fontSize: 14,
                        color: Colors.grey[700] ?? Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Penalties
                  if (book['penalties'] != null) ...[
                    Text(
                      'Penalties',
                      style: poppinsStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPenaltyRow('Late Return', book['penalties']['lateReturn']),
                    _buildPenaltyRow('Damage', book['penalties']['damage']),
                    _buildPenaltyRow('Lost/Unreturned', book['penalties']['lost']),
                    const SizedBox(height: 24),
                  ],
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          book['status'] == 'available'
                              ? 'Available'
                              : 'Not Available',
                          style: poppinsStyle(
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: poppinsStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsStyle(
                fontSize: 14,
                color: const Color(0xFF003060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyRow(String label, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: poppinsStyle(
              fontSize: 14,
              color: Colors.grey[700] ?? Colors.grey,
            ),
          ),
          Text(
            '₱${amount ?? 0}',
            style: poppinsStyle(
              fontSize: 14,
              color: const Color(0xFFD67730),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
