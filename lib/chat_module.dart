import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message_module.dart' show ChatScreen;
import 'homepage_module' show HomeScreen;
import 'favorite_module.dart' show FavoritesScreen;
import 'profile_module.dart' show ProfileScreen;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatsScreen(),
    );
  }
}

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<ChatItem> _filteredChats = [];
  int selectedNavIndex = 2; // Messages tab selected by default
  late List<AnimationController> _iconAnimationControllers;
  
  final List<ChatItem> _allChats = [
    ChatItem(
      name: 'From System',
      message: 'Welcome to Nest Book…',
      avatarColor: Colors.blue.shade700,
      initials: 'SY',
      isSystemChat: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredChats = _allChats;
    _iconAnimationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _iconAnimationControllers[2].forward(); // Messages icon selected by default
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _allChats;
      } else {
        _filteredChats = _allChats.where((chat) {
          return chat.name.toLowerCase().contains(query.toLowerCase()) ||
              chat.message.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    // Responsive breakpoints
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    // Responsive sizing
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 32.0 : 40.0));
    final titleFontSize = isSmallMobile ? 28.0 : (isMobile ? 32.0 : (isTablet ? 36.0 : 40.0));
    final searchFontSize = isSmallMobile ? 14.0 : (isMobile ? 16.0 : 18.0);
    final searchIconSize = isSmallMobile ? 20.0 : (isMobile ? 24.0 : 28.0);
    final verticalPadding = isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0);
    final spacing = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Text(
                'Chats',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003060),
                ),
              ),
            ),
            
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterChats,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: searchFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: searchIconSize,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: verticalPadding,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: spacing),
            
            // Chat List
            Expanded(
              child: _filteredChats.isEmpty
                  ? Center(
                      child: Text(
                        'No chats found',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: searchFontSize,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredChats.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        return ChatTile(
                          chat: chat,
                          isSmallMobile: isSmallMobile,
                          isMobile: isMobile,
                          horizontalPadding: horizontalPadding,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedNavIndex,
          onTap: (index) {
            setState(() {
              _iconAnimationControllers[selectedNavIndex].reverse();
              selectedNavIndex = index;
              _iconAnimationControllers[index].forward();
            });
            
            if (index == 0) {
              // Navigate to homepage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            } else if (index == 1) {
              // Navigate to favorites
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            } else if (index == 3) {
              // Navigate to profile
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD67730),
          unselectedItemColor: const Color(0xFF003060),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.home_rounded, Icons.home_rounded, 0, isSmallMobile, isMobile),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.menu_book_rounded, Icons.menu_book_rounded, 1, isSmallMobile, isMobile),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.chat_bubble_rounded, Icons.chat_bubble_rounded, 2, isSmallMobile, isMobile),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.person_rounded, Icons.person_rounded, 3, isSmallMobile, isMobile),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData outlinedIcon, IconData filledIcon, int index, bool isSmallMobile, bool isMobile) {
    // Responsive icon size
    final iconSize = isSmallMobile ? 28.0 : (isMobile ? 32.0 : 36.0);
    
    return AnimatedBuilder(
      animation: _iconAnimationControllers[index],
      builder: (context, child) {
        final animation = _iconAnimationControllers[index];
        final isSelected = selectedNavIndex == index;
        
        // Elastic bounce curve for scale
        final scaleValue = isSelected 
            ? 1.0 + (Curves.elasticOut.transform(animation.value) * 0.25)
            : 1.0 - (animation.value * 0.1);
        
        // Subtle rotation for dynamic effect
        final rotationValue = isSelected
            ? (Curves.easeOutBack.transform(animation.value) * 0.1) - 0.05
            : 0.0;
        
        return Transform.rotate(
          angle: rotationValue,
          child: Transform.scale(
            scale: scaleValue,
            child: Icon(
              selectedNavIndex == index ? filledIcon : outlinedIcon,
              size: iconSize,
              color: selectedNavIndex == index
                  ? const Color(0xFFD67730)
                  : const Color(0xFF003060),
            ),
          ),
        );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatItem chat;
  final bool isSmallMobile;
  final bool isMobile;
  final double horizontalPadding;

  const ChatTile({
    Key? key,
    required this.chat,
    required this.isSmallMobile,
    required this.isMobile,
    required this.horizontalPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for chat tile
    final avatarRadius = isSmallMobile ? 28.0 : (isMobile ? 32.0 : 36.0);
    final avatarSize = avatarRadius * 2;
    final avatarSpacing = isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0);
    final verticalPadding = isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0);
    final nameFontSize = isSmallMobile ? 15.0 : (isMobile ? 17.0 : 19.0);
    final messageFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 16.0);
    final initialsFontSize = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final unreadDotSize = isSmallMobile ? 10.0 : (isMobile ? 10.0 : 12.0);
    final dividerLeftPadding = avatarSize + avatarSpacing + horizontalPadding;
    
    return Column(
      children: [
        InkWell(
          onTap: () {
            // Mark as read and navigate to message module
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatName: chat.name,
                  isSystemChat: chat.isSystemChat,
                ),
              ),
            ).then((_) {
              // Mark as read when returning from message screen
              chat.isUnread = false;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: chat.avatarColor,
                  child: chat.isSystemChat
                      ? ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                chat.initials,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: initialsFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          chat.initials,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: initialsFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(width: avatarSpacing),
                // Chat Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: GoogleFonts.poppins(
                                fontSize: nameFontSize,
                                fontWeight: chat.isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.isUnread)
                            Container(
                              width: unreadDotSize,
                              height: unreadDotSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD67730),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isSmallMobile ? 3 : 4),
                      Text(
                        chat.message,
                        style: GoogleFonts.poppins(
                          fontSize: messageFontSize,
                          fontWeight: chat.isUnread ? FontWeight.w500 : FontWeight.w400,
                          color: chat.isUnread ? Colors.black87 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider
        Padding(
          padding: EdgeInsets.only(
            left: dividerLeftPadding,
            right: horizontalPadding,
          ),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final Color avatarColor;
  final String initials;
  final bool isSystemChat;
  bool isUnread;

  ChatItem({
    required this.name,
    required this.message,
    required this.avatarColor,
    required this.initials,
    this.isSystemChat = false,
    this.isUnread = true,
  });
}
