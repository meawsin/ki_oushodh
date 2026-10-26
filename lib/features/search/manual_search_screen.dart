// lib/features/search/manual_search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../results/results_screen.dart';
import '../scanner/scanner_viewmodel.dart';

class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<ScanResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  static const List<String> _popularChips = [
    'Napa',
    'Seclo',
    'Maxpro',
    'Sergel',
    'Ace',
    'Entacyd',
    'Paracetamol',
    'Omeprazole',
    'Montelukast',
    'Azithromycin',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    final language = ref.read(languageProvider);
    final searchService = ref.read(llmServiceProvider);

    try {
      final matches = await searchService.searchOffline(clean, language);
      if (mounted) {
        setState(() {
          _results = matches;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    }
  }

  void _onSelectResult(ScanResult result) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ResultsScreen(result: result),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);
    final isQueryEmpty = _searchController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: cs.onSurfaceVariant, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == 'bn' ? 'ওষুধ অনুসন্ধান' : 'Search Medicines',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          language == 'bn'
                              ? '১৩,৯২৯টি ওষুধ · সম্পূর্ণ অফলাইন'
                              : '13,929 Medicines · 100% Offline',
                          style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Input Box ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus: false,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: language == 'bn'
                        ? 'ওষুধের নাম লিখুন (যেমন: Napa, Seclo)...'
                        : 'Search brand or generic (e.g. Napa, Seclo)...',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: cs.onSurfaceVariant, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // ── Suggestions or Results List ──────────────────────────────
            Expanded(
              child: isQueryEmpty
                  ? _buildEmptyPrompt(cs, language)
                  : _isSearching
                      ? Center(
                          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
                        )
                      : _results.isEmpty
                          ? _buildNoResultsFound(cs, language)
                          : _buildResultsList(cs, language),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt(ColorScheme cs, String language) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: cs.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                language == 'bn' ? 'জনপ্রিয় ওষুধসমূহ' : 'Popular Medicines',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _popularChips.map((name) {
              return Material(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _searchController.text = name;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: name.length),
                    );
                    _performSearch(name);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.offline_pin_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language == 'bn' ? 'ইন্টারনেট ছাড়াই অনুসন্ধান' : 'Completely Offline',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language == 'bn'
                            ? 'ক্যামেরা স্ক্যানের বিকল্প হিসেবে যে কোনো ব্র্যান্ড বা জেনেরিক নাম লিখে তাৎক্ষণিক তথ্য জানুন।'
                            : 'Look up any Bangladeshi brand or generic name instantly without internet connectivity.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound(ColorScheme cs, String language) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6), size: 48),
            const SizedBox(height: 14),
            Text(
              language == 'bn' ? 'কোনো ওষুধ পাওয়া যায়নি' : 'No medicines found',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              language == 'bn'
                  ? 'বানান সঠিক আছে কিনা দেখুন অথবা জেনেরিক নাম দিয়ে খুঁজুন।'
                  : 'Check your spelling or try searching by active generic ingredient.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ColorScheme cs, String language) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _onSelectResult(item),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medication_rounded, color: cs.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.medicineName,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (item.category != null && item.category!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category!,
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.genericName,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.summary,
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
