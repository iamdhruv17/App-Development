import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FocusFlowApp());
}

// ════════════════════════════════════════════════════════════
// THEME & CONSTANTS
// ════════════════════════════════════════════════════════════

class AppColors {
  static const bg = Color(0xFF07070F);
  static const surface = Color(0xFF0F0F1E);
  static const card = Color(0xFF171728);
  static const cardBorder = Color(0xFF252540);
  static const neonCyan = Color(0xFF00F5FF);
  static const neonPurple = Color(0xFF9D4EDD);
  static const neonPink = Color(0xFFFF006E);
  static const neonGreen = Color(0xFF06D6A0);
  static const neonAmber = Color(0xFFFFB830);
  static const textPrimary = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF7878A0);
  static const focusGrad1 = Color(0xFF00F5FF);
  static const focusGrad2 = Color(0xFF9D4EDD);
  static const breakGrad1 = Color(0xFF06D6A0);
  static const breakGrad2 = Color(0xFF118AB2);
  static const longBreakGrad1 = Color(0xFFFF9F1C);
  static const longBreakGrad2 = Color(0xFFFF006E);

  static const List<Color> taskColors = [
    Color(0xFF00F5FF), Color(0xFF9D4EDD), Color(0xFF06D6A0),
    Color(0xFFFF006E), Color(0xFFFFB830), Color(0xFF3D8EF0),
    Color(0xFFFF6B6B), Color(0xFF48CAE4),
  ];
}

// ════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════

enum TimerMode { focus, shortBreak, longBreak }

extension TimerModeExt on TimerMode {
  String get label {
    switch (this) {
      case TimerMode.focus: return 'Focus';
      case TimerMode.shortBreak: return 'Short Break';
      case TimerMode.longBreak: return 'Long Break';
    }
  }

  // NOTE: seconds getter kept for backward compat but no longer used
  // by the timer itself — _durationFor() in state is used instead.
  int get seconds {
    switch (this) {
      case TimerMode.focus: return 25 * 60;
      case TimerMode.shortBreak: return 5 * 60;
      case TimerMode.longBreak: return 15 * 60;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case TimerMode.focus: return [AppColors.focusGrad1, AppColors.focusGrad2];
      case TimerMode.shortBreak: return [AppColors.breakGrad1, AppColors.breakGrad2];
      case TimerMode.longBreak: return [AppColors.longBreakGrad1, AppColors.longBreakGrad2];
    }
  }

  Color get accentColor {
    switch (this) {
      case TimerMode.focus: return AppColors.neonCyan;
      case TimerMode.shortBreak: return AppColors.neonGreen;
      case TimerMode.longBreak: return AppColors.neonPink;
    }
  }

  String get motivational {
    final quotes = {
      TimerMode.focus: [
        'Deep work in progress. You\'ve got this! 💪',
        'Every minute of focus is a brick in your success. 🧱',
        'Silence the noise. Build something great. 🚀',
        'Champions focus when others are distracted. 🏆',
      ],
      TimerMode.shortBreak: [
        'Recharge your mind. Breathe. ✨',
        'Rest is part of the process. 🌿',
        'A rested mind performs at its peak. 🧘',
        'Step back to leap forward. 🌊',
      ],
      TimerMode.longBreak: [
        'Great session! Enjoy your well-earned rest. 🌟',
        'You crushed it. Now truly unwind. 🎉',
        'Exceptional effort deserves exceptional rest. 🛸',
        'Fuel up — more greatness awaits. ⚡',
      ],
    };
    final list = quotes[this]!;
    return list[DateTime.now().second % list.length];
  }
}

class TaskModel {
  final String id;
  String title;
  String tag;
  int colorIndex;
  bool completed;
  int focusMinutes;
  int sessionCount;

  TaskModel({
    required this.id,
    required this.title,
    this.tag = '',
    this.colorIndex = 0,
    this.completed = false,
    this.focusMinutes = 0,
    this.sessionCount = 0,
  });

  Color get color => AppColors.taskColors[colorIndex % AppColors.taskColors.length];
}

// ════════════════════════════════════════════════════════════
// XP & LEVEL SYSTEM
// ════════════════════════════════════════════════════════════

class LevelSystem {
  static const int xpPerMinute = 10;
  static const int baseXpPerLevel = 200;

  static int xpForLevel(int level) => baseXpPerLevel + (level - 1) * 100;

  static int levelFromTotalXp(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return level;
  }

  static int xpInCurrentLevel(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return remaining;
  }

  static double progressToNextLevel(int totalXp) {
    int level = levelFromTotalXp(totalXp);
    int current = xpInCurrentLevel(totalXp);
    return (current / xpForLevel(level)).clamp(0.0, 1.0);
  }

  static String titleForLevel(int level) {
    if (level < 3) return 'Beginner';
    if (level < 5) return 'Focused Mind';
    if (level < 8) return 'Flow State';
    if (level < 12) return 'Deep Worker';
    if (level < 17) return 'Zen Master';
    if (level < 23) return 'Iron Focus';
    if (level < 30) return 'Deep Work Master';
    return 'Legendary 🏆';
  }

  static String emojiForLevel(int level) {
    if (level < 3) return '🌱';
    if (level < 5) return '⚡';
    if (level < 8) return '🔥';
    if (level < 12) return '💎';
    if (level < 17) return '🌟';
    if (level < 23) return '🚀';
    if (level < 30) return '👑';
    return '🏆';
  }

  static List<Color> colorsForLevel(int level) {
    if (level < 3) return [const Color(0xFF06D6A0), const Color(0xFF118AB2)];
    if (level < 5) return [const Color(0xFF00F5FF), const Color(0xFF9D4EDD)];
    if (level < 8) return [const Color(0xFFFF9F1C), const Color(0xFFFF006E)];
    if (level < 12) return [const Color(0xFF48CAE4), const Color(0xFF9D4EDD)];
    if (level < 17) return [const Color(0xFFFFD700), const Color(0xFFFF9F1C)];
    if (level < 23) return [const Color(0xFFFF006E), const Color(0xFF9D4EDD)];
    return [const Color(0xFFFFD700), const Color(0xFFFF006E)];
  }
}

// ════════════════════════════════════════════════════════════
// ACHIEVEMENT BADGES
// ════════════════════════════════════════════════════════════

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    this.unlocked = false,
  });
}

List<Achievement> buildAchievements() => [
  Achievement(id: 'first_focus', title: 'First Focus', description: 'Complete your first focus session', emoji: '🎯', color: AppColors.neonCyan),
  Achievement(id: 'streak_3', title: 'On a Roll', description: 'Achieve a 3-day streak', emoji: '🔥', color: Colors.orange),
  Achievement(id: 'streak_7', title: 'Week Warrior', description: 'Achieve a 7-day streak', emoji: '⚡', color: Colors.amber),
  Achievement(id: 'sessions_10', title: 'Dedicated', description: 'Complete 10 sessions total', emoji: '💪', color: AppColors.neonPurple),
  Achievement(id: 'sessions_50', title: 'Unstoppable', description: 'Complete 50 sessions total', emoji: '🚀', color: AppColors.neonPink),
  Achievement(id: 'focus_60', title: 'Hour Power', description: 'Focus for 60 minutes total', emoji: '⏱️', color: AppColors.neonGreen),
  Achievement(id: 'focus_300', title: 'Marathon Mind', description: 'Focus for 300 minutes total', emoji: '🏃', color: AppColors.neonCyan),
  Achievement(id: 'level_5', title: 'Rising Star', description: 'Reach Level 5', emoji: '🌟', color: AppColors.neonAmber),
  Achievement(id: 'level_10', title: 'Elite Focus', description: 'Reach Level 10', emoji: '👑', color: Colors.amber),
  Achievement(id: 'tasks_5', title: 'Planner', description: 'Create 5 tasks', emoji: '📋', color: AppColors.neonGreen),
];

// ════════════════════════════════════════════════════════════
// APP ROOT
// ════════════════════════════════════════════════════════════

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonCyan,
          secondary: AppColors.neonPurple,
        ),
      ),
      home: const LandingPage(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LANDING PAGE
// ════════════════════════════════════════════════════════════

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _contentCtrl, _btnCtrl, _orbitCtrl;
  late Animation<double> _fadeAnim, _scaleAnim, _btnGlow;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _contentCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _btnGlow = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _contentCtrl.forward(); });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _contentCtrl.dispose(); _btnCtrl.dispose(); _orbitCtrl.dispose();
    super.dispose();
  }

  void _go() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => const PomodoroHomePage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF090920), const Color(0xFF13041F), _bgCtrl.value)!,
                Color.lerp(const Color(0xFF050515), const Color(0xFF0B0820), _bgCtrl.value)!,
                Color.lerp(const Color(0xFF080818), const Color(0xFF050310), _bgCtrl.value)!,
              ],
            ),
          ),
          child: Stack(children: [
            CustomPaint(size: sz, painter: _GridPainter()),
            AnimatedBuilder(animation: _orbitCtrl, builder: (_, __) {
              final a1 = _orbitCtrl.value * 2 * pi;
              final a2 = a1 + pi;
              return Stack(children: [
                Positioned(left: sz.width * .5 + cos(a1) * sz.width * .38 - 70, top: sz.height * .4 + sin(a1) * sz.height * .17 - 70,
                    child: _GlowCircle(140, AppColors.neonCyan, .18)),
                Positioned(left: sz.width * .5 + cos(a2) * sz.width * .34 - 55, top: sz.height * .4 + sin(a2) * sz.height * .15 - 55,
                    child: _GlowCircle(110, AppColors.neonPurple, .22)),
              ]);
            }),
            Positioned(top: -90, right: -70, child: _GlowCircle(320, AppColors.neonPurple, .1)),
            Positioned(bottom: -70, left: -50, child: _GlowCircle(260, AppColors.neonCyan, .09)),
            SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim, child: ScaleTransition(scale: _scaleAnim,
              child: Column(children: [
                const Spacer(flex: 2),
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(.35), blurRadius: 30, spreadRadius: 5), BoxShadow(color: AppColors.neonPurple.withOpacity(.3), blurRadius: 50, spreadRadius: 10)],
                  ),
                  child: const Icon(Icons.timer_rounded, color: Colors.white, size: 54),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple, AppColors.neonPink]).createShader(b),
                  child: const Text('FocusFlow', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2, height: 1)),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.neonCyan.withOpacity(.25)), color: AppColors.neonCyan.withOpacity(.05)),
                  child: const Text('Stay Focused. Stay Productive.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1.2)),
                ),
                const Spacer(flex: 2),
                Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: const [
                  _FeaturePill(icon: Icons.track_changes, label: 'Focus Timer'),
                  _FeaturePill(icon: Icons.local_fire_department, label: 'Streaks'),
                  _FeaturePill(icon: Icons.star_rounded, label: 'XP & Levels'),
                  _FeaturePill(icon: Icons.task_alt, label: 'Tasks'),
                  _FeaturePill(icon: Icons.emoji_events, label: 'Achievements'),
                ]),
                const SizedBox(height: 44),
                AnimatedBuilder(animation: _btnGlow, builder: (_, child) => Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(.3 * _btnGlow.value), blurRadius: 28, spreadRadius: 2), BoxShadow(color: AppColors.neonPurple.withOpacity(.2 * _btnGlow.value), blurRadius: 48, spreadRadius: 5)]),
                  child: child!,
                ), child: GestureDetector(onTap: _go, child: Container(
                  width: 240, height: 60,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple])),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                  ]),
                ))),
                const Spacer(),
                Padding(padding: const EdgeInsets.only(bottom: 24),
                    child: Text('Powered by the Pomodoro Technique', style: TextStyle(color: AppColors.textSecondary.withOpacity(.4), fontSize: 11, letterSpacing: .8))),
              ]),
            )))),
          ]),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.card, border: Border.all(color: AppColors.neonPurple.withOpacity(.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.neonCyan, size: 13),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowCircle(this.size, this.color, this.opacity);
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])));
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.neonCyan.withOpacity(.035)..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 48) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 48) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════
// HOME PAGE
// ════════════════════════════════════════════════════════════

class PomodoroHomePage extends StatefulWidget {
  const PomodoroHomePage({super.key});
  @override
  State<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends State<PomodoroHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Timer
  TimerMode _mode = TimerMode.focus;
  int _secondsLeft = 25 * 60; // matches default _focusDuration
  bool _isRunning = false;
  Timer? _timer;

  // ── Custom Durations (in minutes) — Feature 1
  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  // ── Background tracking — Feature 3
  DateTime? _backgroundedAt;

  // ── Stats
  int _sessionsCompleted = 0;
  int _totalFocusMinutes = 0;
  int _streak = 0;
  DateTime? _lastSessionDate;

  // ── XP & Levels
  int _totalXp = 0;
  int _prevLevel = 1;
  bool _showLevelUp = false;
  String _levelUpTitle = '';

  // ── Tasks
  final List<TaskModel> _tasks = [];
  TaskModel? _activeTask;
  int _taskColorIndex = 0;
  bool _showTaskSelector = false;

  // ── Achievements
  late List<Achievement> _achievements;

  // ── UI
  int _tabIndex = 0;
  bool _completionFlash = false;

  // ── Animations
  late AnimationController _pulseCtrl, _glowCtrl, _levelUpCtrl, _xpBarCtrl, _tabCtrl;
  late Animation<double> _pulseAnim, _glowAnim, _levelUpScale, _levelUpFade, _xpBarAnim;

  // ── Helper: seconds for current custom duration — Feature 1
  int _durationFor(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus: return _focusDuration * 60;
      case TimerMode.shortBreak: return _shortBreakDuration * 60;
      case TimerMode.longBreak: return _longBreakDuration * 60;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Feature 3
    _achievements = buildAchievements();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _xpBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _tabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.035).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: .5, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _levelUpScale = Tween<double>(begin: .4, end: 1.0).animate(CurvedAnimation(parent: _levelUpCtrl, curve: Curves.elasticOut));
    _levelUpFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeOut));
    _xpBarAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _xpBarCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Feature 3
    _timer?.cancel();
    _pulseCtrl.dispose(); _glowCtrl.dispose(); _levelUpCtrl.dispose();
    _xpBarCtrl.dispose(); _tabCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // FEATURE 3 — App Lifecycle / Background Execution
  // ════════════════════════════════════════════════════════

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App going to background — record timestamp if timer is running
      if (_isRunning) {
        _backgroundedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming back — calculate elapsed time and adjust timer
      if (_isRunning && _backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
        _backgroundedAt = null;

        final newSecondsLeft = _secondsLeft - elapsed;
        if (newSecondsLeft <= 0) {
          // Timer expired while in background
          setState(() => _secondsLeft = 0);
          _onTimerComplete();
        } else {
          setState(() => _secondsLeft = newSecondsLeft);
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // Timer logic
  // ════════════════════════════════════════════════════════

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() { _timer?.cancel(); setState(() => _isRunning = false); }

  // Feature 1 — uses _durationFor instead of _mode.seconds
  void _resetTimer() {
    _timer?.cancel();
    setState(() { _isRunning = false; _secondsLeft = _durationFor(_mode); });
  }

  // Feature 1 — uses _durationFor instead of m.seconds
  void _switchMode(TimerMode m) {
    if (_isRunning) _pauseTimer();
    _tabCtrl.forward(from: 0);
    setState(() { _mode = m; _secondsLeft = _durationFor(m); });
  }

  // ════════════════════════════════════════════════════════
  // FEATURE 2 — Auto Session Switching
  // ════════════════════════════════════════════════════════

  void _onTimerComplete() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() { _isRunning = false; _completionFlash = true; });

    if (_mode == TimerMode.focus) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Feature 1 — use dynamic focus duration for XP & stats
      final int sessionMinutes = _focusDuration;
      final int xpGained = sessionMinutes * LevelSystem.xpPerMinute;
      final oldLevel = LevelSystem.levelFromTotalXp(_totalXp);

      setState(() {
        _sessionsCompleted++;
        _totalFocusMinutes += sessionMinutes;
        _totalXp += xpGained;

        if (_activeTask != null) {
          _activeTask!.focusMinutes += sessionMinutes;
          _activeTask!.sessionCount++;
        }

        // Streak
        if (_lastSessionDate == null) {
          _streak = 1;
        } else {
          final lastDay = DateTime(_lastSessionDate!.year, _lastSessionDate!.month, _lastSessionDate!.day);
          final diff = today.difference(lastDay).inDays;
          if (diff == 0) { /* same day */ }
          else if (diff == 1) { _streak++; }
          else { _streak = 1; }
        }
        _lastSessionDate = now;
      });

      final newLevel = LevelSystem.levelFromTotalXp(_totalXp);
      if (newLevel > oldLevel) {
        _triggerLevelUp(newLevel);
      } else {
        _xpBarCtrl.forward(from: 0);
      }
      _checkAchievements();
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() { _completionFlash = false; _secondsLeft = _durationFor(_mode); });
    });

    // Determine the NEXT mode automatically
    final TimerMode nextMode;
    if (_mode == TimerMode.focus) {
      // Every 4 focus sessions → long break, otherwise short break
      nextMode = (_sessionsCompleted % 4 == 0)
          ? TimerMode.longBreak
          : TimerMode.shortBreak;
    } else {
      nextMode = TimerMode.focus;
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(.75),
        builder: (_) => _CompletionDialog(
          mode: _mode,
          nextMode: nextMode,
          xpGained: _mode == TimerMode.focus ? _focusDuration * LevelSystem.xpPerMinute : 0,
          onDismiss: () {
            Navigator.pop(context);
            // Auto-switch to next mode, then auto-start after a 1s pause
            _switchMode(nextMode);
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _startTimer();
            });
          },
        ),
      );
    });
  }

  void _triggerLevelUp(int newLevel) {
    setState(() {
      _showLevelUp = true;
      _levelUpTitle = LevelSystem.titleForLevel(newLevel);
    });
    _levelUpCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showLevelUp = false);
    });
  }

  void _checkAchievements() {
    bool anyNew = false;
    final lvl = LevelSystem.levelFromTotalXp(_totalXp);

    void tryUnlock(String id, bool condition) {
      if (!condition) return;
      final a = _achievements.firstWhere((e) => e.id == id);
      if (!a.unlocked) { a.unlocked = true; anyNew = true; }
    }

    tryUnlock('first_focus', _sessionsCompleted >= 1);
    tryUnlock('streak_3', _streak >= 3);
    tryUnlock('streak_7', _streak >= 7);
    tryUnlock('sessions_10', _sessionsCompleted >= 10);
    tryUnlock('sessions_50', _sessionsCompleted >= 50);
    tryUnlock('focus_60', _totalFocusMinutes >= 60);
    tryUnlock('focus_300', _totalFocusMinutes >= 300);
    tryUnlock('level_5', lvl >= 5);
    tryUnlock('level_10', lvl >= 10);
    tryUnlock('tasks_5', _tasks.length >= 5);

    if (anyNew) setState(() {});
  }

  // ── Task actions
  void _addTask(String title, String tag, int colorIdx) {
    setState(() {
      _tasks.add(TaskModel(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, tag: tag, colorIndex: colorIdx));
      _taskColorIndex = (colorIdx + 1) % AppColors.taskColors.length;
    });
    _checkAchievements();
  }

  void _deleteTask(String id) {
    setState(() {
      if (_activeTask?.id == id) _activeTask = null;
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  void _toggleTask(String id) {
    setState(() {
      final t = _tasks.firstWhere((e) => e.id == id);
      t.completed = !t.completed;
    });
  }

  // ════════════════════════════════════════════════════════
  // FEATURE 4 — Task Reordering
  // ════════════════════════════════════════════════════════

  void _reorderTasks(int oldIndex, int newIndex, List<TaskModel> activeTasks) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = activeTasks.removeAt(oldIndex);
      activeTasks.insert(newIndex, item);

      // Rebuild _tasks: active (reordered) + completed (preserved at end)
      final completed = _tasks.where((t) => t.completed).toList();
      _tasks
        ..clear()
        ..addAll(activeTasks)
        ..addAll(completed);
    });
  }

  // ── Helpers
  String get _formattedTime {
    final m = _secondsLeft ~/ 60, s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Feature 1 — uses _durationFor instead of _mode.seconds
  double get _progress => 1 - (_secondsLeft / _durationFor(_mode));

  int get _currentLevel => LevelSystem.levelFromTotalXp(_totalXp);
  double get _xpProgress => LevelSystem.progressToNextLevel(_totalXp);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        AnimatedBuilder(animation: _glowCtrl, builder: (_, __) => Positioned(
          top: -120, left: -60, right: -60,
          child: Container(height: 380, decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.1, colors: [_mode.accentColor.withOpacity(.07 * _glowAnim.value), Colors.transparent]))),
        )),
        SafeArea(child: Column(children: [
          _buildHeader(),
          _buildXpBar(),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildCurrentTab(),
          )),
          _buildBottomNav(),
        ])),
        if (_showLevelUp) _buildLevelUpOverlay(),
      ]),
    );
  }

  Widget _buildHeader() {
    final lvl = _currentLevel;
    final levelColors = LevelSystem.colorsForLevel(lvl);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: _mode.gradientColors), boxShadow: [BoxShadow(color: _mode.accentColor.withOpacity(.4), blurRadius: 12)]),
            child: const Icon(Icons.timer_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        ShaderMask(shaderCallback: (b) => LinearGradient(colors: _mode.gradientColors).createShader(b),
            child: const Text('FocusFlow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .8))),
        const Spacer(),
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.card, border: Border.all(color: levelColors[0].withOpacity(.4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(LevelSystem.emojiForLevel(lvl), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Lv.$lvl', style: TextStyle(color: levelColors[0], fontWeight: FontWeight.w800, fontSize: 12, height: 1.1)),
              Text(LevelSystem.titleForLevel(lvl), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, height: 1.1)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        // Streak badge
        AnimatedContainer(duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.card, border: Border.all(color: _streak > 0 ? Colors.orange.withOpacity(.5) : AppColors.cardBorder),
              boxShadow: _streak > 0 ? [BoxShadow(color: Colors.orange.withOpacity(.2), blurRadius: 10)] : []),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🔥', style: TextStyle(fontSize: _streak > 0 ? 14 : 12)),
            const SizedBox(width: 4),
            Text('$_streak', style: TextStyle(color: _streak > 0 ? Colors.orange : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        const SizedBox(width: 8),
        // ── FEATURE 1: Settings icon
        GestureDetector(
          onTap: () => Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (_, __, ___) => SettingsScreen(
              focusDuration: _focusDuration,
              shortBreakDuration: _shortBreakDuration,
              longBreakDuration: _longBreakDuration,
              onSave: (f, s, l) {
                setState(() {
                  _focusDuration = f;
                  _shortBreakDuration = s;
                  _longBreakDuration = l;
                  // Only reset timer display if timer is not actively running
                  if (!_isRunning) _secondsLeft = _durationFor(_mode);
                });
              },
            ),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _buildXpBar() {
    final lvl = _currentLevel;
    final xpCurrent = LevelSystem.xpInCurrentLevel(_totalXp);
    final xpNeeded = LevelSystem.xpForLevel(lvl);
    final levelColors = LevelSystem.colorsForLevel(lvl);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('XP: $xpCurrent / $xpNeeded', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Total XP: $_totalXp', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ]),
        const SizedBox(height: 5),
        Stack(children: [
          Container(height: 5, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: AppColors.card)),
          TweenAnimationBuilder<double>(
            key: ValueKey(_totalXp),
            tween: Tween(begin: 0, end: _xpProgress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => FractionallySizedBox(widthFactor: v, child: Container(height: 5,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: LinearGradient(colors: levelColors),
                    boxShadow: [BoxShadow(color: levelColors[0].withOpacity(.5), blurRadius: 6)]))),
          ),
        ]),
      ]),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0: return _TimerTab(key: const ValueKey(0), state: this);
      case 1: return _TasksTab(key: const ValueKey(1), state: this);
      case 2: return _StatsTab(key: const ValueKey(2), state: this);
      case 3: return _AchievementsTab(key: const ValueKey(3), state: this);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.timer_rounded, 'Timer'),
      (Icons.task_alt, 'Tasks'),
      (Icons.bar_chart_rounded, 'Stats'),
      (Icons.emoji_events_rounded, 'Badges'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: AppColors.card, border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Row(children: List.generate(items.length, (i) {
        final sel = _tabIndex == i;
        return Expanded(child: GestureDetector(onTap: () => setState(() => _tabIndex = i),
          child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), color: sel ? _mode.accentColor.withOpacity(.15) : Colors.transparent),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(items[i].$1, color: sel ? _mode.accentColor : AppColors.textSecondary, size: 22),
              const SizedBox(height: 3),
              Text(items[i].$2, style: TextStyle(color: sel ? _mode.accentColor : AppColors.textSecondary, fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            ]),
          )));
      })),
    );
  }

  Widget _buildLevelUpOverlay() {
    final lvl = _currentLevel;
    final levelColors = LevelSystem.colorsForLevel(lvl);
    return Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _levelUpCtrl, builder: (_, __) => Opacity(opacity: _levelUpFade.value, child: Container(
      color: Colors.black.withOpacity(.55),
      child: Center(child: ScaleTransition(scale: _levelUpScale, child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: AppColors.surface, border: Border.all(color: levelColors[0].withOpacity(.5), width: 1.5),
            boxShadow: [BoxShadow(color: levelColors[0].withOpacity(.25), blurRadius: 40, spreadRadius: 5)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(LevelSystem.emojiForLevel(lvl), style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 12),
          ShaderMask(shaderCallback: (b) => LinearGradient(colors: levelColors).createShader(b),
              child: Text('LEVEL UP!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3))),
          const SizedBox(height: 8),
          Text('You reached Level $lvl', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: levelColors)),
              child: Text(_levelUpTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
      ))),
    )))));
  }
}

// ════════════════════════════════════════════════════════════
// TIMER TAB
// ════════════════════════════════════════════════════════════

class _TimerTab extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _TimerTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: [
        const SizedBox(height: 10),
        _ModeSelector(state: s),
        const SizedBox(height: 20),
        if (s._activeTask != null)
          _ActiveTaskChip(task: s._activeTask!, onClear: () => s.setState(() => s._activeTask = null)),
        if (s._activeTask == null)
          _SelectTaskButton(onTap: () => s.setState(() => s._showTaskSelector = !s._showTaskSelector)),
        AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          child: s._showTaskSelector && s._tasks.isNotEmpty
              ? _TaskSelectorPanel(tasks: s._tasks, onSelect: (t) => s.setState(() { s._activeTask = t; s._showTaskSelector = false; }))
              : const SizedBox.shrink()),
        const SizedBox(height: 20),
        _CircularTimer(state: s),
        const SizedBox(height: 24),
        AnimatedSwitcher(duration: const Duration(milliseconds: 400),
          child: Container(key: ValueKey(s._mode), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.card, border: Border.all(color: s._mode.accentColor.withOpacity(.2))),
            child: Row(children: [
              Icon(Icons.lightbulb_outline, color: s._mode.accentColor, size: 17),
              const SizedBox(width: 10),
              Expanded(child: Text(s._mode.motivational, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5))),
            ])),
        ),
        const SizedBox(height: 24),
        _Controls(state: s),
        const SizedBox(height: 22),
        _QuickStatsRow(state: s),
        const SizedBox(height: 18),
      ]),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _ModeSelector({required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.card, border: Border.all(color: AppColors.cardBorder)),
    child: Row(children: TimerMode.values.map((m) {
      final sel = state._mode == m;
      return Expanded(child: GestureDetector(onTap: () => state._switchMode(m), child: AnimatedContainer(
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: sel ? LinearGradient(colors: m.gradientColors) : null,
            boxShadow: sel ? [BoxShadow(color: m.accentColor.withOpacity(.3), blurRadius: 10)] : []),
        child: Text(m.label, textAlign: TextAlign.center,
            style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, fontSize: 12)),
      )));
    }).toList()),
  );
}

class _ActiveTaskChip extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onClear;
  const _ActiveTaskChip({required this.task, required this.onClear});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.card, border: Border.all(color: task.color.withOpacity(.4))),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: task.color)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Working on', style: TextStyle(color: AppColors.textSecondary.withOpacity(.7), fontSize: 9, letterSpacing: .8)),
        Text(task.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        if (task.tag.isNotEmpty) Text(task.tag, style: TextStyle(color: task.color, fontSize: 10)),
      ])),
      GestureDetector(onTap: onClear, child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18)),
    ]),
  );
}

class _SelectTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SelectTaskButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.card, border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.add_task, color: AppColors.textSecondary, size: 16),
      SizedBox(width: 8),
      Text('Link a Task (optional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]),
  ));
}

class _TaskSelectorPanel extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onSelect;
  const _TaskSelectorPanel({required this.tasks, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final active = tasks.where((t) => !t.completed).toList();
    if (active.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No active tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center));
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.surface, border: Border.all(color: AppColors.cardBorder)),
      child: Column(children: active.map((t) => GestureDetector(onTap: () => onSelect(t), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(.5), width: .5))),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: t.color)),
          const SizedBox(width: 10),
          Expanded(child: Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
          if (t.tag.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: t.color.withOpacity(.15)),
              child: Text(t.tag, style: TextStyle(color: t.color, fontSize: 10))),
        ]),
      ))).toList()),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _CircularTimer({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    return AnimatedBuilder(animation: s._pulseCtrl, builder: (_, __) => Transform.scale(
      scale: s._isRunning ? s._pulseAnim.value : 1.0,
      child: SizedBox(width: 250, height: 250, child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(animation: s._glowCtrl, builder: (_, __) => Container(width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: s._mode.accentColor.withOpacity(.13 * s._glowAnim.value), blurRadius: 38, spreadRadius: 10)]))),
        CustomPaint(size: const Size(250, 250), painter: _RingPainter(progress: 1.0, color: AppColors.card, strokeWidth: 13)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: s._progress),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (_, v, __) => CustomPaint(size: const Size(250, 250), painter: _RingPainter(progress: v, colors: s._mode.gradientColors, strokeWidth: 13, glowColor: s._mode.accentColor)),
        ),
        Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.card, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: s._mode.accentColor.withOpacity(.15), border: Border.all(color: s._mode.accentColor.withOpacity(.3))),
                child: Text(s._mode.label.toUpperCase(), style: TextStyle(color: s._mode.accentColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
            const SizedBox(height: 10),
            Text(s._formattedTime, style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: s._completionFlash ? s._mode.accentColor : AppColors.textPrimary, letterSpacing: 2, fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 5),
            Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(duration: const Duration(milliseconds: 300), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: s._isRunning ? s._mode.accentColor : AppColors.textSecondary.withOpacity(.3),
                  boxShadow: s._isRunning ? [BoxShadow(color: s._mode.accentColor.withOpacity(.7), blurRadius: 7)] : [])),
              const SizedBox(width: 5),
              Text(s._isRunning ? 'RUNNING' : 'PAUSED', style: TextStyle(color: s._isRunning ? s._mode.accentColor : AppColors.textSecondary.withOpacity(.35), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ]),
          ]),
        ),
      ])),
    ));
  }
}

class _Controls extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _Controls({required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _ControlBtn(icon: Icons.replay_rounded, label: 'Reset', onTap: s._resetTimer, color: AppColors.textSecondary, size: 50),
      const SizedBox(width: 22),
      AnimatedBuilder(animation: s._glowCtrl, builder: (_, __) => GestureDetector(onTap: s._isRunning ? s._pauseTimer : s._startTimer,
        child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 70, height: 70,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: s._mode.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: s._mode.accentColor.withOpacity(.4 * s._glowAnim.value), blurRadius: 20, spreadRadius: 3)]),
          child: Icon(s._isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36)))),
      const SizedBox(width: 22),
      _ControlBtn(icon: Icons.skip_next_rounded, label: 'Skip', color: AppColors.textSecondary, size: 50,
        onTap: () { final modes = TimerMode.values; s._switchMode(modes[(s._mode.index + 1) % modes.length]); }),
    ]);
  }
}

class _QuickStatsRow extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _QuickStatsRow({required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return Row(children: [
      _MiniStat(icon: Icons.check_circle_outline, label: 'Sessions', value: '${s._sessionsCompleted}', color: AppColors.neonCyan),
      const SizedBox(width: 10),
      _MiniStat(icon: Icons.access_time_rounded, label: 'Minutes', value: '${s._totalFocusMinutes}', color: AppColors.neonPurple),
      const SizedBox(width: 10),
      _MiniStat(icon: Icons.star_rounded, label: 'XP', value: '${s._totalXp}', color: AppColors.neonAmber),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.card, border: Border.all(color: color.withOpacity(.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
    ]),
  ));
}

// ════════════════════════════════════════════════════════════
// TASKS TAB
// ════════════════════════════════════════════════════════════

class _TasksTab extends StatefulWidget {
  final _PomodoroHomePageState state;
  const _TasksTab({super.key, required this.state});
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final _titleCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  bool _showForm = false;
  int _selectedColor = 0;
  bool _showCompleted = false;

  @override
  void dispose() { _titleCtrl.dispose(); _tagCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.state._addTask(_titleCtrl.text.trim(), _tagCtrl.text.trim(), _selectedColor);
    setState(() {
      _titleCtrl.clear(); _tagCtrl.clear();
      _selectedColor = widget.state._taskColorIndex;
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.state._tasks;
    final active = tasks.where((t) => !t.completed).toList();
    final done = tasks.where((t) => t.completed).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 8), child: Row(children: [
        const Text('Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.neonCyan.withOpacity(.15)),
            child: Text('${active.length}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 12))),
        const Spacer(),
        GestureDetector(onTap: () => setState(() => _showForm = !_showForm), child: AnimatedContainer(duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: _showForm ? AppColors.neonCyan.withOpacity(.2) : AppColors.card, border: Border.all(color: AppColors.neonCyan.withOpacity(.3))),
          child: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded, color: AppColors.neonCyan, size: 20))),
      ])),
      AnimatedSize(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut,
          child: _showForm ? _buildAddForm() : const SizedBox.shrink()),
      Expanded(child: tasks.isEmpty ? _buildEmptyState() : ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 10), children: [
        // ── FEATURE 4: ReorderableListView for active tasks
        if (active.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('IN PROGRESS', style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            )),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: active.length,
            onReorder: (oldIndex, newIndex) =>
                widget.state._reorderTasks(oldIndex, newIndex, List<TaskModel>.from(active)),
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              elevation: 0,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.03).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
            itemBuilder: (context, index) {
              final t = active[index];
              return KeyedSubtree(
                key: ValueKey(t.id),
                child: Stack(children: [
                  _TaskCard(
                    task: t,
                    state: widget.state,
                    onDelete: () => setState(() => widget.state._deleteTask(t.id)),
                    onToggle: () => setState(() => widget.state._toggleTask(t.id)),
                  ),
                  // Drag handle — positioned to avoid overlap with delete/focus buttons
                  Positioned(
                    right: 42,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (done.isNotEmpty) ...[
          GestureDetector(onTap: () => setState(() => _showCompleted = !_showCompleted),
            child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
              Text('COMPLETED (${done.length})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(width: 6),
              Icon(_showCompleted ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
            ]))),
          if (_showCompleted) ...done.map((t) => _TaskCard(task: t, state: widget.state, onDelete: () => setState(() => widget.state._deleteTask(t.id)), onToggle: () => setState(() => widget.state._toggleTask(t.id)))),
        ],
      ])),
    ]);
  }

  Widget _buildAddForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.card, border: Border.all(color: AppColors.neonCyan.withOpacity(.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('New Task', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        _GlassInput(controller: _titleCtrl, hint: 'Task title...', onSubmitted: (_) => FocusScope.of(context).nextFocus()),
        const SizedBox(height: 10),
        _GlassInput(controller: _tagCtrl, hint: 'Category / Tag (optional)'),
        const SizedBox(height: 12),
        const Text('Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 8),
        SizedBox(height: 28, child: ListView.separated(scrollDirection: Axis.horizontal,
          itemCount: AppColors.taskColors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final sel = _selectedColor == i;
            return GestureDetector(onTap: () => setState(() => _selectedColor = i), child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              width: sel ? 32 : 26, height: sel ? 32 : 26,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.taskColors[i], border: sel ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: sel ? [BoxShadow(color: AppColors.taskColors[i].withOpacity(.5), blurRadius: 8)] : [])));
          })),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _showForm = false), child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surface),
            child: const Text('Cancel', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: GestureDetector(onTap: _submit, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple])),
            child: const Text('Add Task', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card, border: Border.all(color: AppColors.cardBorder)),
        child: const Icon(Icons.task_alt, color: AppColors.textSecondary, size: 34)),
    const SizedBox(height: 16),
    const Text('No tasks yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    const Text('Add your first task to track\nyour focus sessions', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
    const SizedBox(height: 20),
    GestureDetector(onTap: () => setState(() => _showForm = true), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple])),
      child: const Text('Create Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
  ]));
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  const _GlassInput({required this.controller, required this.hint, this.onSubmitted});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, onSubmitted: onSubmitted,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true, fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5))),
  );
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final _PomodoroHomePageState state;
  final VoidCallback onDelete, onToggle;
  const _TaskCard({required this.task, required this.state, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isActive = state._activeTask?.id == task.id;
    return Container(margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.card, border: Border.all(color: isActive ? task.color.withOpacity(.5) : AppColors.cardBorder.withOpacity(.5)),
          boxShadow: isActive ? [BoxShadow(color: task.color.withOpacity(.12), blurRadius: 12)] : []),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          GestureDetector(onTap: onToggle, child: AnimatedContainer(duration: const Duration(milliseconds: 250), width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: task.completed ? task.color : Colors.transparent, border: Border.all(color: task.color, width: 1.5)),
            child: task.completed ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: TextStyle(color: task.completed ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, decoration: task.completed ? TextDecoration.lineThrough : null)),
            if (task.tag.isNotEmpty) const SizedBox(height: 2),
            if (task.tag.isNotEmpty) Text(task.tag, style: TextStyle(color: task.color, fontSize: 10)),
          ])),
          if (!task.completed) GestureDetector(onTap: () => state.setState(() { state._activeTask = task; state._showTaskSelector = false; }),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isActive ? task.color.withOpacity(.2) : AppColors.surface, border: Border.all(color: task.color.withOpacity(.3))),
              child: Text(isActive ? 'Active' : 'Focus', style: TextStyle(color: task.color, fontSize: 10, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 8),
          GestureDetector(onTap: onDelete, child: Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary.withOpacity(.5), size: 17)),
        ])),
        if (task.sessionCount > 0) Container(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 12),
            const SizedBox(width: 5),
            Text('${task.sessionCount} session${task.sessionCount != 1 ? 's' : ''} · ${task.focusMinutes}m focused', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ])),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STATS TAB
// ════════════════════════════════════════════════════════════

class _StatsTab extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _StatsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final lvl = s._currentLevel;
    final levelColors = LevelSystem.colorsForLevel(lvl);
    final xpCurr = LevelSystem.xpInCurrentLevel(s._totalXp);
    final xpNeed = LevelSystem.xpForLevel(lvl);
    final focusHours = s._totalFocusMinutes ~/ 60;
    final focusMins = s._totalFocusMinutes % 60;
    final taskTarget = 8;
    final taskProgress = (s._sessionsCompleted / taskTarget).clamp(0.0, 1.0);
    final tasksWithTime = s._tasks.where((t) => t.focusMinutes > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Track your productivity journey', style: TextStyle(color: AppColors.textSecondary.withOpacity(.7), fontSize: 12)),
        const SizedBox(height: 18),

        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [levelColors[0].withOpacity(.15), levelColors[1].withOpacity(.08)]),
              border: Border.all(color: levelColors[0].withOpacity(.35))),
          child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: levelColors)),
                child: Center(child: Text(LevelSystem.emojiForLevel(lvl), style: const TextStyle(fontSize: 26)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Level $lvl · ${LevelSystem.titleForLevel(lvl)}', style: TextStyle(color: levelColors[0], fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 6),
              Stack(children: [
                Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: AppColors.surface)),
                TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: xpCurr / xpNeed), duration: const Duration(milliseconds: 900), curve: Curves.easeOut,
                  builder: (_, v, __) => FractionallySizedBox(widthFactor: v, child: Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: LinearGradient(colors: levelColors),
                      boxShadow: [BoxShadow(color: levelColors[0].withOpacity(.5), blurRadius: 6)])))),
              ]),
              const SizedBox(height: 4),
              Text('$xpCurr / $xpNeed XP to Level ${lvl + 1}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ])),
          ]),
        ),
        const SizedBox(height: 14),

        Row(children: [
          _BigStatCard(title: 'Sessions', value: '${s._sessionsCompleted}', icon: Icons.check_circle_rounded, color: AppColors.neonCyan, sub: 'completed', progress: taskProgress),
          const SizedBox(width: 12),
          _BigStatCard(title: 'Focus Time', value: focusHours > 0 ? '${focusHours}h ${focusMins}m' : '${s._totalFocusMinutes}m', icon: Icons.access_time_rounded, color: AppColors.neonPurple, sub: 'total', progress: (s._totalFocusMinutes / 300).clamp(0, 1)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _BigStatCard(title: 'Total XP', value: '${s._totalXp}', icon: Icons.star_rounded, color: AppColors.neonAmber, sub: 'earned', progress: (s._totalXp / 2000).clamp(0, 1)),
          const SizedBox(width: 12),
          _BigStatCard(title: 'Streak', value: '${s._streak}🔥', icon: Icons.local_fire_department, color: Colors.orange, sub: 'days', progress: (s._streak / 30).clamp(0, 1)),
        ]),
        const SizedBox(height: 18),

        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.card, border: Border.all(color: AppColors.neonCyan.withOpacity(.18))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Daily Session Goal', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text('${s._sessionsCompleted} / $taskTarget', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Stack(children: [
              Container(height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppColors.surface)),
              TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: taskProgress), duration: const Duration(milliseconds: 900), curve: Curves.easeOut,
                builder: (_, v, __) => FractionallySizedBox(widthFactor: v, child: Container(height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(.4), blurRadius: 8)])))),
            ]),
            const SizedBox(height: 12),
            Row(children: List.generate(taskTarget, (i) {
              final done = i < s._sessionsCompleted;
              return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 30,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: done ? AppColors.neonCyan.withOpacity(.2) : AppColors.surface, border: Border.all(color: done ? AppColors.neonCyan.withOpacity(.5) : AppColors.cardBorder)),
                child: Icon(done ? Icons.check_rounded : Icons.circle_outlined, size: 12, color: done ? AppColors.neonCyan : AppColors.textSecondary.withOpacity(.2))));
            })),
          ])),
        const SizedBox(height: 18),

        if (tasksWithTime.isNotEmpty) ...[
          const Text('Time by Task', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.card, border: Border.all(color: AppColors.cardBorder)),
            child: Column(children: [
              SizedBox(height: 180, child: Row(children: [
                SizedBox(width: 180, height: 180, child: CustomPaint(painter: _PieChartPainter(tasks: tasksWithTime))),
                const SizedBox(width: 16),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ...tasksWithTime.map((t) {
                    final pct = (t.focusMinutes / s._totalFocusMinutes * 100).toStringAsFixed(0);
                    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: t.color)),
                      const SizedBox(width: 7),
                      Expanded(child: Text(t.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis)),
                      Text('$pct%', style: TextStyle(color: t.color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]));
                  }),
                ])),
              ])),
            ])),
          const SizedBox(height: 18),
        ],

        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [AppColors.neonPurple.withOpacity(.12), AppColors.neonCyan.withOpacity(.05)]), border: Border.all(color: AppColors.neonPurple.withOpacity(.2))),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pro Tip', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 4),
              Text('After 4 focus sessions, take a long break. This maximizes deep work cycles.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.45)),
            ])),
          ])),
      ]),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  final double progress;
  const _BigStatCard({required this.title, required this.value, required this.icon, required this.color, required this.sub, required this.progress});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.card, border: Border.all(color: color.withOpacity(.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(.15)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(sub, style: TextStyle(color: AppColors.textSecondary.withOpacity(.6), fontSize: 10)),
      const SizedBox(height: 10),
      Stack(children: [
        Container(height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: AppColors.surface)),
        TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: const Duration(milliseconds: 900), curve: Curves.easeOut,
          builder: (_, v, __) => FractionallySizedBox(widthFactor: v, child: Container(height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color, boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 4)])))),
      ]),
    ]),
  ));
}

class _PieChartPainter extends CustomPainter {
  final List<TaskModel> tasks;
  const _PieChartPainter({required this.tasks});

  @override
  void paint(Canvas canvas, Size size) {
    final total = tasks.fold(0, (sum, t) => sum + t.focusMinutes).toDouble();
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    double startAngle = -pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    const gap = 0.03;

    for (final task in tasks) {
      final sweep = (task.focusMinutes / total) * 2 * pi - gap;
      paint.color = task.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle + gap / 2, sweep, true, paint);
      startAngle += sweep + gap;
    }

    final holePaint = Paint()..color = AppColors.card..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);

    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: '${tasks.length}\n', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
        const TextSpan(text: 'tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => true;
}

// ════════════════════════════════════════════════════════════
// ACHIEVEMENTS TAB
// ════════════════════════════════════════════════════════════

class _AchievementsTab extends StatelessWidget {
  final _PomodoroHomePageState state;
  const _AchievementsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final all = state._achievements;
    final unlocked = all.where((a) => a.unlocked).length;
    final lvl = state._currentLevel;
    final levelColors = LevelSystem.colorsForLevel(lvl);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Achievements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.neonAmber.withOpacity(.15), border: Border.all(color: AppColors.neonAmber.withOpacity(.3))),
            child: Text('$unlocked / ${all.length}', style: const TextStyle(color: AppColors.neonAmber, fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
        const SizedBox(height: 4),
        Text('Earn badges by hitting milestones', style: TextStyle(color: AppColors.textSecondary.withOpacity(.7), fontSize: 12)),
        const SizedBox(height: 14),

        Container(width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [levelColors[0].withOpacity(.18), levelColors[1].withOpacity(.1)]),
              border: Border.all(color: levelColors[0].withOpacity(.4), width: 1.5)),
          child: Column(children: [
            Text(LevelSystem.emojiForLevel(lvl), style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            ShaderMask(shaderCallback: (b) => LinearGradient(colors: levelColors).createShader(b),
                child: Text(LevelSystem.titleForLevel(lvl), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
            const SizedBox(height: 6),
            Text('Level $lvl · ${state._totalXp} XP Total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surface.withOpacity(.6), border: Border.all(color: levelColors[0].withOpacity(.25))),
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.share_rounded, color: levelColors[0], size: 14),
                const SizedBox(width: 6),
                Text('Share on LinkedIn', style: TextStyle(color: levelColors[0], fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
          ])),
        const SizedBox(height: 20),

        const Text('BADGES', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.55, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: all.length,
          itemBuilder: (_, i) => _AchievementCard(achievement: all[i]),
        ),
        const SizedBox(height: 18),

        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.card, border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            const Text('🔒', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Next title at Level ${lvl + 1}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 3),
              Text(LevelSystem.titleForLevel(lvl + 1), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ])),
            Text('${LevelSystem.xpForLevel(lvl) - LevelSystem.xpInCurrentLevel(state._totalXp)} XP away', style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w700)),
          ])),
      ]),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.unlocked;
    return AnimatedContainer(duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.card,
        border: Border.all(color: locked ? AppColors.cardBorder : achievement.color.withOpacity(.45), width: locked ? 1 : 1.5),
        boxShadow: locked ? [] : [BoxShadow(color: achievement.color.withOpacity(.15), blurRadius: 12)],
        gradient: locked ? null : LinearGradient(colors: [achievement.color.withOpacity(.1), achievement.color.withOpacity(.04)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(locked ? '🔒' : achievement.emoji, style: TextStyle(fontSize: locked ? 18 : 22)),
          const Spacer(),
          if (!locked) Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: achievement.color, boxShadow: [BoxShadow(color: achievement.color.withOpacity(.6), blurRadius: 6)])),
        ]),
        const SizedBox(height: 8),
        Text(achievement.title, style: TextStyle(color: locked ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(achievement.description, style: TextStyle(color: locked ? AppColors.textSecondary.withOpacity(.5) : AppColors.textSecondary, fontSize: 9, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// COMPLETION DIALOG — updated with nextMode info (Feature 2)
// ════════════════════════════════════════════════════════════

class _CompletionDialog extends StatefulWidget {
  final TimerMode mode;
  final TimerMode nextMode;
  final int xpGained;
  final VoidCallback onDismiss;
  const _CompletionDialog({
    required this.mode,
    required this.nextMode,
    required this.xpGained,
    required this.onDismiss,
  });
  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: .5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _nextLabel {
    switch (widget.nextMode) {
      case TimerMode.focus: return 'Focus Session';
      case TimerMode.shortBreak: return 'Short Break';
      case TimerMode.longBreak: return 'Long Break';
    }
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: AppColors.surface, border: Border.all(color: widget.mode.accentColor.withOpacity(.4), width: 1.5),
          boxShadow: [BoxShadow(color: widget.mode.accentColor.withOpacity(.2), blurRadius: 40, spreadRadius: 5)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: widget.mode.gradientColors),
            boxShadow: [BoxShadow(color: widget.mode.accentColor.withOpacity(.4), blurRadius: 18)]),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
        const SizedBox(height: 18),
        Text(widget.mode == TimerMode.focus ? '🎉 Session Complete!' : '☕ Break Complete!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(widget.mode == TimerMode.focus ? 'Excellent work! Keep the momentum going.' : 'Feeling refreshed? Let\'s get back to it!',
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        if (widget.xpGained > 0) ...[
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.neonAmber.withOpacity(.12), border: Border.all(color: AppColors.neonAmber.withOpacity(.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('+${widget.xpGained} XP earned!', style: const TextStyle(color: AppColors.neonAmber, fontWeight: FontWeight.w700, fontSize: 14)),
            ])),
        ],
        // ── Feature 2: Show what's coming next
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.nextMode.accentColor.withOpacity(.08),
            border: Border.all(color: widget.nextMode.accentColor.withOpacity(.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.skip_next_rounded, color: widget.nextMode.accentColor, size: 16),
            const SizedBox(width: 7),
            Text('Up next: $_nextLabel', style: TextStyle(
              color: widget.nextMode.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
          ]),
        ),
        const SizedBox(height: 20),
        GestureDetector(onTap: widget.onDismiss, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: widget.nextMode.gradientColors)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Start $_nextLabel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ]))),
      ]),
    ),
  )));
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _ControlBtn extends StatefulWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color; final double size;
  const _ControlBtn({required this.icon, required this.label, required this.onTap, required this.color, required this.size});
  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: .88, upperBound: 1.0, value: 1.0); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.reverse(), onTapUp: (_) { _ctrl.forward(); widget.onTap(); }, onTapCancel: () => _ctrl.forward(),
    child: AnimatedBuilder(animation: _ctrl, builder: (_, __) => Transform.scale(scale: _ctrl.value, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: widget.size, height: widget.size, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card, border: Border.all(color: widget.color.withOpacity(.3))),
          child: Icon(widget.icon, color: widget.color, size: 22)),
      const SizedBox(height: 5),
      Text(widget.label, style: TextStyle(color: widget.color, fontSize: 10, fontWeight: FontWeight.w500)),
    ]))),
  );
}

class _RingPainter extends CustomPainter {
  final double progress; final Color? color; final List<Color>? colors; final double strokeWidth; final Color? glowColor;
  const _RingPainter({required this.progress, this.color, this.colors, required this.strokeWidth, this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;

    if (colors != null && colors!.isNotEmpty) {
      paint.shader = SweepGradient(startAngle: -pi / 2, endAngle: -pi / 2 + 2 * pi * progress, colors: colors!).createShader(Rect.fromCircle(center: center, radius: radius));
    } else { paint.color = color ?? Colors.white; }

    if (glowColor != null && progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth + 5..strokeCap = StrokeCap.round..color = glowColor!.withOpacity(.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ════════════════════════════════════════════════════════════
// FEATURE 1 — SETTINGS SCREEN
// ════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  final int focusDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final void Function(int focus, int shortBreak, int longBreak) onSave;

  const SettingsScreen({
    super.key,
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.onSave,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _focus;
  late double _shortBreak;
  late double _longBreak;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusDuration.toDouble();
    _shortBreak = widget.shortBreakDuration.toDouble();
    _longBreak = widget.longBreakDuration.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        CustomPaint(size: MediaQuery.of(context).size, painter: _GridPainter()),
        // Ambient top glow
        Positioned(top: -100, left: -60, right: -60,
          child: Container(height: 300, decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment.topCenter, radius: 1.0,
                colors: [Color(0x1400F5FF), Colors.transparent]),
          )),
        ),
        SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card, border: Border.all(color: AppColors.cardBorder)),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]).createShader(b),
                  child: const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .5)),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Section label
                  const Text('TIMER DURATIONS', style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  )),
                  const SizedBox(height: 14),
                  _DurationSliderCard(
                    label: 'Focus',
                    emoji: '🎯',
                    value: _focus,
                    min: 5, max: 90, divisions: 17,
                    gradientColors: TimerMode.focus.gradientColors,
                    accentColor: TimerMode.focus.accentColor,
                    onChanged: (v) => setState(() => _focus = v),
                  ),
                  const SizedBox(height: 14),
                  _DurationSliderCard(
                    label: 'Short Break',
                    emoji: '☕',
                    value: _shortBreak,
                    min: 1, max: 30, divisions: 29,
                    gradientColors: TimerMode.shortBreak.gradientColors,
                    accentColor: TimerMode.shortBreak.accentColor,
                    onChanged: (v) => setState(() => _shortBreak = v),
                  ),
                  const SizedBox(height: 14),
                  _DurationSliderCard(
                    label: 'Long Break',
                    emoji: '🛋️',
                    value: _longBreak,
                    min: 5, max: 60, divisions: 11,
                    gradientColors: TimerMode.longBreak.gradientColors,
                    accentColor: TimerMode.longBreak.accentColor,
                    onChanged: (v) => setState(() => _longBreak = v),
                  ),
                  const SizedBox(height: 28),
                  // Info tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.card,
                      border: Border.all(color: AppColors.neonPurple.withOpacity(.2)),
                    ),
                    child: const Row(children: [
                      Text('💡', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Changes apply immediately. If the timer is running, new durations take effect on the next session.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.5),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  // Save button
                  GestureDetector(
                    onTap: () {
                      widget.onSave(_focus.round(), _shortBreak.round(), _longBreak.round());
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
                        boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(.28), blurRadius: 18, spreadRadius: 2)],
                      ),
                      child: const Text('Save Settings', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: .5)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DurationSliderCard extends StatelessWidget {
  final String label, emoji;
  final double value, min, max;
  final int divisions;
  final List<Color> gradientColors;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _DurationSliderCard({
    required this.label,
    required this.emoji,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.gradientColors,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.card,
        border: Border.all(color: accentColor.withOpacity(.25)),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(.06), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(colors: gradientColors),
            ),
            child: Text('${value.round()} min',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: AppColors.surface,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayColor: accentColor.withOpacity(.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            Text('${min.round()}m', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            const Spacer(),
            Text('${max.round()}m', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }
}