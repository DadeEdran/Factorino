import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// The control that widens a paginated list's window by one page.
///
/// **A button, not an on-scroll trigger.** Infinite scroll hides the size of
/// what the user is looking at: a list that keeps loading gives no way to tell
/// a long list from a slow one, and no way to reach the end of anything. An
/// explicit control makes the paging visible, and on a financial record —
/// where "is that all of them?" is a real question — visible is what it should
/// be.
///
/// It is an item in the list rather than a bar pinned beneath it, so it scrolls
/// away with the rows and costs no vertical space on a full screen.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Persian, from the localization layer.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: TextButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
