import 'package:flutter/material.dart';
import 'app_state.dart';

String tr(BuildContext context, String thText, String enText) {
  final appState = AppStateProvider.of(context);
  return appState.isEnglish ? enText : thText;
}
