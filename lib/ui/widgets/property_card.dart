import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../models/property_status.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property, required this.onTap});

  /// data to display (title, address, price, status, etc.)
  final Property property;

  /// what to do when user taps the card (in app it opens PropertyDetailScreen)
  final VoidCallback onTap;

  /// this helper turns price formatting (INR)
  static String _formatInr(double value) {
    final n = value.round();
    final neg = n < 0;
    final s = n.abs().toString();
    final parts = <String>[];
    var i = s.length;
    var first = true;
    while (i > 0) {
      final take = first ? (i >= 3 ? 3 : i) : (i >= 2 ? 2 : i);
      first = false;
      parts.insert(0, s.substring(i - take, i));
      i -= take;
    }
    return '${neg ? '-' : ''}₹${parts.join(',')}';

    /// returns formatted price string like "₹1,23,456"
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(scheme, property.status);

    /// color based on status (primary for sale, outline for sold, tertiary for pending)

    /// a card with InkWell for tap effect, padding, and row layout
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// display property type icon (home_work_outlined) in a circle
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.home_work_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// title + optional "user-added" icon, address, then status pill + price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property.isUserAdded)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.bookmark_added_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            property.status.displayLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: statusColor),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatInr(property.price),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
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

  /// helper to get color based on status (primary for sale, outline for sold, tertiary for pending)
  Color _statusColor(ColorScheme scheme, PropertyStatus s) {
    return switch (s) {
      PropertyStatus.forSale => scheme.primary,
      PropertyStatus.sold => scheme.outline,
      PropertyStatus.pending => scheme.tertiary,
    };
  }
}
