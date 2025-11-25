import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'book-detail-screen_module.dart' show BookDetailScreen;
import 'notification_system_module.dart';
import 'book_management_module.dart' show BookManagementScreen;
import 'error_handler_module.dart';

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
  int _selectedTabIndex = 0; // 0 for My Books, 1 for Requests
  
  final List<String> categories = [
    'All',
    'Education',
    'Non - Fiction',
    'Mystery',
    'Fiction',
  ];

  List<Map<String, dynamic>> _myBooks = [];
  List<Map<String, dynamic>> _borrowRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPostings();
    _loadBorrowRequests();
  }

  Future<void> _refreshData() async {
    try {
      await _loadMyPostings();
      await _loadBorrowRequests();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context: context,
          message: 'Failed to refresh data',
          onRetry: _refreshData,
        );
      }
    }
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

  Future<void> _loadBorrowRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load all borrow requests where user is the owner
      final snapshot = await FirebaseDatabase.instance
          .ref('borrows')
          .orderByChild('ownerId')
          .equalTo(user.uid)
          .once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map?;
        if (data != null) {
          final List<Map<String, dynamic>> loadedRequests = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              final requestData = Map<String, dynamic>.from(value);
              requestData['id'] = key; // Store the request ID
              loadedRequests.add(requestData);
            }
          });

          // Sort by requestedAt timestamp (newest first)
          loadedRequests.sort((a, b) {
            final aTime = a['requestedAt'] ?? 0;
            final bTime = b['requestedAt'] ?? 0;
            return bTime.compareTo(aTime);
          });

          if (mounted) {
            setState(() {
              _borrowRequests = loadedRequests;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading borrow requests: $e');
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      // Get the request data to find the bookId
      final requestSnapshot = await FirebaseDatabase.instance
          .ref('borrows/$requestId')
          .once();
      
      if (!requestSnapshot.snapshot.exists) {
        throw Exception('Request not found');
      }
      
      final requestData = requestSnapshot.snapshot.value as Map;
      final bookId = requestData['bookId'];
      final requesterId = requestData['userId'];
      final bookTitle = requestData['bookTitle'] ?? 'Unknown';
      
      // Get owner name
      final currentUser = FirebaseAuth.instance.currentUser;
      String ownerName = 'Book owner';
      if (currentUser != null) {
        final userSnapshot = await FirebaseDatabase.instance
            .ref('users/${currentUser.uid}/username')
            .once();
        if (userSnapshot.snapshot.exists) {
          ownerName = userSnapshot.snapshot.value.toString();
        }
      }
      
      // Update request status
      await FirebaseDatabase.instance
          .ref('borrows/$requestId')
          .update({'status': status});

      // Send notification to requester
      final notificationSystem = NotificationSystemModule();
      if (status == 'approved') {
        await notificationSystem.notifyRequestApproved(
          requesterId: requesterId,
          bookTitle: bookTitle,
          ownerName: ownerName,
          requestId: requestId,
        );
      } else if (status == 'rejected') {
        await notificationSystem.notifyRequestRejected(
          requesterId: requesterId,
          bookTitle: bookTitle,
          ownerName: ownerName,
          requestId: requestId,
        );
      }

      // If approved, mark the book as borrowed
      if (status == 'approved' && bookId != null) {
        await FirebaseDatabase.instance
            .ref('books/$bookId')
            .update({'status': 'borrowed'});
        
        // Reload postings to reflect the status change
        _loadMyPostings();
      }

      // Reload requests
      _loadBorrowRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved' 
                  ? 'Request approved and book marked as borrowed'
                  : 'Request rejected',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: status == 'approved' 
                ? Colors.green 
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating request status: $e');
      if (mounted) {
        ErrorHandler.showFirebaseError(
          context: context,
          operation: 'update request status',
          error: e,
          onRetry: () => _updateRequestStatus(requestId, status),
        );
      }
    }
  }

  Future<void> _markAsReturned(String requestId) async {
    try {
      // Get the request data to find the bookId
      final requestSnapshot = await FirebaseDatabase.instance
          .ref('borrows/$requestId')
          .once();
      
      if (!requestSnapshot.snapshot.exists) {
        throw Exception('Request not found');
      }
      
      final requestData = requestSnapshot.snapshot.value as Map;
      final bookId = requestData['bookId'];
      
      if (bookId == null) {
        throw Exception('Book ID not found in request');
      }

      // Mark the book as available
      await FirebaseDatabase.instance
          .ref('books/$bookId')
          .update({'status': 'available'});
      
      // Update the request to mark as returned
      await FirebaseDatabase.instance
          .ref('borrows/$requestId')
          .update({
            'returned': true,
            'returnedAt': DateTime.now().millisecondsSinceEpoch,
          });

      // Reload postings and requests
      _loadMyPostings();
      _loadBorrowRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Book marked as returned and available again',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error marking book as returned: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark book as returned',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
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
                      Navigator.pop(context);
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
                  Expanded(
                    child: Text(
                      'Postings & Requests',
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003060),
                      ),
                    ),
                  ),
                  // Manage Books Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookManagementScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 12.0 : 16.0,
                        vertical: isSmallMobile ? 8.0 : 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003060),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: isSmallMobile ? 16.0 : 18.0,
                          ),
                          if (!isSmallMobile) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Manage',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            // Tab Selector
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 
                              ? const Color(0xFF003060) 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'My Books',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedTabIndex == 0 
                                  ? Colors.white 
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 
                              ? const Color(0xFFD67730) 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Requests',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTabIndex == 1 
                                      ? Colors.white 
                                      : Colors.grey[700],
                                ),
                              ),
                              if (_borrowRequests.where((r) => r['status'] == 'pending').isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_borrowRequests.where((r) => r['status'] == 'pending').length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            // Category Filter Chips (only show for My Books tab)
            if (_selectedTabIndex == 0)
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

            // Content Area - Books Grid or Requests List
            Expanded(
              child: _isLoading
                  ? Padding(
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
                        itemCount: 6,
                        itemBuilder: (context, index) => _buildBookCardSkeleton(isSmallMobile, isMobile),
                      ),
                    )
                  : _selectedTabIndex == 0
                      ? _buildBooksGrid(isSmallMobile, isMobile, isTablet, horizontalPadding, spacing)
                      : _buildRequestsList(isSmallMobile, isMobile, isTablet, horizontalPadding, spacing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid(bool isSmallMobile, bool isMobile, bool isTablet, double horizontalPadding, double spacing) {
    if (filteredBooks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD67730),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
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
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFD67730),
      child: Padding(
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
    );
  }

  Widget _buildRequestsList(bool isSmallMobile, bool isMobile, bool isTablet, double horizontalPadding, double spacing) {
    if (_borrowRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD67730),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: isSmallMobile ? 64.0 : (isMobile ? 72.0 : 80.0),
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: spacing),
                    Text(
                      'No borrow requests',
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
                  'Borrow requests for your books will appear here',
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
      ),
        ),
      ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFD67730),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: spacing,
        ),
        itemCount: _borrowRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_borrowRequests[index], isSmallMobile, isMobile);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isSmallMobile, bool isMobile) {
    final status = request['status'] ?? 'pending';
    final isReturned = request['returned'] == true;
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;
    String statusText = status.toUpperCase();
    
    if (isReturned) {
      statusColor = Colors.blue;
      statusIcon = Icons.assignment_return;
      statusText = 'RETURNED';
    } else if (status == 'approved') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['bookTitle'] ?? 'Unknown Book',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by ${request['borrowerName'] ?? 'Unknown'}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 14,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: isMobile ? 16 : 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _updateRequestStatus(request['id'], 'approved');
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 48,
                          ),
                          title: Text(
                            'Decline Request',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF003060),
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to decline this borrow request from ${request['requesterName']}?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        _updateRequestStatus(request['id'], 'rejected');
                      }
                    },
                    icon: const Icon(Icons.close, size: 20),
                    label: Text(
                      'Decline',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'approved' && !isReturned) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _markAsReturned(request['id']);
                },
                icon: const Icon(Icons.assignment_return, size: 20),
                label: Text(
                  'Mark as Returned',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003060),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
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
              // Status watermark (if borrowed or reserved)
              if (book['status'] == 'borrowed' || book['status'] == 'reserved')
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Text(
                          book['status'] == 'borrowed' ? 'BORROWED' : 'RESERVED',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallMobile ? 18.0 : (isMobile ? 20.0 : 22.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Action buttons at top
              Positioned(
                top: overlayPadding,
                right: overlayPadding,
                child: _buildActionMenu(book, isSmallMobile, isMobile),
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

  Widget _buildActionMenu(Map<String, dynamic> book, bool isSmallMobile, bool isMobile) {
    final iconSize = isSmallMobile ? 24.0 : (isMobile ? 26.0 : 28.0);
    
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(isSmallMobile ? 4.0 : 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.more_vert,
          color: const Color(0xFF003060),
          size: iconSize * 0.7,
        ),
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      offset: const Offset(0, 8),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'borrowed',
          child: Row(
            children: [
              Icon(
                Icons.book_outlined,
                color: const Color(0xFF003060),
                size: iconSize * 0.8,
              ),
              SizedBox(width: 12),
              Text(
                'Mark as Borrowed',
                style: GoogleFonts.poppins(
                  fontSize: isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0),
                  color: const Color(0xFF003060),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reserved',
          child: Row(
            children: [
              Icon(
                Icons.bookmark_outline,
                color: const Color(0xFFD67730),
                size: iconSize * 0.8,
              ),
              SizedBox(width: 12),
              Text(
                'Mark as Reserved',
                style: GoogleFonts.poppins(
                  fontSize: isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0),
                  color: const Color(0xFF003060),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'available',
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: iconSize * 0.8,
              ),
              SizedBox(width: 12),
              Text(
                'Mark as Available',
                style: GoogleFonts.poppins(
                  fontSize: isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0),
                  color: const Color(0xFF003060),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: iconSize * 0.8,
              ),
              SizedBox(width: 12),
              Text(
                'Delete Book',
                style: GoogleFonts.poppins(
                  fontSize: isSmallMobile ? 13.0 : (isMobile ? 13.5 : 14.0),
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleAction(value, book),
    );
  }

  Future<void> _handleAction(String action, Map<String, dynamic> book) async {
    final bookId = book['id'];
    if (bookId == null) return;

    if (action == 'delete') {
      // Show confirmation dialog for delete
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Book',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${book['title']}"? This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _deleteBook(bookId);
      }
    } else {
      // Update status (borrowed, reserved, or available)
      await _updateBookStatus(bookId, action);
    }
  }

  Widget _buildBookCardSkeleton(bool isSmallMobile, bool isMobile) {
    final coverHeight = isSmallMobile ? 120.0 : (isMobile ? 130.0 : 140.0);
    final cardPadding = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    
    return Container(
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
          Container(
            height: coverHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: isSmallMobile ? 48.0 : 60.0,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: isSmallMobile ? 14.0 : 16.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: isSmallMobile ? 10.0 : 12.0,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: isSmallMobile ? 18.0 : 20.0,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    try {
      await FirebaseDatabase.instance.ref('books/$bookId').remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Book deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF003060),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Reload postings
        _loadMyPostings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete book: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateBookStatus(String bookId, String status) async {
    try {
      await FirebaseDatabase.instance.ref('books/$bookId').update({
        'status': status,
      });
      
      if (mounted) {
        String message = 'Book marked as ${status == 'available' ? 'available' : status}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFD67730),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Reload postings
        _loadMyPostings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update book status: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}