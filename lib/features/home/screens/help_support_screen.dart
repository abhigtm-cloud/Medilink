import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';

/// Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'How do I book an appointment?',
              answer: 'Tap the "Search" tab, select a hospital, choose a doctor, pick a time slot, and confirm your booking.',
            ),
            _buildFAQItem(
              question: 'Can I cancel my booking?',
              answer: 'Yes! Go to "Bookings" tab, find your booking, and tap "Cancel Booking". You can cancel up to 2 hours before the appointment.',
            ),
            _buildFAQItem(
              question: 'How do I find hospitals near me?',
              answer: 'Tap the "Map" tab to see all hospitals on a map. Your location is marked with a blue dot.',
            ),
            _buildFAQItem(
              question: 'What if I forget my password?',
              answer: 'On the login screen, tap "Forgot Password?" and follow the steps to reset it via email.',
            ),
            _buildFAQItem(
              question: 'How do I edit my profile?',
              answer: 'Go to "Account" tab, tap "Edit Profile" and update your information.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@medilink.com',
              onTap: () => _sendEmail('support@medilink.com'),
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+1-800-MEDILINK',
              onTap: () => _makeCall('+18006334546'),
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'Chat Support',
              subtitle: 'Available 24/7',
              onTap: () => _showChatDialog(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Resources'),
            const SizedBox(height: 12),
            _buildResourceItem(
              icon: Icons.description_outlined,
              title: 'User Guide',
              subtitle: 'Learn how to use Medilink',
              onTap: () => _showResourceDialog('User Guide', 'User Guide coming soon'),
            ),
            _buildResourceItem(
              icon: Icons.security_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy terms',
              onTap: () => _showResourceDialog('Privacy Policy', 'Our privacy policy ensures your data is protected.'),
            ),
            _buildResourceItem(
              icon: Icons.article_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms of service',
              onTap: () => _showResourceDialog('Terms & Conditions', 'Our terms and conditions...'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Pro Tip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable notifications to get instant updates about your bookings and appointments!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Medilink Support Request'},
    );
    try {
      await launchUrl(emailUri);
    } catch (e) {

    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(callUri);
    } catch (e) {

    }
  }

  void _showChatDialog() {
    // You can integrate a chat service here

  }

  void _showResourceDialog(String title, String content) {
    // Show resource content in a dialog

  }
}
