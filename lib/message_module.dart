import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool showDelivered;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.showDelivered = true,
  });
}

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String chatName;
  final bool isSystemChat;
  final String? otherUserId;

  const ChatScreen({
    Key? key,
    this.chatId,
    this.chatName = 'From System',
    this.isSystemChat = true,
    this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  late DatabaseReference _messagesRef;
  late DatabaseReference _chatRef;
  String _otherUserName = '';
  File? _otherUserAvatar;
  bool _isLoadingProfile = true;
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
    if (widget.otherUserId != null && !widget.isSystemChat) {
      _loadOtherUserProfile();
    } else {
      _otherUserName = widget.chatName;
      _isLoadingProfile = false;
    }
  }
  
  Future<void> _loadOtherUserProfile() async {
    try {
      print('DEBUG: Loading other user profile. otherUserId: ${widget.otherUserId}, chatName: ${widget.chatName}');
      
      if (widget.otherUserId == null) {
        print('DEBUG: otherUserId is null, using chatName: ${widget.chatName}');
        setState(() {
          _otherUserName = widget.chatName;
          _isLoadingProfile = false;
        });
        return;
      }

      print('DEBUG: Fetching user data from Firebase for userId: ${widget.otherUserId}');
      // Fetch user's current name from Firebase
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/${widget.otherUserId}')
          .once();
      
      print('DEBUG: User snapshot exists: ${userSnapshot.snapshot.exists}');
      if (userSnapshot.snapshot.value != null) {
        final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>;
        _otherUserName = userData['username'] ?? widget.chatName;
        print('DEBUG: Found username in Firebase: $_otherUserName');
      } else {
        _otherUserName = widget.chatName;
        print('DEBUG: No user data found, using chatName: $_otherUserName');
      }

      // Load user's avatar from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final avatarBase64 = prefs.getString('avatar_base64_${widget.otherUserId}');
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(avatarBase64);
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/chat_avatar_${widget.otherUserId}.png');
          await file.writeAsBytes(bytes);
          _otherUserAvatar = file;
        } catch (e) {
          print('Error loading chat user avatar: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading other user profile: $e');
      if (mounted) {
        setState(() {
          _otherUserName = widget.chatName;
          _isLoadingProfile = false;
        });
      }
    }
  }
  
  void _initializeChat() {
    if (widget.isSystemChat) {
      // System chat with static messages
      _messages = [
        Message(
          text: 'Welcome to Book Nest, a mobile application designed to enhance book accessibility among West Visayas State University (WVSU) students through a peer-to-peer lending system. This project addresses challenges faced by students in finding academic or leisure reading materials due to limited library resources and the lack of organized ways to borrow books from each other. Book Nest aims to create a structured and technology-driven solution that promotes collaboration, resource sharing, and community engagement within the university.',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
    } else if (widget.chatId != null) {
      // Real chat with Firebase
      _messagesRef = FirebaseDatabase.instance.ref('chats/${widget.chatId}/messages');
      _chatRef = FirebaseDatabase.instance.ref('chats/${widget.chatId}');
      _loadMessages();
    }
  }
  
  void _loadMessages() {
    _messagesRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Message> loadedMessages = [];
        data.forEach((key, value) {
          if (value is Map) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            loadedMessages.add(Message(
              text: value['text'] ?? '',
              isUser: value['senderId'] == currentUserId,
              timestamp: DateTime.fromMillisecondsSinceEpoch(value['timestamp'] ?? 0),
            ));
          }
        });
        loadedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (mounted) {
          setState(() {
            _messages = loadedMessages;
          });
          _scrollToBottom();
        }
      }
    });
  }
  
  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // If this is a system chat, show auto-reply
    if (widget.isSystemChat) {
      setState(() {
        _messages.add(Message(
          text: messageText,
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
      _scrollToBottom();
    } else if (widget.chatId != null) {
      // Send to Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final messageData = {
        'text': messageText,
        'senderId': currentUser.uid,
        'timestamp': ServerValue.timestamp,
      };
      
      await _messagesRef.push().set(messageData);
      
      // Update last message in chat metadata and mark as unread for recipient
      await _chatRef.update({
        'lastMessage': messageText,
        'lastMessageTime': ServerValue.timestamp,
        'readBy/${currentUser.uid}': true, // Keep as read for sender
      });
      
      // Mark as unread for the other user
      if (widget.otherUserId != null) {
        await _chatRef.update({
          'readBy/${widget.otherUserId}': false,
        });
      }
      
      _scrollToBottom();
    }
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
          _isLoadingProfile && !widget.isSystemChat
              ? CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.blue.shade700,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.blue.shade700,
                  backgroundImage: _otherUserAvatar != null ? FileImage(_otherUserAvatar!) : null,
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
                      : (_otherUserAvatar == null
                          ? Icon(Icons.person, color: Colors.white, size: avatarIconSize)
                          : null),
                ),
          SizedBox(width: spacing),
          Expanded(
            child: _isLoadingProfile && !widget.isSystemChat
                ? Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Text(
                    _otherUserName.isNotEmpty ? _otherUserName : widget.chatName,
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
    final deliveredFontSize = isSmallMobile ? 10.0 : (isMobile ? 10.5 : 11.0);
    
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
            child: GestureDetector(
              onTap: message.isUser ? () {
                setState(() {
                  message.showDelivered = !message.showDelivered;
                });
              } : null,
              child: Column(
                crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
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
                  if (message.isUser && message.showDelivered) ...[
                    SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Text(
                        'Delivered',
                        style: GoogleFonts.poppins(
                          fontSize: deliveredFontSize,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
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