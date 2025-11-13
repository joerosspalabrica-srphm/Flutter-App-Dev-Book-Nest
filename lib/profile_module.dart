import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'homepage_module' show HomeScreen;
import 'favorite_module.dart' show FavoritesScreen;
import 'chat_module.dart' show ChatsScreen;
import 'my-postings_module.dart' show PostingsScreen;
import 'about_us.dart' show AboutBookNestScreen;
import 'logout_module.dart';
import 'delete-account_module.dart';
import 'edit-profile_module.dart' show ProfileLoginScreen;

// Note: main() is in main.dart, not here
// This module provides the ProfileScreen UI

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  int selectedNavIndex = 3; // Profile is at index 3
  late List<AnimationController> _iconAnimationControllers;
  String userName = 'User'; // Default username
  File? _avatarImage; // Store selected avatar image
  final ImagePicker _imagePicker = ImagePicker();
  int _unreadCount = 0;

  // Helper function for Poppins text style
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
    _loadUserName(); // Load username from Firebase
    _loadSavedAvatar(); // Load saved avatar
    _loadUnreadCount(); // Load unread message count
    _iconAnimationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _iconAnimationControllers[3].forward(); // Profile icon is active
  }

  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() {
          userName = user.displayName!;
        });
        print('DEBUG: Loaded profile username from Firebase Auth: $userName');
      } else {
        print('DEBUG: No displayName in Auth (profile), will fetch from Realtime Database asynchronously');
        
        Future.microtask(() async {
          try {
            final userRef = FirebaseDatabase.instance.ref('users/${user.uid}/username');
            final snapshot = await userRef
                .get()
                .timeout(const Duration(seconds: 5), onTimeout: () {
              print('DEBUG: Realtime Database fetch timed out (profile)');
              throw TimeoutException('Realtime Database timeout', const Duration(seconds: 5));
            });

            if (snapshot.exists && snapshot.value != null) {
              if (mounted) {
                setState(() {
                  userName = snapshot.value.toString();
                });
                print('DEBUG: Loaded profile username from Realtime Database: $userName');
              }
            } else {
              print('DEBUG: No username in Realtime Database (profile), using default "User"');
            }
          } catch (error) {
            print('DEBUG: Error fetching from Realtime Database (profile): $error');
          }
        });
      }
    } else {
      print('DEBUG: No user logged in (profile), using default "User"');
    }
  }

  Future<void> _pickAvatar() async {
    try {
      print('DEBUG: Opening image picker...');
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choose Avatar Source'),
            content: const Text('Select where to pick your avatar from:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
                child: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('DEBUG: Error in _pickAvatar: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('DEBUG: Picking image from gallery...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (pickedFile != null) {
        _updateAvatarImage(pickedFile);
      } else {
        print('DEBUG: User cancelled gallery picker');
      }
    } catch (e) {
      print('DEBUG: Gallery picker error: $e');
      _showErrorMessage('Gallery Error: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      print('DEBUG: Picking image from camera...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      
      if (pickedFile != null) {
        _updateAvatarImage(pickedFile);
      } else {
        print('DEBUG: User cancelled camera picker');
      }
    } catch (e) {
      print('DEBUG: Camera picker error: $e');
      _showErrorMessage('Camera Error: $e');
    }
  }

  void _updateAvatarImage(XFile pickedFile) {
    print('DEBUG: Avatar image selected: ${pickedFile.path}');
    final File imageFile = File(pickedFile.path);
    
    setState(() {
      _avatarImage = imageFile;
    });
    
    // Save avatar path to local storage
    _saveAvatarPath(imageFile.path);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAvatarPath(String imagePath) async {
    try {
      print('DEBUG: Starting to save avatar from: $imagePath');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in, cannot save avatar');
        return;
      }
      
      final sourceFile = File(imagePath);
      final sourceExists = await sourceFile.exists();
      print('DEBUG: Source file exists: $sourceExists');
      
      if (!sourceExists) {
        print('DEBUG: Source file does not exist, cannot save');
        return;
      }
      
      // Read file bytes
      final bytes = await sourceFile.readAsBytes();
      print('DEBUG: Read ${bytes.length} bytes from source file');
      
      // Convert bytes to base64
      final base64String = base64Encode(bytes);
      print('DEBUG: Converted to base64, length: ${base64String.length}');
      
      // Save to SharedPreferences with user-specific key
      final prefs = await SharedPreferences.getInstance();
      final avatarKey = 'avatar_base64_${user.uid}';
      await prefs.setString(avatarKey, base64String);
      
      final retrievedBase64 = prefs.getString(avatarKey);
      print('DEBUG: Avatar base64 saved for user ${user.uid}, retrieved length: ${retrievedBase64?.length ?? 0}');
      
    } catch (e) {
      print('DEBUG: Error saving avatar path: $e');
      print('DEBUG: Stack trace: ${e.toString()}');
    }
  }

  Future<void> _loadSavedAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in, cannot load avatar');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final avatarKey = 'avatar_base64_${user.uid}';
      final base64String = prefs.getString(avatarKey);
      print('DEBUG: Loading avatar for user ${user.uid}, base64 from preferences, length: ${base64String?.length ?? 0}');
      
      if (base64String != null && base64String.isNotEmpty) {
        try {
          // Decode base64 to bytes
          final bytes = base64Decode(base64String);
          print('DEBUG: Decoded base64 to ${bytes.length} bytes');
          
          // Create a temporary file from bytes
          final tempDir = await Directory.systemTemp.createTemp('flutter_avatar');
          final avatarFile = File('${tempDir.path}/avatar.png');
          await avatarFile.writeAsBytes(bytes);
          
          if (mounted) {
            setState(() {
              _avatarImage = avatarFile;
            });
            print('DEBUG: Loaded saved avatar from base64');
          }
        } catch (decodeError) {
          print('DEBUG: Error decoding base64: $decodeError');
        }
      } else {
        print('DEBUG: No saved avatar base64 found in preferences');
      }
    } catch (e) {
      print('DEBUG: Error loading saved avatar: $e');
      print('DEBUG: Stack trace: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
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
    
    // Responsive sizing variables
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : (isTablet ? 28.0 : 36.0));
    final verticalPadding = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final avatarSize = isSmallMobile ? 100.0 : (isMobile ? 110.0 : (isTablet ? 120.0 : 140.0));
    final cameraIconSize = isSmallMobile ? 32.0 : (isMobile ? 34.0 : 36.0);
    final cameraIconInner = isSmallMobile ? 16.0 : (isMobile ? 17.0 : 18.0);
    final emojiSize = isSmallMobile ? 50.0 : (isMobile ? 55.0 : 60.0);
    final nameSpacing = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final nameFontSize = isSmallMobile ? 22.0 : (isMobile ? 24.0 : (isTablet ? 26.0 : 30.0));
    final menuSpacing = isSmallMobile ? 28.0 : (isMobile ? 32.0 : 36.0);
    final containerPadding = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final containerSpacing = isSmallMobile ? 24.0 : (isMobile ? 28.0 : 32.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                // Profile Avatar
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DA3FA),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Avatar image or emoji
                        if (_avatarImage != null)
                          ClipOval(
                            child: Image.file(
                              _avatarImage!,
                              fit: BoxFit.cover,
                              width: avatarSize,
                              height: avatarSize,
                            ),
                          )
                        else
                          Text(
                            '👤',
                            style: TextStyle(fontSize: emojiSize),
                          ),
                        // Camera icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: cameraIconSize,
                            height: cameraIconSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD67730),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: cameraIconInner,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: nameSpacing),
                
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
                
                SizedBox(height: menuSpacing),
                
                // Menu Items Container
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.all(containerPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileLoginScreen(),
                            ),
                          );
                          // Reload profile if changes were made
                          if (result == true) {
                            _loadUserName(); // Reload username
                            _loadSavedAvatar(); // Reload avatar
                          }
                        },
                        isSmallMobile: isSmallMobile,
                        isMobile: isMobile,
                      ),
                      const Divider(height: 30),
                      _buildMenuItem(
                        icon: Icons.access_time,
                        title: 'Posting History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PostingsScreen(),
                            ),
                          );
                        },
                        isSmallMobile: isSmallMobile,
                        isMobile: isMobile,
                      ),
                      const Divider(height: 30),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About Book Nest',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutBookNestScreen(),
                            ),
                          );
                        },
                        isSmallMobile: isSmallMobile,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: containerSpacing),
                
                // Logout and Delete Container
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.all(containerPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Log Out',
                        onTap: () {
                          LogoutModule.showLogoutDialog(context);
                        },
                        isSmallMobile: isSmallMobile,
                        isMobile: isMobile,
                      ),
                      const Divider(height: 30),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        onTap: () {
                          DeleteAccountModule.showDeleteAccountDialog(context);
                        },
                        isSmallMobile: isSmallMobile,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final navIconSize = isSmallMobile ? 28.0 : (isMobile ? 30.0 : 32.0);
          
          return Container(
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
            
            // Navigate to homepage when home icon is tapped
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              ).then((_) {
                // Reset to profile when coming back
                setState(() {
                  _iconAnimationControllers[selectedNavIndex].reverse();
                  selectedNavIndex = 3;
                  _iconAnimationControllers[3].forward();
                });
              });
            }
            // Navigate to favorites module when bookmarks icon is tapped
            else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              ).then((_) {
                // Reset to profile when coming back
                setState(() {
                  _iconAnimationControllers[selectedNavIndex].reverse();
                  selectedNavIndex = 3;
                  _iconAnimationControllers[3].forward();
                });
              });
            }
            // Navigate to chat module when messages icon is tapped
            else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatsScreen(),
                ),
              ).then((_) {
                // Reset to profile when coming back
                setState(() {
                  _iconAnimationControllers[selectedNavIndex].reverse();
                  selectedNavIndex = 3;
                  _iconAnimationControllers[3].forward();
                });
              });
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
                  icon: _buildAnimatedIcon(
                    Icons.home_rounded,
                    Icons.home_rounded,
                    0,
                    navIconSize,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildAnimatedIcon(
                    Icons.menu_book_rounded,
                    Icons.menu_book_rounded,
                    1,
                    navIconSize,
                  ),
                  label: 'Bookmarks',
                ),
                BottomNavigationBarItem(
                  icon: _buildAnimatedIconWithBadge(
                    Icons.chat_bubble_rounded,
                    Icons.chat_bubble_rounded,
                    2,
                    navIconSize,
                    _unreadCount,
                  ),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: _buildAnimatedIcon(
                    Icons.person_rounded,
                    Icons.person_rounded,
                    3,
                    navIconSize,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _loadUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // Listen to chats for unread count
    FirebaseDatabase.instance.ref('chats').onValue.listen((event) {
      final data = event.snapshot.value;
      int count = 0;
      
      if (data != null && data is Map) {
        data.forEach((chatId, chatData) {
          if (chatData is Map && chatData['participants'] != null) {
            final participants = chatData['participants'] as Map;
            // Only count chats where current user is a participant
            if (participants[currentUser.uid] == true) {
              // Check if current user has unread messages
              final readStatus = chatData['readBy'] as Map?;
              final isUnread = readStatus == null || readStatus[currentUser.uid] != true;
              if (isUnread) {
                count++;
              }
            }
          }
        });
      }
      
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Widget _buildAnimatedIcon(IconData outlinedIcon, IconData filledIcon, int index, double iconSize) {
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
  
  Widget _buildAnimatedIconWithBadge(IconData outlinedIcon, IconData filledIcon, int index, double iconSize, int badgeCount) {
    final badgeSize = iconSize * 0.55;
    final badgeFontSize = iconSize * 0.35;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
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
        ),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: EdgeInsets.all(badgeCount > 9 ? 2 : 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD67730),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize,
                minHeight: badgeSize,
              ),
              child: Center(
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSmallMobile,
    required bool isMobile,
  }) {
    final iconContainerPadding = isSmallMobile ? 6.0 : (isMobile ? 7.0 : 8.0);
    final iconSize = isSmallMobile ? 24.0 : (isMobile ? 26.0 : 28.0);
    final iconTextSpacing = isSmallMobile ? 15.0 : (isMobile ? 17.0 : 20.0);
    final textFontSize = isSmallMobile ? 15.0 : (isMobile ? 16.0 : 17.0);
    final verticalPadding = isSmallMobile ? 6.0 : (isMobile ? 7.0 : 8.0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(iconContainerPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF003060),
                size: iconSize,
              ),
            ),
            SizedBox(width: iconTextSpacing),
            Expanded(
              child: Text(
                title,
                style: poppinsStyle(
                  fontSize: textFontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF003060),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}