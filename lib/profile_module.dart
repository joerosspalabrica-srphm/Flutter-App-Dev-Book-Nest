import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homepage_module' show HomeScreen;
import 'favorite_module.dart' show FavoritesScreen;
import 'chat_module.dart' show ChatsScreen;
import 'my-postings_module.dart' show PostingsScreen;

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
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  int selectedNavIndex = 3; // Profile is at index 3
  late List<AnimationController> _iconAnimationControllers;

  @override
  void initState() {
    super.initState();
    _iconAnimationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _iconAnimationControllers[3].forward(); // Profile icon is active
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
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
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
                  child: Center(
                    child: Text(
                      '👤',
                      style: TextStyle(fontSize: isSmallScreen ? 50 : 60),
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.02),
                
                // Name
                Text(
                  'Joeross Palabrica',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF003060),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: size.height * 0.04),
                
                // Menu Items Container
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () {},
                        isSmallScreen: isSmallScreen,
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
                        isSmallScreen: isSmallScreen,
                      ),
                      const Divider(height: 30),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About Book Nest',
                        onTap: () {},
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: size.height * 0.03),
                
                // Logout and Delete Container
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Log Out',
                        onTap: () {},
                        isSmallScreen: isSmallScreen,
                      ),
                      const Divider(height: 30),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        onTap: () {},
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                Icons.menu_book_rounded,
                Icons.menu_book_rounded,
                1,
              ),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_rounded,
                2,
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                Icons.person_rounded,
                Icons.person_rounded,
                3,
              ),
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
                  ? const Color(0xFFD67730)
                  : const Color(0xFF003060),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF003060),
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            SizedBox(width: isSmallScreen ? 15 : 20),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 15 : 17,
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