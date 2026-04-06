import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Professional UI Components and Widgets for MEDILINK
class AppUIComponents {
  // ============ CARD COMPONENTS ============

  /// Professional card with consistent styling
  static Widget buildCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 16,
    VoidCallback? onTap,
    BoxBorder? border,
    List<BoxShadow>? shadows,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardLight,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: shadows ??
              [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: child,
      ),
    );
  }

  /// Gradient card with professional styling
  static Widget buildGradientCard({
    required Widget child,
    required Gradient gradient,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 16,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066CC).withAlpha(51),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ============ BUTTON COMPONENTS ============

  /// Professional primary button with full width option
  static Widget buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool fullWidth = true,
    bool isLoading = false,
    IconData? icon,
    double height = 56,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                  strokeWidth: 2,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Professional secondary (outline) button
  static Widget buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    bool fullWidth = true,
    IconData? icon,
    double height = 56,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Ghost button (text only)
  static Widget buildGhostButton({
    required String label,
    required VoidCallback onPressed,
    Color color = AppColors.primary,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============ INPUT COMPONENTS ============

  /// Professional text input field
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    bool obscureText = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixIconTap,
                    child: Icon(suffixIcon),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ============ HEADER COMPONENTS ============

  /// Professional screen header
  static Widget buildScreenHeader({
    required String title,
    String? subtitle,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }

  /// Professional list item card
  static Widget buildListItemCard({
    required Widget child,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
          if (showDivider)
            const Divider(
              height: 1,
              color: AppColors.dividerLight,
            ),
        ],
      ),
    );
  }

  /// Info banner for alerts/notices
  static Widget buildInfoBanner({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    VoidCallback? onClose,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(26),
        border: Border.all(color: backgroundColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: backgroundColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: backgroundColor,
              ),
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, color: backgroundColor, size: 18),
            ),
        ],
      ),
    );
  }

  /// Loading shimmer effect for skeleton screens
  static Widget buildShimmerLoader({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.dividerLight,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  /// Professional empty state widget
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.borderLight),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Badge widget for status indicators
  static Widget buildBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(51),
        border: Border.all(color: backgroundColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: backgroundColor,
        ),
      ),
    );
  }

  /// Horizontal divider with text
  static Widget buildDividerWithText({required String text}) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.dividerLight,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.dividerLight,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

