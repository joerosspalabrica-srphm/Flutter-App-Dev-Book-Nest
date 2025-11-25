import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'book-detail-screen_module.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId; // The user ID of the profile to view
  final String? userName; // Optional: pass username if already known

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  String userName = 'User';
  String userBio = '';
  File? _avatarImage;
  double userRating = 0.0;
  int totalRatings = 0;
  List<Map<String, dynamic>> userPostings = [];
  bool isLoading = true;

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
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _loadUserName(),
      _loadUserBio(),
      _loadUserAvatar(),
      _loadUserRating(),
      _loadUserPostings(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserName() async {
    try {
      if (widget.userName != null && widget.userName!.isNotEmpty) {
        setState(() {
          userName = widget.userName!;
        });
        return;
      }

      final userRef = FirebaseDatabase.instance.ref('users/${widget.userId}/username');
      final snapshot = await userRef.get().timeout(const Duration(seconds: 5));

      if (snapshot.exists && snapshot.value != null) {
        if (mounted) {
          setState(() {
            userName = snapshot.value.toString();
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error loading username: $e');
    }
  }

  Future<void> _loadUserBio() async {
    try {
      final bioRef = FirebaseDatabase.instance.ref('users/${widget.userId}/bio');
      final snapshot = await bioRef.get().timeout(const Duration(seconds: 5));

      if (snapshot.exists && snapshot.value != null) {
        if (mounted) {
          setState(() {
            userBio = snapshot.value.toString();
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error loading bio: $e');
    }
  }

  Future<void> _loadUserAvatar() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar_${widget.userId}.png');

      if (await avatarFile.exists()) {
        if (mounted) {
          setState(() {
            _avatarImage = avatarFile;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error loading avatar: $e');
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final ratingRef = FirebaseDatabase.instance.ref('users/${widget.userId}/rating');
      final snapshot = await ratingRef.get().timeout(const Duration(seconds: 5));

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map?;
        if (data != null) {
          if (mounted) {
            setState(() {
              userRating = (data['average'] ?? 0.0).toDouble();
              totalRatings = (data['count'] ?? 0).toInt();
            });
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error loading rating: $e');
    }
  }

  Future<void> _loadUserPostings() async {
    try {
      final postingsRef = FirebaseDatabase.instance.ref('books');
      final snapshot = await postingsRef
          .orderByChild('ownerId')
          .equalTo(widget.userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.exists && snapshot.value != null) {
        final booksMap = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedPostings = [];

        booksMap.forEach((key, value) {
          final book = Map<String, dynamic>.from(value as Map);
          book['id'] = key;
          loadedPostings.add(book);
        });

        // Sort by createdAt timestamp (newest first)
        loadedPostings.sort((a, b) {
          final aTime = a['createdAt'] ?? 0;
          final bTime = b['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        if (mounted) {
          setState(() {
            userPostings = loadedPostings;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error loading postings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 360;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 28.0 : 36.0));
    final verticalPadding = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final avatarSize = isSmallMobile ? 100.0 : (isMobile ? 110.0 : (isTablet ? 120.0 : 140.0));
    final nameFontSize = isSmallMobile ? 22.0 : (isMobile ? 24.0 : (isTablet ? 26.0 : 30.0));

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF003060)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF003060),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003060)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userName,
          style: poppinsStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003060),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF003060),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _avatarImage != null
                      ? Image.file(
                          _avatarImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(avatarSize);
                          },
                        )
                      : _buildDefaultAvatar(avatarSize),
                ),
              ),

              SizedBox(height: isSmallMobile ? 16 : 20),

              // Name
              Text(
                userName,
                style: poppinsStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003060),
                ),
                textAlign: TextAlign.center,
              ),

              // Bio
              SizedBox(height: isSmallMobile ? 8 : 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 24 : 32),
                child: Text(
                  userBio.isNotEmpty ? userBio : 'No bio yet',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallMobile ? 12 : 13,
                    color: userBio.isNotEmpty ? Colors.grey[600]! : Colors.grey[400]!,
                    height: 1.4,
                    fontStyle: userBio.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: isSmallMobile ? 16 : 20),

              // Rating Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFD67730),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userRating.toStringAsFixed(1),
                      style: poppinsStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003060),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($totalRatings)',
                      style: poppinsStyle(
                        fontSize: 14,
                        color: Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallMobile ? 24 : 32),

              // Postings Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Posted Books',
                  style: poppinsStyle(
                    fontSize: isSmallMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF003060),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Postings List
              if (userPostings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No posts yet',
                    style: poppinsStyle(
                      fontSize: 14,
                      color: Colors.grey[600]!,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userPostings.length,
                  itemBuilder: (context, index) {
                    final post = userPostings[index];
                    return _buildPostingCard(post, isSmallMobile, isMobile);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF003060),
      child: Center(
        child: Text(
          '😊',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildPostingCard(Map<String, dynamic> post, bool isSmallMobile, bool isMobile) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              book: post,
              bookId: post['id'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Title
          Text(
            post['title'] ?? 'Untitled',
            style: poppinsStyle(
              fontSize: isSmallMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Author
          if (post['author'] != null)
            Text(
              'by ${post['author']}',
              style: poppinsStyle(
                fontSize: isSmallMobile ? 13 : 14,
                color: Colors.grey[600]!,
              ),
            ),

          const SizedBox(height: 8),

          // Condition & Genre
          Row(
            children: [
              if (post['condition'] != null) ...[
                _buildTag(post['condition'], isSmallMobile),
                const SizedBox(width: 8),
              ],
              if (post['genre'] != null)
                _buildTag(post['genre'], isSmallMobile),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Text(
              post['description'],
              style: poppinsStyle(
                fontSize: isSmallMobile ? 12 : 13,
                color: Colors.grey[700]!,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8 : 10,
        vertical: isSmallMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD67730).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: poppinsStyle(
          fontSize: isSmallMobile ? 11 : 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFD67730),
        ),
      ),
    );
  }
}
