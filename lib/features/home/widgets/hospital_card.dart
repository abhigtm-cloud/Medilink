import 'package:flutter/material.dart';

/// Reusable hospital card widget similar to Zomato restaurant card design.
/// Features hospital image, name, address, type badge, rating, and action button.
class HospitalCard extends StatelessWidget {
  /// Hospital name to display
  final String hospitalName;

  /// Hospital address
  final String address;

  /// Hospital image URL
  final String imageUrl;

  /// Hospital rating (e.g., 4.5)
  final double rating;

  /// Hospital type badge (e.g., 'Public', 'Private')
  final String hospitalType;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when "View Doctors" button is pressed
  final VoidCallback? onViewDoctorsPressed;

  /// Distance from user location (optional)
  final String? distance;

  /// Average wait time (optional)
  final String? avgWaitTime;

  const HospitalCard({
    super.key,
    required this.hospitalName,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.hospitalType,
    this.onTap,
    this.onViewDoctorsPressed,
    this.distance,
    this.avgWaitTime,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Image with Rating Badge
              Stack(
                children: [
                  // Image Container
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: _buildImageWidget(),
                  ),
                  // Rating Badge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20B2AA),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Hospital Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital Name (Bold)
                    Text(
                      hospitalName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Hospital Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getHospitalTypeColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getHospitalTypeColor(),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        hospitalType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getHospitalTypeColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Distance and Wait Time Row
                    Row(
                      children: [
                        if (distance != null) ...[
                          Icon(
                            Icons.navigation_outlined,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (distance != null && avgWaitTime != null)
                          const SizedBox(width: 12),
                        if (avgWaitTime != null) ...[
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            avgWaitTime!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // View Doctors Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onViewDoctorsPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF20B2AA),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'View Doctors',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build image widget with network image and error handling
  Widget _buildImageWidget() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 40,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Get color based on hospital type
  Color _getHospitalTypeColor() {
    switch (hospitalType.toLowerCase()) {
      case 'public':
        return const Color(0xFF10B981); // Green
      case 'private':
        return const Color(0xFF3B82F6); // Blue
      case 'government':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
