import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../data/models/api_models.dart';
import '../../../../data/models/fallback_countries.dart';
import '../../../../data/datasources/api_client.dart';
import '../../../providers/airtime_wizard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class SelectCountryScreen extends ConsumerStatefulWidget {
  const SelectCountryScreen({super.key});

  @override
  ConsumerState<SelectCountryScreen> createState() => _SelectCountryScreenState();
}

class _SelectCountryScreenState extends ConsumerState<SelectCountryScreen> {
  final _searchController = TextEditingController();
  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiClient = ref.read(apiClientProvider);
      final httpResponse = await apiClient.getCountriesRaw();
      final rawResponse = httpResponse.data;

      // Parse the raw list response
      final countries = <Country>[];
      if (rawResponse is! List) {
        throw Exception('Unexpected response format');
      }
      for (var item in rawResponse) {
        try {
          if (item is Map<String, dynamic>) {
            final country = Country.fromJson(item);
            countries.add(country);
          }
        } catch (e) {
          print('⚠️ Failed to parse country: $e');
        }
      }

      // Debug logging
      print('🔍 Countries Response - Parsed ${countries.length} countries');

      if (countries.isNotEmpty) {
        // Sort alphabetically
        countries.sort((a, b) => a.name.compareTo(b.name));
        
        setState(() {
          _countries = countries;
          _filteredCountries = _countries;
          _isLoading = false;
        });
        print('✅ Loaded ${_countries.length} countries successfully');
        
        // Auto-select user's country
        _autoSelectUserCountry(countries);
      } else {
        setState(() {
          _error = 'No countries available. Please try again later.';
          _isLoading = false;
        });
        print('⚠️ Countries list is empty');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading countries from API: $e');
      print('Using fallback countries list');
      
      // Use fallback countries
      setState(() {
        _countries = fallbackCountries;
        _filteredCountries = fallbackCountries;
        _isLoading = false;
        _error = null;
      });
      
      // Auto-select user's country from fallback
      _autoSelectUserCountry(fallbackCountries);
    }
  }

  void _autoSelectUserCountry(List<Country> countries) {
    // Get user's country from current user provider
    final userAsync = ref.read(currentUserProvider);
    final userCountry = userAsync.valueOrNull?.country?.toUpperCase();
    
    Country? selectedCountry;
    
    if (userCountry != null && userCountry.isNotEmpty) {
      // Try to find user's country by name or code
      selectedCountry = countries.where((c) => 
        c.code.toUpperCase() == userCountry ||
        c.name.toUpperCase() == userCountry
      ).firstOrNull;
    }
    
    // Fallback to Ghana if user's country not found
    selectedCountry ??= countries.where((c) => c.code == 'GH').firstOrNull;
    
    if (selectedCountry != null) {
      ref.read(airtimeWizardProvider.notifier).selectCountry(selectedCountry);
      print('🌍 Auto-selected country: ${selectedCountry.name}');
      
      // Move selected country to top of list
      _moveSelectedCountryToTop(selectedCountry);
    }
  }

  void _moveSelectedCountryToTop(Country selectedCountry) {
    setState(() {
      // Remove selected country from current position
      _countries.removeWhere((c) => c.code == selectedCountry.code);
      // Insert at the beginning
      _countries.insert(0, selectedCountry);
      // Update filtered list
      _filteredCountries = List.from(_countries);
    });
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries.where((country) {
          return country.name.toLowerCase().contains(query.toLowerCase()) ||
              country.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _selectCountry(Country country) {
    ref.read(airtimeWizardProvider.notifier).selectCountry(country);
    context.push('/airtime/enter-phone');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(airtimeWizardProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressIndicator(context, 0),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Select Country',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    final steps = ['Country', 'Network', 'Phone', 'Amount', 'Confirm'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: stepBefore < currentStep
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 2,
                  ),
                  boxShadow: isCurrent ? AppShadows.softGlow(AppColors.primary) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose the country for airtime topup',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSearchBar(context),
            ],
          ),
        ),
        Expanded(
          child: _filteredCountries.isEmpty
              ? Center(
                  child: Text(
                    'No countries found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final selectedCountryCode = ref.watch(airtimeWizardProvider).selectedCountry?.code;
                    return _CountryCard(
                      country: country,
                      isSelected: selectedCountryCode == country.code,
                      onTap: () => _selectCountry(country),
                    ).animate(delay: Duration(milliseconds: 20 * index)).fadeIn().slideX(begin: 0.05, end: 0);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCountries,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search countries...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextMuted : Colors.black54,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextMuted : Colors.black54,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? AppColors.darkTextMuted : Colors.black54,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterCountries('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ?? 'Something went wrong',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadCountries,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryCard({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  String _getCallingCode() {
    if (country.callingCodes != null && country.callingCodes!.isNotEmpty) {
      // Remove "+" if present, then add it back to ensure single "+"
      final code = country.callingCodes!.first.replaceFirst(RegExp(r'^\+'), '');
      return '+$code';
    }
    // Fallback
    final codes = {
      'NG': '+234',
      'GH': '+233',
      'KE': '+254',
      'ZA': '+27',
    };
    return codes[country.code] ?? '+234';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final callingCode = _getCallingCode();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.softGlow(AppColors.primary) : AppShadows.xs,
        ),
        child: Row(
          children: [
            // Flag image
            CountryFlagWidget(
              flagUrl: country.flag,
              countryCode: country.code,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            // Country info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        callingCode,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        country.code,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
          ],
        ),
      ),
    );
  }
}

