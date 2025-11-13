import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final String chatName;
  final bool isSystemChat;

  const ChatScreen({
    Key? key,
    this.chatName = 'From System',
    this.isSystemChat = true,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [
    Message(
      text: 'Welcome to Book Nest, a mobile application designed to enhance book accessibility among West Visayas State University (WVSU) students through a peer-to-peer lending system. This project addresses challenges faced by students in finding academic or leisure reading materials due to limited library resources and the lack of organized ways to borrow books from each other. Book Nest aims to create a structured and technology-driven solution that promotes collaboration, resource sharing, and community engagement within the university.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // If this is a system chat, show auto-reply
    if (widget.isSystemChat) {
      setState(() {
        _messages.add(Message(
          text: _messageController.text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        
        // Add system auto-reply
        _messages.add(Message(
          text: 'This is a System Generated Message. You cannot reply to this conversation. For assistance, please contact the Book Nest support team.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } else {
      setState(() {
        _messages.add(Message(
          text: _messageController.text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });
    }

    _messageController.clear();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and define responsive breakpoints
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    final isSmallMobile = width < 360;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isSmallMobile, isMobile, isTablet),
            
            // Chat Messages
            Expanded(
              child: _buildMessageList(isSmallMobile, isMobile, isTablet),
            ),
            
            // Input Field
            _buildInputField(isSmallMobile, isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallMobile, bool isMobile, bool isTablet) {
    final horizontalPadding = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final verticalPadding = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final backIconSize = isSmallMobile ? 22.0 : (isMobile ? 23.0 : 24.0);
    final avatarRadius = isSmallMobile ? 18.0 : (isMobile ? 19.0 : 20.0);
    final avatarIconSize = isSmallMobile ? 18.0 : (isMobile ? 19.0 : 20.0);
    final nameFontSize = isSmallMobile ? 16.0 : (isMobile ? 17.0 : (isTablet ? 18.0 : 20.0));
    final spacing = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final moreIconSize = isSmallMobile ? 22.0 : (isMobile ? 23.0 : 24.0);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF003060), size: backIconSize),
            onPressed: () {
              Navigator.pop(context);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: spacing),
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.blue.shade700,
            child: widget.isSystemChat
                ? ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.settings, color: Colors.white, size: avatarIconSize);
                      },
                    ),
                  )
                : Icon(Icons.person, color: Colors.white, size: avatarIconSize),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              widget.chatName,
              style: GoogleFonts.poppins(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF003060),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Color(0xFF003060), size: moreIconSize),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isSmallMobile, bool isMobile, bool isTablet) {
    final horizontalPadding = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final verticalPadding = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index], isSmallMobile, isMobile);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isSmallMobile, bool isMobile) {
    final bubbleSpacing = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final avatarRadius = isSmallMobile ? 14.0 : (isMobile ? 15.0 : 16.0);
    final avatarIconSize = isSmallMobile ? 14.0 : (isMobile ? 15.0 : 16.0);
    final avatarSpacing = isSmallMobile ? 6.0 : (isMobile ? 7.0 : 8.0);
    final bubblePaddingH = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final bubblePaddingV = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final bubbleRadius = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final textFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bubbleSpacing),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.blue.shade700,
              child: widget.isSystemChat
                  ? ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        width: avatarRadius * 2,
                        height: avatarRadius * 2,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.settings, color: Colors.white, size: avatarIconSize);
                        },
                      ),
                    )
                  : Icon(Icons.person, color: Colors.white, size: avatarIconSize),
            ),
            SizedBox(width: avatarSpacing),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: bubblePaddingH, vertical: bubblePaddingV),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF003060)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(bubbleRadius),
                  topRight: Radius.circular(bubbleRadius),
                  bottomLeft: Radius.circular(message.isUser ? bubbleRadius : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : bubbleRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: textFontSize,
                  color: message.isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: avatarSpacing),
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: const Color(0xFFD67730),
              child: Icon(Icons.person, color: Colors.white, size: avatarIconSize),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(bool isSmallMobile, bool isMobile, bool isTablet) {
    final horizontalPadding = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final verticalPadding = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final inputRadius = isSmallMobile ? 22.0 : (isMobile ? 23.0 : 25.0);
    final inputFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);
    final inputPaddingH = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final inputPaddingV = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final buttonSpacing = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final buttonPadding = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final sendIconSize = isSmallMobile ? 18.0 : (isMobile ? 19.0 : 20.0);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(inputRadius),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: inputFontSize,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: inputPaddingH,
                    vertical: inputPaddingV,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: buttonSpacing),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(buttonPadding),
              decoration: BoxDecoration(
                color: const Color(0xFFD67730),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD67730).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: sendIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}