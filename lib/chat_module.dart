import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message_module.dart' show ChatScreen;
import 'homepage_module' show HomeScreen;

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
    final isSmallScreen = size.width < 360;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16.0 : 20.0,
                vertical: isSmallScreen ? 12.0 : 16.0,
              ),
              child: Text(
                'Chats',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 28 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16.0 : 20.0,
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
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Chat List
            Expanded(
              child: _filteredChats.isEmpty
                  ? Center(
                      child: Text(
                        'No chats found',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: isSmallScreen ? 14 : 16,
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
                          isSmallScreen: isSmallScreen,
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
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE67E22),
          unselectedItemColor: const Color(0xFF1B3A5C),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.home_rounded, Icons.home_rounded, 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.menu_book_rounded, Icons.menu_book_rounded, 1),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.chat_bubble_rounded, Icons.chat_bubble_rounded, 2),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.person_rounded, Icons.person_rounded, 3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData outlinedIcon, IconData filledIcon, int index) {
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
              size: 32,
              color: selectedNavIndex == index
                  ? const Color(0xFFE67E22)
                  : const Color(0xFF1B3A5C),
            ),
          ),
        );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatItem chat;
  final bool isSmallScreen;

  const ChatTile({
    Key? key,
    required this.chat,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              horizontal: isSmallScreen ? 16.0 : 20.0,
              vertical: isSmallScreen ? 12.0 : 16.0,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: isSmallScreen ? 28 : 32,
                  backgroundColor: chat.avatarColor,
                  child: chat.isSystemChat
                      ? ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            width: isSmallScreen ? 56 : 64,
                            height: isSmallScreen ? 56 : 64,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                chat.initials,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 16 : 18,
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
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
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
                                fontSize: isSmallScreen ? 15 : 17,
                                fontWeight: chat.isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD67730),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 3 : 4),
                      Text(
                        chat.message,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
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
            left: isSmallScreen ? 84.0 : 96.0,
            right: isSmallScreen ? 16.0 : 20.0,
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
