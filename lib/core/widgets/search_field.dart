import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// The search input above a list.
///
/// **Debounced.** Each keystroke would otherwise re-issue a `LIKE` query
/// against the whole table, so typing a five-letter name runs five searches and
/// throws four of them away — on a list §13 requires to work at thousands of
/// rows. The delay is short enough to feel immediate and long enough that
/// ordinary typing produces one query rather than one per letter.
///
/// The debounce lives here, in the widget, rather than in the provider. It is a
/// property of how fast a person types, not of what the data layer means, and
/// keeping it out of the provider leaves that provider synchronous and directly
/// testable.
///
/// Normalization is deliberately **not** done here. The term goes to the
/// repository as typed and is folded there by `searchKey`, the same function
/// that produced the stored `search_name` (D-029). Folding it in the widget
/// would be the second normalizer that decision exists to prevent.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.hintText,
    required this.onChanged,
    this.clearTooltip,
    super.key,
  });

  /// Persian placeholder, from the localization layer.
  final String hintText;

  /// Called with the debounced term.
  final ValueChanged<String> onChanged;

  final String? clearTooltip;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(AppDuration.inputDebounce, () => widget.onChanged(value));
    // Rebuild for the clear button's visibility only; the query is not
    // reissued here.
    setState(() {});
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;

    // field-limit-exempt: a search term is never stored, so there is no column
    // whose limit this could disagree with. It reaches SQL as a bound
    // parameter through searchKey (D-018, D-029), and the only thing a length
    // limit would change is how much of their own query the user can see.
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: AppIconSize.md),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close, size: AppIconSize.md),
                tooltip: widget.clearTooltip,
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
