import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skillswapper/ai_assistant_screen.dart';
import 'package:skillswapper/match.dart';
import 'package:skillswapper/welcome_screen.dart';
import 'combinedrequestsscreen.dart';

class DashboardScreen extends StatefulWidget {
  final String currentUser;

  DashboardScreen({required this.currentUser});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showFirstButton = false;
  bool _showSecondButton = false;
  String username = "User";

  Future<void> loadUserData() async {
    final data = await getUserData(widget.currentUser);
    setState(() {
      username = data?['name'] ?? "User";
    });
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("Error getting user data: $e");
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    loadUserData();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _showFirstButton = true);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _showSecondButton = true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: Icon(icon, size: 20),
              label: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[50]!, Colors.blue[50]!, Colors.purple[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.indigo[400],
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => WelcomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.indigo[600]!,
                                Colors.purple[600]!,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Dashboard',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Card(
                            elevation: 12,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/SkillswapperLogo.png',
                                    height: 80,
                                    width: 80,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Welcome back,',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.indigo[600]!,
                                        Colors.purple[600]!,
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      username,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ready to swap some skills?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.indigo[50]!,
                                          Colors.purple[50]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.indigo[100]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.search_rounded,
                                              color: Colors.indigo[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Discover',
                                              style: TextStyle(
                                                color: Colors.indigo[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.indigo[200],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.swap_horiz_rounded,
                                              color: Colors.purple[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Exchange',
                                              style: TextStyle(
                                                color: Colors.purple[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.indigo[200],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.trending_up_rounded,
                                              color: Colors.green[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Grow',
                                              style: TextStyle(
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  if (_showFirstButton)
                                    _buildActionButton(
                                      text: 'Find Matches',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MatchScreen(
                                            name: widget.currentUser,
                                          ),
                                        ),
                                      ),
                                      backgroundColor: Colors.indigo,
                                      icon: Icons.search_rounded,
                                    ),
                                  const SizedBox(height: 20),
                                  if (_showSecondButton)
                                    _buildActionButton(
                                      text: 'View My Requests',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CombinedRequestsScreen(
                                                currentUser: widget.currentUser,
                                              ),
                                        ),
                                      ),
                                      backgroundColor: Colors.purple,
                                      icon: Icons.swap_horiz_rounded,
                                    ),
                                  if (_showSecondButton)
                                    const SizedBox(height: 20),

                                  if (_showSecondButton)
                                    _buildActionButton(
                                      text: 'AI Assistance',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AIAssistantScreen(
                                              currentUserId: widget.currentUser,
                                            ),
                                          ),
                                        );
                                      },
                                      backgroundColor: Colors.green,
                                      icon: Icons.smart_toy_outlined,
                                    ),

                                  const SizedBox(height: 24),
                                  Text(
                                    'Connect • Learn • Grow Together',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
