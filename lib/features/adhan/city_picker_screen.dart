import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';

class CityPickerResult {
  const CityPickerResult({
    required this.id,
    required this.name,
    required this.label,
    required this.country,
    required this.lat,
    required this.lng,
    this.timezone,
  });

  final String id;
  final String name;
  final String label;
  final String country;
  final double lat;
  final double lng;
  final String? timezone;
}

class _CityItem {
  const _CityItem({
    required this.id,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    this.timezone,
  });

  final String id;
  final String name;
  final String country;
  final double lat;
  final double lng;
  final String? timezone;

  String get label => '$name, $country';

  factory _CityItem.fromJson(Map<String, dynamic> json) {
    return _CityItem(
      id: (json['id'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      country: (json['country'] ?? '').toString().trim(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timezone: (json['tz'] ?? json['timezone'])?.toString(),
    );
  }
}

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_CityItem> _allCities = const [];
  List<_CityItem> _filteredCities = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/adhan/cities.json',
      );
      final decoded = jsonDecode(raw) as List<dynamic>;
      final cities = decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .map(_CityItem.fromJson)
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.name.isNotEmpty &&
                item.country.isNotEmpty,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allCities = const [];
        _filteredCities = const [];
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCities = _allCities);
      return;
    }
    setState(() {
      _filteredCities = _allCities
          .where(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                item.country.toLowerCase().contains(query),
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('prayer_times_choose_city'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.get('prayer_times_search_city'),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF7A746F),
                ),
                filled: true,
                fillColor: const Color(0xFFFDF9F6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Text(
                        S.get('prayer_times_loading'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF7A746F),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredCities.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Color(0x1A000000),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          title: Text(
                            city.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2B2725),
                            ),
                          ),
                          subtitle: Text(
                            city.country,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF7A746F),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(
                              CityPickerResult(
                                id: city.id,
                                name: city.name,
                                label: city.label,
                                country: city.country,
                                lat: city.lat,
                                lng: city.lng,
                                timezone: city.timezone,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
