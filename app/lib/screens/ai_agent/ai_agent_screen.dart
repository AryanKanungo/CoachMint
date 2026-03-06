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
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../utils/colors.dart';

// ─────────────────────────────────────────────────────────────
// Chat-specific colour palette (scoped to this file only)
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
// Lesson link map — keys must match backend suggested_lesson_title
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
// AIAgentScreen — root StatefulWidget (chat screen)
// ═════════════════════════════════════════════════════════════
class AIAgentScreen extends StatefulWidget {
  final String userId;

  const AIAgentScreen({super.key, required this.userId});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> {
  // ── State fields ───────────────────────────────────────────
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController =
      TextEditingController();

  bool _isLoading = false;
  bool _lessonCardVisible = false;
  String _lessonTitle   = '';
  String _lessonSummary = '';
  String _lessonLink    = '';
  int _latestResilienceScore = 0;

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendSeedMessage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Seed: fires on load, result shown as first AI bubble ───
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

  // ── User submits a message ─────────────────────────────────
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    // History = everything except the message just added, capped at 20
    final allPrior =
        _messages.take(_messages.length - 1).toList();
    final capped = allPrior.length > 20
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

  // ── Parse successful response ──────────────────────────────
  void _handleResponse(ChatApiResponse response) {
    final link =
        _lessonLinks[response.suggestedLessonTitle]?['link'] ?? '';
    final sim = response.simulationResult != null
        ? SimulationData.fromMap(response.simulationResult!)
        : null;

    setState(() {
      _isLoading = false;
      _lessonTitle   = response.suggestedLessonTitle;
      _lessonSummary = response.suggestedLessonSummary;
      _lessonLink    = link;
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

  // ── Map status codes to user-facing error bubbles ──────────
  void _handleError(ChatException e) {
    String msg;
    switch (e.statusCode) {
      case 500:
        msg = 'Something went wrong on our end. Try again in a moment.';
        break;
      case 502:
        msg = "I'm having trouble thinking right now. Please retry.";
        break;
      case 0:
        msg = 'Connection timed out. Check your internet and retry.';
        break;
      default:
        msg = 'Something went wrong. Please try again.';
    }
    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(role: 'model', content: msg));
    });
    _scrollToBottom();
  }

  // ── Smooth scroll to latest message ───────────────────────
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

  // ─────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _chatBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: _chatTextPrimary),
        onPressed: () => context.go(AppRoutes.dashboard),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CoachMint AI',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _chatTextPrimary,
            ),
          ),
          Row(
            children: [
              _PulsingDot(),
              const SizedBox(width: 5),
              Text(
                'Online',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _chatTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_latestResilienceScore',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Lesson card — animated, pinned above ListView
  // ─────────────────────────────────────────────────────────
  Widget _buildLessonCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
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

  // ─────────────────────────────────────────────────────────
  // Message ListView
  // ─────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ThinkingIndicator(),
          );
        }
        final msg = _messages[index];
        final maxWidth = min(
            MediaQuery.of(context).size.width * 0.75, 480.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ChatBubble(message: msg, maxWidth: maxWidth),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _chatBg,
        appBar: _buildAppBar(),
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
// _PulsingDot
// ═════════════════════════════════════════════════════════════
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.primary),
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
          left: BorderSide(color: _lessonCyan, width: 3),
          bottom: BorderSide(color: _chatBorder),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_filled_rounded,
              color: _lessonCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _chatTextPrimary,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: link.isNotEmpty
                    ? () => launchUrl(Uri.parse(link),
                        mode: LaunchMode.externalApplication)
                    : null,
                child: Text(
                  '▶ Watch',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _lessonCyan,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: _chatTextSecondary),
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
  final double maxWidth;

  const _ChatBubble(
      {required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return message.role == 'user'
        ? _buildUser()
        : _buildAi();
  }

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
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _chatTextPrimary,
                    height: 1.5),
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
        _avatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _chatSurface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: _chatBorder),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: _chatTextPrimary,
                            height: 1.55),
                      ),
                      if (message.hasSimulation &&
                          message.simulation != null) ...[
                        const SizedBox(height: 14),
                        _SimulationCard(
                            sim: message.simulation!),
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

  Widget _avatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('₹',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ═════════════════════════════════════════════════════════════
// _ThinkingIndicator
// ═════════════════════════════════════════════════════════════
class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text('₹',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _chatSurface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: _chatBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedDot(delayMs: 0),
              SizedBox(width: 6),
              _AnimatedDot(delayMs: 200),
              SizedBox(width: 6),
              _AnimatedDot(delayMs: 400),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _AnimatedDot
// ─────────────────────────────────────────────────────────────
class _AnimatedDot extends StatefulWidget {
  final int delayMs;
  const _AnimatedDot({required this.delayMs});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _chatTextSecondary),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _SimulationCard — verdict chip + Syncfusion chart + stat chips
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
  late Animation<double> _fade;
  late Animation<double> _size;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500));
    _fade =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _size =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sim = widget.sim;
    final hasChart =
        sim.predictionBefore.balanceCurve.isNotEmpty;

    return FadeTransition(
      opacity: _fade,
      child: SizeTransition(
        sizeFactor: _size,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _chatBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _chatBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VerdictChip(verdict: sim.verdict),
              const SizedBox(height: 12),
              if (hasChart) ...[
                SizedBox(
                  height: 180,
                  child: _buildChart(sim),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: '📉',
                    label: 'Runway Lost',
                    value:
                        '${sim.delta.survivalDaysLost.toStringAsFixed(1)} days',
                    color: _chartRed,
                  ),
                  _StatChip(
                    icon: '🎯',
                    label: 'Resilience Drop',
                    value: '${sim.delta.resilienceDrop} pts',
                    color: _chartAmber,
                  ),
                  if (sim.delta.billsNowAtRisk.isNotEmpty)
                    _StatChip(
                      icon: '⚠',
                      label: 'Bills at Risk',
                      value: sim.delta.billsNowAtRisk
                          .map((b) => b.name)
                          .join(', '),
                      color: _chartRed,
                    ),
                ],
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
        textStyle: TextStyle(
            color: _chatTextSecondary, fontSize: 10),
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

// ─────────────────────────────────────────────────────────────
// _VerdictChip
// ─────────────────────────────────────────────────────────────
class _VerdictChip extends StatelessWidget {
  final String verdict;
  const _VerdictChip({required this.verdict});

  @override
  Widget build(BuildContext context) {
    const colorMap = {
      'safe': _chartGreen,
      'risky': _chartAmber,
      'critical': _chartRed,
    };
    const labelMap = {
      'safe': '✅ SAFE TO SPEND',
      'risky': '⚠️ RISKY',
      'critical': '🚨 CRITICAL',
    };
    final color = colorMap[verdict] ?? _chartAmber;
    final label =
        labelMap[verdict] ?? verdict.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _StatChip
// ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _chatSurface,
        border: Border.all(color: _chatBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: GoogleFonts.dmSans(
                color: _chatTextSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _InputBar
// ═════════════════════════════════════════════════════════════
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: _chatSurface,
        border:
            Border(top: BorderSide(color: _chatBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.dmSans(
                    color: _chatTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask CoachMint anything...',
                  hintStyle: GoogleFonts.dmSans(
                      color: _chatTextSecondary, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: _chatBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: _chatBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLoading
                      ? _chatBorder
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: isLoading
                      ? _chatTextSecondary
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
