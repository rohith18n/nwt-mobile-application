import 'dart:async';

import 'package:flutter/material.dart';

/// A mixin that provides "peek" behavior for Pinput-based PIN fields.
///
/// When the user types a digit, it is visible for [peekDuration] before
/// being replaced by [obscuringCharacter].
///
/// Usage with `Pinput.builder`:
///  1. Add `with PinPeekMixin` to your State class.
///  2. Call [onPinChanged] from Pinput's `onChanged` callback.
///  3. Inside the `builder` callback, check [peekIndex] against `state.index`
///     to decide whether to show the digit or [obscuringCharacter].
///  4. Call [disposePeekMixin] from your `dispose()` override.
mixin PinPeekMixin<T extends StatefulWidget> on State<T> {
  /// How long the digit is visible before being obscured.
  Duration get peekDuration => const Duration(milliseconds: 500);

  /// The character shown after the peek window closes.
  String get obscuringCharacter => '*';

  // ── internal state ──────────────────────────────────────────────────────────

  /// Index of the cell currently in "peek" mode (-1 = none).
  int _peekIndex = -1;

  /// Active timer that ends the peek.
  Timer? _peekTimer;

  // ── public API ───────────────────────────────────────────────────────────────

  /// The index currently being peeked (-1 when none).
  int get peekIndex => _peekIndex;

  /// The last text value seen (used to detect newly added characters).
  String _previousPin = '';

  /// Call this from Pinput's `onChanged`.
  void onPinChanged(String newValue) {
    if (newValue.length > _previousPin.length) {
      // A character was added — peek at the last typed index.
      final addedIndex = newValue.length - 1;
      _startPeek(addedIndex);
    } else {
      // Character deleted — cancel any active peek.
      _cancelPeek();
    }
    _previousPin = newValue;
  }

  /// Releases the timer. Call from your widget's `dispose()`.
  void disposePeekMixin() {
    _peekTimer?.cancel();
  }

  // ── private helpers ──────────────────────────────────────────────────────────

  void _startPeek(int index) {
    _peekTimer?.cancel();
    setState(() => _peekIndex = index);

    _peekTimer = Timer(peekDuration, () {
      if (mounted) {
        setState(() => _peekIndex = -1);
      }
    });
  }

  void _cancelPeek() {
    _peekTimer?.cancel();
    if (_peekIndex != -1) {
      setState(() => _peekIndex = -1);
    }
  }
}
