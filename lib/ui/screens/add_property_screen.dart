import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../providers/property_provider.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  PropertyStatus _status = PropertyStatus.forSale;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final price = double.parse(_price.text.trim());
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final property = Property(
      id: id,
      title: _title.text.trim(),
      address: _address.text.trim(),
      description: _description.text.trim(),
      price: price,
      status: _status,
      isUserAdded: true,
    );

    final result = await context.read<PropertyProvider>().addUserProperty(property);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    final message = result.info ?? 'Property saved';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Sunny 2-bedroom loft'),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 3) return 'Enter at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Address / area', hintText: 'City, neighborhood, street'),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Address is required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Price (INR)', hintText: '7850000'),
              validator: (v) {
                final t = v?.trim() ?? '';
                final n = double.tryParse(t);
                if (n == null) return 'Enter a valid number';
                if (n <= 0) return 'Price must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PropertyStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: PropertyStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                hintText: 'Highlights, amenities, availability…',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 10) return 'Write at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save property'),
            ),
          ],
        ),
      ),
    );
  }
}
