import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/water_intake_provider.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildAppBar(),
                const SizedBox(height: 24),
                _buildWaterGoalSection(context, ref, settings),
                const SizedBox(height: 16),
                _buildRemindersSection(context, ref, settings),
                const SizedBox(height: 16),
                _buildScheduleSection(context, ref, settings),
                const SizedBox(height: 16),
                _buildDataSection(context, ref),
                const SizedBox(height: 24),
              ],
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
          child: const Icon(Icons.settings, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterGoalSection(BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      title: 'Water Goal',
      icon: Icons.flag_outlined,
      children: [
        _buildSettingTile(
          icon: Icons.local_drink,
          label: 'Daily target',
          value: '${settings.dailyTargetMl} ml',
          onTap: () => _showEditTargetDialog(context, ref, settings),
        ),
      ],
    );
  }

  Widget _buildRemindersSection(BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      title: 'Reminders',
      icon: Icons.notifications_outlined,
      children: [
        _buildSettingTile(
          icon: Icons.access_time,
          label: 'Reminder interval',
          value: '${settings.reminderIntervalMinutes} minutes',
          onTap: () => _showEditIntervalDialog(context, ref, settings),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      title: 'Schedule',
      icon: Icons.schedule,
      children: [
        _buildSettingTile(
          icon: Icons.wb_sunny_outlined,
          label: 'Wake time',
          value: _formatTime(settings.wakeTimeHour, settings.wakeTimeMinute),
          onTap: () => _showEditWakeTimeDialog(context, ref, settings),
        ),
        Divider(
          height: 1,
          indent: 56,
          endIndent: 18,
          color: AppTheme.textLight.withValues(alpha: 0.2),
        ),
        _buildSettingTile(
          icon: Icons.bedtime_outlined,
          label: 'Sleep time',
          value: _formatTime(settings.sleepTimeHour, settings.sleepTimeMinute),
          onTap: () => _showEditSleepTimeDialog(context, ref, settings),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context, WidgetRef ref) {
    return _buildSection(
      title: 'Data',
      icon: Icons.storage_outlined,
      children: [
        _buildSettingTile(
          icon: Icons.delete_outline,
          label: 'Reset all data',
          value: '',
          isDestructive: true,
          onTap: () => _showResetConfirmationDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.error.withValues(alpha: 0.1)
                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppTheme.error : AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              Flexible(
                child: Text(
                  value,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              color: AppTheme.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  void _showEditTargetDialog(BuildContext context, WidgetRef ref, UserSettings settings) {
    final controller = TextEditingController(text: settings.dailyTargetMl.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Daily target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Enter target in ml',
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
                ref.read(settingsProvider.notifier).updateSettings(dailyTargetMl: ml);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditIntervalDialog(BuildContext context, WidgetRef ref, UserSettings settings) {
    final controller = TextEditingController(text: settings.reminderIntervalMinutes.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Reminder interval'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Enter interval in minutes',
            suffixText: 'minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                ref.read(settingsProvider.notifier).updateSettings(
                  reminderIntervalMinutes: minutes,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditWakeTimeDialog(BuildContext context, WidgetRef ref, UserSettings settings) async {
    final initialTime = TimeOfDay(hour: settings.wakeTimeHour, minute: settings.wakeTimeMinute);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      ref.read(settingsProvider.notifier).updateSettings(
        wakeTimeHour: picked.hour,
        wakeTimeMinute: picked.minute,
      );
    }
  }

  Future<void> _showEditSleepTimeDialog(BuildContext context, WidgetRef ref, UserSettings settings) async {
    final initialTime = TimeOfDay(hour: settings.sleepTimeHour, minute: settings.sleepTimeMinute);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      ref.read(settingsProvider.notifier).updateSettings(
        sleepTimeHour: picked.hour,
        sleepTimeMinute: picked.minute,
      );
    }
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.error,
          size: 48,
        ),
        title: const Text('Reset all data?'),
        content: const Text(
          'This will delete all your water logs, settings, and cancel scheduled notifications. This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear water logs
              await ref.read(waterIntakeProvider.notifier).clearAll();
              
              // Clear settings (also cancels notifications via SettingsNotifier)
              await ref.read(settingsProvider.notifier).clearSettings();
              
              // Navigate back to onboarding
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
