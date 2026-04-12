import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_status.dart';
import '../../providers/property_provider.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/property_card.dart';
import 'add_property_screen.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold is called to be page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        actions: [
          IconButton(
            tooltip: 'Refresh from API',
            onPressed: () => context.read<PropertyProvider>().refreshFromApi(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
        },
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => context.read<PropertyProvider>().setSearchQuery(v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, area, or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          context.read<PropertyProvider>().setSearchQuery('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _StatusFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.allProperties.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.allProperties.isEmpty) {
                  return ErrorRetryView(
                    message: provider.errorMessage!,
                    onRetry: provider.retryAfterError,
                    showRetry: provider.errorRetryable,
                  );
                }

                final items = provider.visibleProperties;

                if (items.isEmpty) {
                  final noActiveFilters =
                      provider.searchQuery.trim().isEmpty && provider.statusFilter == null;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            noActiveFilters ? 'No listings yet' : 'No matches for your filters',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (provider.errorMessage != null && provider.allProperties.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'API note: ${provider.errorMessage}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: provider.retryAfterError,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry fetch'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<PropertyProvider>().refreshFromApi(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: items.length + (provider.errorMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (provider.errorMessage != null && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MaterialBanner(
                            content: Text('Could not refresh. ${provider.errorMessage}'),
                            leading: const Icon(Icons.warning_amber_rounded),
                            actions: [
                              TextButton(
                                onPressed: provider.retryAfterError,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      final i = provider.errorMessage != null ? index - 1 : index;
                      final p = items[i];
                      return PropertyCard(
                        property: p,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: provider.statusFilter == null,
                onSelected: (_) => provider.setStatusFilter(null),
              ),
              const SizedBox(width: 8),
              ...PropertyStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.displayLabel),
                    selected: provider.statusFilter == s,
                    onSelected: (_) => provider.setStatusFilter(s),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
