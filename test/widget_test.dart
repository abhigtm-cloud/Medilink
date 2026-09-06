import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme and color tokens smoke test', (WidgetTester tester) async {
    final lightTheme = AppTheme.light;
    expect(lightTheme.brightness, equals(Brightness.light));
    expect(AppColors.primary, isNotNull);
    expect(AppColors.error, isNotNull);
  });
}
