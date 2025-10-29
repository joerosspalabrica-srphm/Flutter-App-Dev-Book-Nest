import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;

  const BookDetailScreen({
    Key? key,
    required this.book,
    required this.bookId,
  }) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.book['ownerId'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Book Cover Section with Back Button
              Stack(
                children: [
                  // Book Cover with gradient background and logo
                  Container(
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getGenreColor(widget.book['genre']),
                          _getGenreColor(widget.book['genre']).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background logo with whitish transparency
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.3,
                            child: Center(
                              child: Image.asset(
                                'assets/background logo.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading background logo: $error');
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        ),
                        // Book cover
                        Center(
                          child: Container(
                            width: 250,
                            height: 350,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.book['imageUrl'] != null && (widget.book['imageUrl'] as String).isNotEmpty
                                  ? Image.memory(
                                      base64Decode(widget.book['imageUrl']),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultBookCover();
                                      },
                                    )
                                  : _buildDefaultBookCover(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003060),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Book Title, Genre, and Favorite Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Genre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book['title'] ?? 'Untitled',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF003060),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book['genre'] ?? 'Unknown Genre',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Favorite Icon
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isFavorite 
                                    ? 'Added to favorites!' 
                                    : 'Removed from favorites',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFFD67730),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isFavorite 
                            ? const Color(0xFFD67730) 
                            : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Grid (Author, Condition, Genre, Language)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.person,
                        label: 'Author',
                        value: widget.book['author'] ?? 'Unknown',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.verified,
                        label: 'Condition',
                        value: widget.book['condition'] ?? 'Used',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.category,
                        label: 'Genre',
                        value: widget.book['genre'] ?? 'Unknown',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.translate,
                        label: 'Language',
                        value: widget.book['language'] ?? 'Unknown',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // About this Book
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About this Book',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.book['about'] ?? 'No description available.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Penalties Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penalties',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    const SizedBox(height: 12),
                      _buildPenaltyItem(
                        'Late Return:',
                        'Php ${widget.book['penalties']?['lateReturn'] ?? 0}',
                      ),
                      _buildPenaltyItem(
                        'Book Damage:',
                        'Php ${widget.book['penalties']?['damage'] ?? 0}',
                      ),
                      _buildPenaltyItem(
                        'Lost or Unreturned:',
                        'Php ${widget.book['penalties']?['lost'] ?? 0}',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Owner Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF4A90E2),
                        child: Text(
                          (widget.book['ownerName'] ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book['ownerName'] ?? 'Unknown Owner',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF003060),
                              ),
                            ),
                            Text(
                              'Owner',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isOwner)
                        InkWell(
                          onTap: () {
                            // Navigate to chat with owner
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Chat feature coming soon!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFFD67730),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD67730),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD67730).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF003060),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF003060),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyItem(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
          ),
        ],
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
  Widget _buildDefaultBookCover() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0033A0),
                const Color(0xFF0066FF),
                Colors.white,
                const Color(0xFFFF0000),
                const Color(0xFFCC0000),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.yellow[700],
                size: 40,
              ),
              const SizedBox(height: 20),
              Text(
                widget.book['title'] ?? 'READINGS IN\nPHILIPPINE\nHISTORY',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Author/s:',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    Text(
                      widget.book['author'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: const Color(0xFF003060),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
