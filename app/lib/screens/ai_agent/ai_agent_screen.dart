// lib/screens/ai_agent/ai_agent_screen.dart
// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'package:coachmint/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common_widgets/widgets.dart' hide NumberFormat;
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../utils/colors.dart';

// ─────────────────────────────────────────────────────────────
// Chat-specific colour palette
// ─────────────────────────────────────────────────────────────
const _chatBg            = Color(0xFF0D1117);
const _chatSurface       = Color(0xFF161B22);
const _chatBorder        = Color(0xFF30363D);
const _chatTextPrimary   = Color(0xFFE6EDF3);
const _chatTextSecondary = Color(0xFF8B949E);
const _userBubbleBg      = Color(0xFF1F6FEB);
const _chartBlue         = Color(0xFF58A6FF);
const _chartRed          = Color(0xFFF85149);
const _chartAmber        = Color(0xFFD29922);
const _chartGreen        = Color(0xFF3FB950);
const _lessonCyan        = Color(0xFF39D0D8);

// ─────────────────────────────────────────────────────────────
// Lesson link map
// ─────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _lessonLinks = {
  'Emergency Budgeting for Gig Workers': {
    'link': 'https://www.youtube.com/watch?v=cT2NLVrQlKc',
  },
  'Never Miss a Bill: The Auto-Pay Trick': {
    'link': 'https://www.youtube.com/watch?v=xvN4dPF9CQY',
  },
  'Income Smoothing for Irregular Earners': {
    'link': 'https://www.youtube.com/watch?v=-Gr4Xx7Yguw',
  },
  'The 50/30/20 Rule (Adapted for Gig Income)': {
    'link': 'https://www.youtube.com/watch?v=i9vJJn25Nso',
  },
  'Building Your 3-Month Emergency Fund': {
    'link': 'https://www.youtube.com/watch?v=nkNWLDe8Dz4',
  },
  'Investing 101 for Freelancers': {
    'link': 'https://www.youtube.com/watch?v=0pNz0QFXK84',
  },
};

// ═════════════════════════════════════════════════════════════
// AIAgentScreen
// ═════════════════════════════════════════════════════════════
class AIAgentScreen extends StatefulWidget {
  final String userId;
  const AIAgentScreen({super.key, required this.userId});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> {
  // ── State ──────────────────────────────────────────────────
  final ChatService           _chatService      = ChatService();
  final List<ChatMessage>     _messages         = [];
  final ScrollController      _scrollController = ScrollController();
  final TextEditingController _textController   = TextEditingController();

  bool   _isLoading          = false;
  bool   _lessonCardVisible  = false;
  String _lessonTitle        = '';
  String _lessonSummary      = '';
  String _lessonLink         = '';
  int    _latestResilienceScore = 0;

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _sendSeedMessage());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Seed message ───────────────────────────────────────────
  void _sendSeedMessage() async {
    setState(() => _isLoading = true);
    try {
      final response = await _chatService.sendMessage(
        userId: widget.userId,
        message: 'Hello',
        history: [],
      );
      _handleResponse(response);
    } catch (_) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          role: 'model',
          content:
          "Hey! I'm your CoachMint AI. Ask me anything about your finances.",
        ));
      });
    }
  }

  // ── User sends a message ───────────────────────────────────
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    final allPrior = _messages.take(_messages.length - 1).toList();
    final capped   = allPrior.length > 20
        ? allPrior.sublist(allPrior.length - 20)
        : allPrior;
    final historyPayload = capped
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    try {
      final response = await _chatService.sendMessage(
        userId: widget.userId,
        message: text,
        history: historyPayload,
      );
      _handleResponse(response);
    } on ChatException catch (e) {
      _handleError(e);
    } catch (_) {
      _handleError(
          const ChatException(statusCode: -1, message: 'unknown'));
    }
  }

  // ── Handle response ────────────────────────────────────────
  void _handleResponse(ChatApiResponse response) {
    final link = _lessonLinks[response.suggestedLessonTitle]?['link'] ?? '';
    final sim  = response.simulationResult != null
        ? SimulationData.fromMap(response.simulationResult!)
        : null;

    setState(() {
      _isLoading         = false;
      _lessonTitle       = response.suggestedLessonTitle;
      _lessonSummary     = response.suggestedLessonSummary;
      _lessonLink        = link;
      _lessonCardVisible = true;

      _messages.add(ChatMessage(
        role: 'model',
        content: response.reply,
        hasSimulation: response.toolUsed == 'simulate_expense',
        simulation: sim,
      ));

      if (sim != null) {
        _latestResilienceScore = sim.after.resilienceScore;
      }
    });
    _scrollToBottom();
  }

  // ── Handle error ───────────────────────────────────────────
  void _handleError(ChatException e) {
    String msg;
    switch (e.statusCode) {
      case 500: msg = 'Something went wrong on our end. Try again in a moment.'; break;
      case 502: msg = "I'm having trouble thinking right now. Please retry.";    break;
      case 0:   msg = 'Connection timed out. Check your internet and retry.';    break;
      default:  msg = 'Something went wrong. Please try again.';
    }
    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(role: 'model', content: msg));
    });
    _scrollToBottom();
  }

  // ── Scroll ─────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _chatBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _chatBorder),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: _chatTextPrimary, size: 20),
        onPressed: () => context.go(AppRoutes.dashboard),
        splashRadius: 20,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HexAvatar(size: 34),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COACHMINT AI',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _chatTextPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              Row(
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 4),
                  Text(
                    'ONLINE',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _chartGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: _ResilienceRing(score: _latestResilienceScore),
        ),
      ],
    );
  }

  // ── Lesson card ────────────────────────────────────────────
  Widget _buildLessonCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => SlideTransition(
        position:
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _lessonCardVisible && _lessonTitle.isNotEmpty
          ? _LessonCard(
        key: const ValueKey('visible'),
        title: _lessonTitle,
        summary: _lessonSummary,
        link: _lessonLink,
        onDismiss: () =>
            setState(() => _lessonCardVisible = false),
      )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }

  // ── Message list ───────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ThinkingIndicator(),
          );
        }
        final msg      = _messages[index];
        final maxWidth = min(
            MediaQuery.of(context).size.width * 0.76, 480.0);
        final showLabel = msg.role == 'model' &&
            (index == 0 || _messages[index - 1].role == 'user');
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ChatBubble(
            message: msg,
            maxWidth: maxWidth,
            showSenderLabel: showLabel,
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _chatBg,
        extendBody: true,
        appBar: _buildAppBar(),
        bottomNavigationBar: SizedBox(
          height: 70,
          child: const CustomBottomNavBar(currentIndex: 1),
        ),
        body: Column(
          children: [
            _buildLessonCard(),
            Expanded(child: _buildMessageList()),
            _InputBar(
              controller: _textController,
              isLoading: _isLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _ResilienceRing — CustomPaint arc progress indicator
// ═════════════════════════════════════════════════════════════

class _ResilienceRing extends StatelessWidget {
  final int score;
  const _ResilienceRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100.0).clamp(0.0, 1.0);
    final arcColor = pct > 0.6
        ? _chartGreen
        : pct > 0.3
        ? _chartAmber
        : _chartRed;

    return Tooltip(
      message: 'Resilience Score',
      child: SizedBox(
        width: 42,
        height: 42,
        child: CustomPaint(
          painter: _RingPainter(progress: pct, color: arcColor),
          child: Center(
            child: Text(
              '$score',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: arcColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - 5) / 2;

    // Track ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _chatBorder
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ═════════════════════════════════════════════════════════════
// _HexAvatar — hexagonal container
// ═════════════════════════════════════════════════════════════

class _HexAvatar extends StatelessWidget {
  final double size;
  const _HexAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(),
        child: Center(
          child: Text(
            '₹',
            style: TextStyle(
              fontSize: size * 0.38,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = AppColors.primary.withOpacity(0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═════════════════════════════════════════════════════════════
// _PulsingDot
// ═════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: _chartGreen),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _LessonCard
// ═════════════════════════════════════════════════════════════

class _LessonCard extends StatelessWidget {
  final String title;
  final String summary;
  final String link;
  final VoidCallback onDismiss;

  const _LessonCard({
    super.key,
    required this.title,
    required this.summary,
    required this.link,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _chatSurface,
        border: Border(
          left:   BorderSide(color: _lessonCyan, width: 3),
          bottom: BorderSide(color: _chatBorder),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _lessonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _lessonCyan.withOpacity(0.25)),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: _lessonCyan, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUGGESTED LESSON',
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _lessonCyan,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _chatTextPrimary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _chatTextSecondary,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 15, color: _chatTextSecondary),
                ),
              ),
              const SizedBox(height: 6),
              if (link.isNotEmpty)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse(link),
                      mode: LaunchMode.externalApplication),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _lessonCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _lessonCyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      'WATCH',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _lessonCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _ChatBubble
// ═════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final double      maxWidth;
  final bool        showSenderLabel;

  const _ChatBubble({
    required this.message,
    required this.maxWidth,
    required this.showSenderLabel,
  });

  @override
  Widget build(BuildContext context) =>
      message.role == 'user' ? _buildUser() : _buildAi();

  Widget _buildUser() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: _userBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(14),
                  topRight:    Radius.circular(14),
                  bottomLeft:  Radius.circular(14),
                  bottomRight: Radius.circular(2),
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: _chatTextPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(message.timestamp),
            style: GoogleFonts.dmSans(
                fontSize: 10, color: _chatTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAi() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HexAvatar(size: 30),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSenderLabel) ...[
                Text(
                  'CoachMint AI',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _chatSurface,
                    borderRadius: const BorderRadius.only(
                      topRight:    Radius.circular(14),
                      bottomLeft:  Radius.circular(2),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(color: _chatBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: _chatTextPrimary,
                          height: 1.55,
                        ),
                      ),
                      if (message.hasSimulation &&
                          message.simulation != null) ...[
                        const SizedBox(height: 16),
                        _SimulationCard(sim: message.simulation!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(message.timestamp),
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: _chatTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ═════════════════════════════════════════════════════════════
// _ThinkingIndicator — waveform bars
// ═════════════════════════════════════════════════════════════

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HexAvatar(size: 30),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _chatSurface,
            borderRadius: const BorderRadius.only(
              topRight:    Radius.circular(14),
              bottomLeft:  Radius.circular(2),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(color: _chatBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _WaveBar(delayMs: 0),
              SizedBox(width: 4),
              _WaveBar(delayMs: 120),
              SizedBox(width: 4),
              _WaveBar(delayMs: 240),
              SizedBox(width: 4),
              _WaveBar(delayMs: 360),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveBar extends StatefulWidget {
  final int delayMs;
  const _WaveBar({required this.delayMs});

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550));
    _scale = Tween<double>(begin: 0.35, end: 1.4).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scaleY: _scale.value,
        alignment: Alignment.center,
        child: Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _chatTextSecondary.withOpacity(0.65),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _SimulationCard
// ═════════════════════════════════════════════════════════════

class _SimulationCard extends StatefulWidget {
  final SimulationData sim;
  const _SimulationCard({required this.sim});

  @override
  State<_SimulationCard> createState() =>
      _SimulationCardState();
}

class _SimulationCardState extends State<_SimulationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _size;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _size = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sim      = widget.sim;
    final hasChart = sim.predictionBefore.balanceCurve.isNotEmpty;

    return FadeTransition(
      opacity: _fade,
      child: SizeTransition(
        sizeFactor: _size,
        child: Container(
          decoration: BoxDecoration(
            color: _chatBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _chatBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    _VerdictChip(verdict: sim.verdict),
                    const Spacer(),
                    Text(
                      'SIMULATION',
                      style: GoogleFonts.dmSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: _chatTextSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (hasChart) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _chatBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: SizedBox(
                    height: 175,
                    child: _buildChart(sim),
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.all(12),
                child: _StatTable(sim: sim),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(SimulationData sim) {
    final afterColor =
    sim.verdict == 'safe' ? _chartAmber : _chartRed;
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: DateTimeAxis(
        isVisible: true,
        labelStyle: const TextStyle(
            color: _chatTextSecondary, fontSize: 9),
        majorGridLines: const MajorGridLines(
            width: 0.3, color: _chatBorder),
        dateFormat: DateFormat('d MMM'),
        intervalType: DateTimeIntervalType.days,
        interval: 3,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      primaryYAxis: NumericAxis(
        isVisible: true,
        labelStyle: const TextStyle(
            color: _chatTextSecondary, fontSize: 9),
        majorGridLines: const MajorGridLines(
            width: 0.3, color: _chatBorder),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        numberFormat: NumberFormat.compact(locale: 'en_IN'),
        labelFormat: '₹{value}',
      ),
      legend: const Legend(
        isVisible: true,
        backgroundColor: Colors.transparent,
        textStyle:
        TextStyle(color: _chatTextSecondary, fontSize: 10),
        position: LegendPosition.bottom,
      ),
      series: <CartesianSeries>[
        SplineSeries<BalancePoint, DateTime>(
          name: 'Before',
          dataSource: sim.predictionBefore.balanceCurve,
          xValueMapper: (p, _) => p.date,
          yValueMapper: (p, _) => p.balance,
          color: _chartBlue,
          width: 2,
          animationDuration: 800,
        ),
        SplineSeries<BalancePoint, DateTime>(
          name: 'After',
          dataSource: sim.predictionAfter.balanceCurve,
          xValueMapper: (p, _) => p.date,
          yValueMapper: (p, _) => p.balance,
          color: afterColor,
          width: 2,
          dashArray: const <double>[5, 3],
          animationDuration: 800,
        ),
      ],
    );
  }
}

// ─── Stat table ───────────────────────────────────────────────

class _StatTable extends StatelessWidget {
  final SimulationData sim;
  const _StatTable({required this.sim});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.timelapse_rounded, 'Runway Lost',
      '${sim.delta.survivalDaysLost.toStringAsFixed(1)} days',
      _chartRed),
      (Icons.shield_outlined, 'Resilience Drop',
      '${sim.delta.resilienceDrop} pts', _chartAmber),
      if (sim.delta.billsNowAtRisk.isNotEmpty)
        (Icons.warning_amber_rounded, 'Bills at Risk',
        sim.delta.billsNowAtRisk.map((b) => b.name).join(', '),
        _chartRed),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _chatBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: _chatBorder),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 13, color: rows[i].$4),
                  const SizedBox(width: 8),
                  Text(
                    rows[i].$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: _chatTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].$3,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rows[i].$4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Verdict chip ─────────────────────────────────────────────

class _VerdictChip extends StatelessWidget {
  final String verdict;
  const _VerdictChip({required this.verdict});

  @override
  Widget build(BuildContext context) {
    const colorMap = {
      'safe':     _chartGreen,
      'risky':    _chartAmber,
      'critical': _chartRed,
    };
    const labelMap = {
      'safe':     'SAFE TO SPEND',
      'risky':    'RISKY',
      'critical': 'CRITICAL',
    };
    const iconMap = {
      'safe':     Icons.check_circle_outline_rounded,
      'risky':    Icons.warning_amber_rounded,
      'critical': Icons.dangerous_outlined,
    };
    final color = colorMap[verdict] ?? _chartAmber;
    final label = labelMap[verdict] ?? verdict.toUpperCase();
    final icon  = iconMap[verdict] ?? Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _InputBar — focused glow, square send button
// ═════════════════════════════════════════════════════════════

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool                  isLoading;
  final VoidCallback           onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(
            () => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: _chatSurface,
        border: Border(top: BorderSide(color: _chatBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Input field with animated glow border
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focused
                        ? AppColors.primary.withOpacity(0.55)
                        : _chatBorder,
                    width: _focused ? 1.5 : 1.0,
                  ),
                  boxShadow: _focused
                      ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.07),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => widget.onSend(),
                    textInputAction: TextInputAction.send,
                    style: GoogleFonts.dmSans(
                      color: _chatTextPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: GoogleFonts.dmSans(
                        color: _chatTextSecondary.withOpacity(0.55),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: _chatBg,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Send button — rounded square, arrow-up icon
            GestureDetector(
              onTap: widget.isLoading ? null : widget.onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? _chatBorder
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: widget.isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.isLoading
                    ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _chatTextSecondary,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}