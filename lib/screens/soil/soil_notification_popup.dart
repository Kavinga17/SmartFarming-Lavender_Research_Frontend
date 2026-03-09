// lib/soil/soil_notification_popup.dart
//
// Styled notification popups for the Soil component.
// Shows diagnosis-based alerts with emoji, color, icon, action message,
// "View Details" button, and termination warnings.

import 'package:flutter/material.dart';

/// Notification configuration for each diagnosis type.
class _DiagnosisStyle {
  final String emoji;
  final String title;
  final Color color;
  final IconData icon;
  final bool showViewDetails;

  const _DiagnosisStyle({
    required this.emoji,
    required this.title,
    required this.color,
    required this.icon,
    this.showViewDetails = false,
  });
}

const _kStyles = <String, _DiagnosisStyle>{
  'NITROGEN_LOCKOUT': _DiagnosisStyle(
    emoji: '🚨',
    title: 'Nitrogen Lockout',
    color: Color(0xFFEF4444), // red
    icon: Icons.warning_amber_rounded,
    showViewDetails: true,
  ),
  'NITROGEN_DEFICIENCY': _DiagnosisStyle(
    emoji: '🌱',
    title: 'Nitrogen Deficiency',
    color: Color(0xFFF59E0B), // amber
    icon: Icons.eco_rounded,
    showViewDetails: true,
  ),
  'UNDERWATERING': _DiagnosisStyle(
    emoji: '💧',
    title: 'Underwatering Detected',
    color: Color(0xFF3B82F6), // blue
    icon: Icons.water_drop_rounded,
    showViewDetails: false,
  ),
  'DISEASE_DETECTED': _DiagnosisStyle(
    emoji: '⚠️',
    title: 'Disease Detected',
    color: Color(0xFFEF4444), // red
    icon: Icons.bug_report_rounded,
    showViewDetails: true,
  ),
  'MILD_CHLOROSIS': _DiagnosisStyle(
    emoji: '🍃',
    title: 'Mild Chlorosis',
    color: Color(0xFFF59E0B), // amber
    icon: Icons.remove_red_eye_rounded,
    showViewDetails: false,
  ),
  'UNKNOWN_ISSUE': _DiagnosisStyle(
    emoji: '❓',
    title: 'Unknown Issue',
    color: Color(0xFFF59E0B), // amber
    icon: Icons.help_outline_rounded,
    showViewDetails: false,
  ),
  'HEALTHY': _DiagnosisStyle(
    emoji: '✅',
    title: 'Plant is Healthy',
    color: Color(0xFF22C55E), // green
    icon: Icons.check_circle_rounded,
    showViewDetails: false,
  ),
  'ROUTINE_CREATED': _DiagnosisStyle(
    emoji: '✅',
    title: 'Routine Created',
    color: Color(0xFF22C55E), // green
    icon: Icons.check_circle_rounded,
    showViewDetails: false,
  ),
  'ROUTINE_TERMINATED': _DiagnosisStyle(
    emoji: '⏹️',
    title: 'Routine Terminated',
    color: Color(0xFF6366F1), // indigo
    icon: Icons.stop_circle_rounded,
    showViewDetails: false,
  ),
};

/// Show a styled popup notification for a soil-component event.
///
/// [diagnosis] one of: NITROGEN_LOCKOUT, NITROGEN_DEFICIENCY, UNDERWATERING,
///   DISEASE_DETECTED, MILD_CHLOROSIS, UNKNOWN_ISSUE, HEALTHY,
///   ROUTINE_CREATED, ROUTINE_TERMINATED.
///
/// [action] the action message shown in the popup body.
///
/// [onViewDetails] optional callback — when provided a "View Details" button
///   is shown (used for lockout / deficiency).
///
/// [routineTerminated] if true an extra termination-warning banner appears.
///
/// [recommendation] optional extra recommendation text.
void showSoilNotification(
  BuildContext context, {
  required String diagnosis,
  required String action,
  VoidCallback? onViewDetails,
  bool routineTerminated = false,
  String? recommendation,
}) {
  final style = _kStyles[diagnosis] ??
      const _DiagnosisStyle(
        emoji: 'ℹ️',
        title: 'Soil Update',
        color: Color(0xFF6B7280),
        icon: Icons.info_outline_rounded,
      );

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'soil_notification',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, a1, a2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a1, child: child),
      );
    },
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Material(
              color: Colors.transparent,
              child: _SoilNotificationCard(
                style: style,
                action: action,
                onViewDetails: onViewDetails,
                routineTerminated: routineTerminated,
                recommendation: recommendation,
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Internal card widget
// ─────────────────────────────────────────────────────────────────────────────

class _SoilNotificationCard extends StatelessWidget {
  final _DiagnosisStyle style;
  final String action;
  final VoidCallback? onViewDetails;
  final bool routineTerminated;
  final String? recommendation;

  const _SoilNotificationCard({
    required this.style,
    required this.action,
    this.onViewDetails,
    this.routineTerminated = false,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final showDetails = style.showViewDetails && onViewDetails != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Coloured header bar ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(style.icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${style.emoji}  ${style.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white70, size: 22),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Action message
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),

                // Recommendation
                if (recommendation != null && recommendation!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18, color: style.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation!,
                            style: TextStyle(
                              fontSize: 13,
                              color: style.color,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Termination warning
                if (routineTerminated) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Irrigation routine was automatically terminated.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                // View Details — only for lockout / deficiency / disease
                if (showDetails) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewDetails!();
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: style.color,
                        side: BorderSide(color: style.color),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // OK / Dismiss
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: style.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
