import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class TripCard extends StatelessWidget {
  final String origin;
  final String destination;
  final DateTime departureTime;
  final String agencyName;
  final double price;
  final int availableSeats;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.agencyName,
    required this.price,
    required this.availableSeats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(origin,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                            DateFormat('HH:mm').format(departureTime),
                            style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.white, size: 20),
                      Container(
                        height: 2,
                        width: 40,
                        color: AppColors.white.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(destination,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(DateFormat('EEE, d MMM').format(departureTime),
                            style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 4),
                  Text(agencyName,
                      style: const TextStyle(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_seat_rounded,
                            color: AppColors.secondary, size: 14),
                        const SizedBox(width: 4),
                        Text('$availableSeats seats',
                            style: const TextStyle(
                                color: AppColors.textMedium, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'XOF ${NumberFormat('#,###').format(price)}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
