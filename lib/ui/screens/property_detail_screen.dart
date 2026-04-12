import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../models/property_status.dart';

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

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
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.home_work_outlined, size: 56, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(property.title, style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (property.isUserAdded)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    avatar: Icon(Icons.edit_note, size: 18, color: scheme.primary),
                    label: const Text('Yours'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(property.address, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(property.status.displayLabel)),
              Chip(label: Text(_formatInr(property.price))),
            ],
          ),
          const SizedBox(height: 16),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(property.description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
