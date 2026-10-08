import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/water_intake_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/water_bottle_painter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _addWater(int ml) {
    ref.read(waterIntakeProvider.notifier).addLog(ml);
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Custom amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter ml',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                _addWater(ml);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final targetMl = settings?.dailyTargetMl ?? 2000;
    final progress = targetMl > 0 ? (todayTotal / targetMl).clamp(0.0, 1.0) : 0.0;
    final percentText = (progress * 100).toInt();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAppBar(),
                    const SizedBox(height: 16),
                    _buildReminderCard(),
                    const SizedBox(height: 24),
                    _buildBottleSection(todayTotal, targetMl, progress, percentText),
                    const SizedBox(height: 28),
                    _buildQuickAddButtons(),
                    const SizedBox(height: 20),
                    _buildTodayTargetCard(targetMl),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Flexible(child: Text(
          'AquaTrack',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        )),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryBlue),
            onPressed: () {},
            splashRadius: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard() {
    final settings = ref.watch(settingsProvider);
    final interval = settings?.reminderIntervalMinutes ?? 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.access_time, color: AppTheme.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next reminder in',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$interval minutes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          )),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildBottleSection(int todayTotal, int targetMl, double progress, int percentText) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 340;
      final bottle = AnimatedWaterBottle(
        fillPercent: progress,
        width: compact ? 110 : 130,
        height: compact ? 205 : 240,
      );
      final stats = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Keep long totals/targets within the available width.
            Text('$todayTotal ml',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text('of $targetMl ml',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            // Progress percentage
            Text(
              '$percentText%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0 ? AppTheme.success : AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            // Motivational message
            if (progress >= 1.0)
              _buildMotivationBadge(
                icon: Icons.emoji_events,
                text: 'Great job!\nYou reached your goal!',
                color: AppTheme.success,
              )
            else if (progress >= 0.5)
              _buildMotivationBadge(
                icon: Icons.thumb_up,
                text: 'Keep going, you\'re\non track!',
                color: AppTheme.primaryBlue,
              )
            else
              _buildMotivationBadge(
                icon: Icons.water_drop_outlined,
                text: 'Stay hydrated!\nDrink some water.',
                color: AppTheme.waterMedium,
              ),
          ],
        );
      if (compact) {
        return Column(children: [bottle, const SizedBox(height: 12), stats]);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [bottle, const SizedBox(width: 16),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft, child: stats))],
      );
    });
  }

  Widget _buildMotivationBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildQuickAddButton(100, Icons.water_drop_outlined),
        _buildQuickAddButton(200, Icons.water_drop),
        _buildCustomAddButton(),
      ],
    );
  }

  Widget _buildQuickAddButton(int ml, IconData icon) {
    return GestureDetector(
      onTap: () => _addWater(ml),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            '+$ml ml',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAddButton() {
    return GestureDetector(
      onTap: _showCustomAmountDialog,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          const Text(
            '+ Custom',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTargetCard(int targetMl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.flag_outlined, color: AppTheme.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s target',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${targetMl.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ml',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          )),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }
}
