import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AIAssistantScreen extends StatefulWidget {
  final String currentUserId;
  const AIAssistantScreen({required this.currentUserId});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _loading = false;
  bool _profileLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User profile data
  List<String> userTeaches = [];
  List<String> userWants = [];
  String currentUsername = '';

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

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      
      if (currentUserDoc.exists) {
        setState(() {
          userTeaches = List<String>.from(currentUserDoc.data()?['teaches'] ?? []);
          userWants = List<String>.from(currentUserDoc.data()?['wants'] ?? []);
          currentUsername = currentUserDoc.data()?['name'] ?? '';
          _profileLoading = false;
        });
        
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _profileLoading = false;
      });
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _generatePersonalizedSystemPrompt() {
    String teachesSkills = userTeaches.isNotEmpty ? userTeaches.join(', ') : 'no specific skills listed';
    String wantsSkills = userWants.isNotEmpty ? userWants.join(', ') : 'no specific skills listed';
    String username = currentUsername.isNotEmpty ? currentUsername : 'User';
    
    return """You are an AI mentor for $username on SkillSwapper, a skill exchange platform. 
    
User Profile Context:
- Name: $username
- Skills they can teach: $teachesSkills
- Skills they want to learn: $wantsSkills

Provide helpful, encouraging advice about learning skills, improving profiles, and connecting with others. 
Use their profile information to give personalized recommendations. Keep responses concise but informative and actionable.""";
  }

  Future<void> fetchAIResponse(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _response = '';
    });

    final apiKey = dotenv.env['TOGETHER_API_KEY'];
    final url = Uri.parse('https://api.together.xyz/v1/chat/completions');

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "mistralai/Mistral-7B-Instruct-v0.2",
          "messages": [
            {"role": "system", "content": _generatePersonalizedSystemPrompt()},
            {"role": "user", "content": prompt},
          ],
          "max_tokens": 250,
          "temperature": 0.7,
          "top_p": 0.9,
        }),
      );

      final data = json.decode(res.body);
      setState(() {
        _response = data['choices'][0]['message']['content'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _response = "I'm having trouble connecting right now. Please try again in a moment!";
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generatePersonalizedPrompts() {
    List<Map<String, dynamic>> prompts = [];

    // Profile improvement prompt
    prompts.add({
      'text': 'Profile Tips',
      'icon': Icons.person_outline_rounded,
      'prompt': 'How can I improve my SkillSwapper profile to attract more connections and skill exchange opportunities?'
    });

    // Skills they want to learn
    if (userWants.isNotEmpty) {
      String skillsText = userWants.length > 2 ? userWants.take(2).join(' & ') : userWants.join(' & ');
      prompts.add({
        'text': 'Learn $skillsText',
        'icon': Icons.school_rounded,
        'prompt': 'What\'s the best learning path for ${userWants.join(', ')}? Give me a structured roadmap.'
      });
    }

    // Skills they can teach - help them become better teachers
    if (userTeaches.isNotEmpty) {
      String skillsText = userTeaches.length > 2 ? userTeaches.take(2).join(' & ') : userTeaches.join(' & ');
      prompts.add({
        'text': 'Teach $skillsText Better',
        'icon': Icons.lightbulb_outline_rounded,
        'prompt': 'How can I become a better mentor and teacher for ${userTeaches.join(', ')}? What teaching strategies work best?'
      });
    }

    // Connection strategies
    prompts.add({
      'text': 'Find Matches',
      'icon': Icons.connect_without_contact_rounded,
      'prompt': 'How can I find and connect with the right skill exchange partners on SkillSwapper?'
    });

    // Skill combination suggestions
    if (userTeaches.isNotEmpty && userWants.isNotEmpty) {
      prompts.add({
        'text': 'Skill Synergy',
        'icon': Icons.auto_awesome_rounded,
        'prompt': 'How can I combine my existing skills (${userTeaches.join(', ')}) with what I want to learn (${userWants.join(', ')}) for better opportunities?'
      });
    }

    // Default prompts if profile is empty
    if (prompts.length <= 2) {
      prompts.addAll([
        {
          'text': 'Learning Tips',
          'icon': Icons.tips_and_updates_rounded,
          'prompt': 'What are the most effective strategies for learning new skills quickly?'
        },
        {
          'text': 'Skill Roadmap',
          'icon': Icons.route_rounded,
          'prompt': 'How do I create an effective learning roadmap for acquiring new skills?'
        }
      ]);
    }

    return prompts.take(4).toList(); // Limit to 4 prompts to avoid overflow
  }

  Widget _buildQuickPromptChip({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo[100]!, Colors.purple[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.indigo[600]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseContainer() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[100]!, Colors.purple[100]!],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_response.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[100]!, Colors.purple[100]!],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 48,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.indigo[600]!, Colors.purple[600]!],
              ).createShader(bounds),
              child: Text(
                currentUsername.isNotEmpty ? 'Hi $currentUsername!' : 'AI Skill Mentor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentUsername.isNotEmpty 
                ? 'I\'ve reviewed your profile. Ask me anything about your learning journey!'
                : 'Ask me anything about skills, learning paths, or improving your profile!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (userTeaches.isNotEmpty || userWants.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userTeaches.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.indigo[600]),
                          const SizedBox(width: 8),
                          Text(
                            'You teach: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userTeaches.join(', '),
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                    if (userTeaches.isNotEmpty && userWants.isNotEmpty)
                      const SizedBox(height: 12),
                    if (userWants.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.indigo[600]),
                          const SizedBox(width: 8),
                          Text(
                            'You want to learn: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userWants.join(', '),
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Response',
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _response,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo[50]!,
                Colors.blue[50]!,
                Colors.purple[50]!,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo[50]!,
              Colors.blue[50]!,
              Colors.purple[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.indigo[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo[100]!, Colors.purple[100]!],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: Colors.indigo[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.indigo[600]!, Colors.purple[600]!],
                        ).createShader(bounds),
                        child: const Text(
                          'AI Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Quick Prompts
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _generatePersonalizedPrompts()
                                  .map((prompt) => Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildQuickPromptChip(
                                          text: prompt['text'],
                                          icon: prompt['icon'],
                                          onTap: () {
                                            _controller.text = prompt['prompt'];
                                            fetchAIResponse(_controller.text);
                                          },
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Input Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(fontSize: 16),
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Ask me anything about your skills, learning journey, or profile...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.indigo[400]!, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              onSubmitted: (value) => fetchAIResponse(value),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ask Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send_rounded, size: 20),
                              label: const Text(
                                'Ask AI Mentor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              onPressed: () => fetchAIResponse(_controller.text),
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
                          const SizedBox(height: 24),

                          // Response Area
                          Expanded(child: _buildResponseContainer()),
                        ],
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