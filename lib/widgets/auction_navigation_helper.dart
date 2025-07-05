import 'package:flutter/material.dart';
import '../pages/auction_page.dart';

class AuctionNavigationHelper {
  static void navigateToAuction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuctionPage(),
      ),
    );
  }

  static Widget buildAuctionButton(BuildContext context, {
    String? label,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: () => navigateToAuction(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF4A90E2),
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel, size: 20),
            const SizedBox(width: 8),
            Text(
              label ?? 'View Live Auctions',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAuctionCard(BuildContext context, {
    String? title,
    String? subtitle,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: backgroundColor ?? const Color(0xFF1B263B),
      child: InkWell(
        onTap: () => navigateToAuction(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.gavel,
                size: 48,
                color: textColor ?? const Color(0xFF64B5F6),
              ),
              const SizedBox(height: 12),
              Text(
                title ?? 'Live Auctions',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? 'View and participate in active bidding',
                style: TextStyle(
                  color: (textColor ?? Colors.white).withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}