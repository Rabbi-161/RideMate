import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onViewRide;
  final bool isRequested;

  const RideCard({
    super.key,
    required this.ride,
    required this.onViewRide,
    this.isRequested = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFull = ride.availableSeats <= 0;

    return StreamBuilder<User?>(
      stream: UserService().getUserProfileStream(ride.hostId),
      builder: (context, userSnap) {
        final profile = userSnap.data;
        final hostName = (profile?.name.trim().isNotEmpty == true)
            ? profile!.name.trim()
            : (ride.hostName.isNotEmpty ? ride.hostName : 'Ride Host');
        final rawPhone = (profile?.phone.trim().isNotEmpty == true)
            ? profile!.phone.trim()
            : ride.hostPhone.trim();
        final hostPhone = rawPhone.isNotEmpty && rawPhone != 'Phone number not available'
            ? rawPhone
            : 'Phone number not available';
        final hostAvatar = (profile?.avatarInitials.isNotEmpty == true)
            ? profile!.avatarInitials
            : (ride.hostAvatar.isNotEmpty
                ? ride.hostAvatar
                : (hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H'));

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isRequested
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : AppTheme.borderColor,
              width: isRequested ? 1.5 : 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Host Name & Phone, Match Status / Requested Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        hostAvatar,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Host Name (from Firestore users/{uid})
                          Text(
                            hostName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Host Phone Number (from Firestore users/{uid})
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hostPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: hostPhone != 'Phone number not available'
                                        ? AppTheme.textSecondary
                                        : AppTheme.textMuted,
                                    fontStyle: hostPhone == 'Phone number not available'
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Match Status or Requested Badge
                    Wrap(
                      spacing: 6,
                      children: [
                        if (isRequested)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.successColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: AppTheme.successColor,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Requested',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFull
                                ? Colors.grey.shade100
                                : AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFull
                                  ? Colors.grey.shade300
                                  : AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isFull ? 'Full' : ride.matchStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFull ? AppTheme.textMuted : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Route visual representation: From -> To (Railway Stop style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FROM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.fromLocation.displayText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'TO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.toLocation.displayText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date & Time row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ride.date,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ride.time,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Available seats
                Row(
                  children: [
                    Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 16,
                      color: isFull ? AppTheme.textMuted : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isFull
                            ? 'No seats remaining'
                            : '${ride.availableSeats} ${ride.availableSeats == 1 ? "seat" : "seats"} available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFull ? AppTheme.textMuted : AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // View Ride / Request to Join Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onViewRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRequested
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      foregroundColor: isRequested
                          ? AppTheme.primaryColor
                          : Colors.white,
                      elevation: 0,
                      side: isRequested
                          ? const BorderSide(color: AppTheme.primaryColor)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isRequested
                          ? 'View Ride (Requested)'
                          : 'View Ride / Request to Join',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
