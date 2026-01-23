import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

/// Complete Air Menu Screen - Hub for all airtime, data, and telecom services
/// Gen Z aesthetic with modern cards, animations, and intuitive navigation
class AirMenuScreen extends StatefulWidget {
  const AirMenuScreen({super.key});

  @override
  State<AirMenuScreen> createState() => _AirMenuScreenState();
}

class _AirMenuScreenState extends State<AirMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedCategory = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // All services data for filtering
  late List<_ServiceItem> _allServices;

  final List<_ServiceCategory> _categories = [
    _ServiceCategory(
      name: 'All',
      icon: Icons.apps_rounded,
    ),
    _ServiceCategory(
      name: 'Airtime',
      icon: Icons.phone_android_rounded,
    ),
    _ServiceCategory(
      name: 'Data',
      icon: Icons.wifi_rounded,
    ),
    _ServiceCategory(
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
    ),
    _ServiceCategory(
      name: 'Convert',
      icon: Icons.swap_horiz_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _initializeServices();
  }

  void _initializeServices() {
    _allServices = [
      // Airtime Services
      _ServiceItem(
        icon: Icons.signal_cellular_alt_rounded,
        title: 'International Airtime',
        subtitle: 'Send airtime to 150+ countries',
        gradient: AppColors.primaryGradient,
        category: 'Airtime',
        onTap: () => context.push('/airtime/select-country'),
      ),
      _ServiceItem(
        icon: Icons.phone_in_talk_rounded,
        title: 'Local Airtime',
        subtitle: 'Quick top-up for Ghana networks',
        gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
        category: 'Airtime',
        onTap: () => context.push('/airtime/select-country'),
      ),
      _ServiceItem(
        icon: Icons.schedule_rounded,
        title: 'Auto Recharge',
        subtitle: 'Schedule recurring top-ups',
        gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
        category: 'Airtime',
        isNew: true,
        onTap: () => _showComingSoon(context, 'Auto Recharge'),
      ),
      // Data Services
      _ServiceItem(
        icon: Icons.wifi_rounded,
        title: 'Data Bundles',
        subtitle: 'High-speed data packages',
        gradient: AppColors.secondaryGradient,
        category: 'Data',
        onTap: () => context.push('/data/select-country'),
      ),
      _ServiceItem(
        icon: Icons.router_rounded,
        title: 'MiFi/Router Data',
        subtitle: 'Data for portable hotspots',
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        category: 'Data',
        onTap: () => _showComingSoon(context, 'MiFi Data'),
      ),
      _ServiceItem(
        icon: Icons.nights_stay_rounded,
        title: 'Night Bundles',
        subtitle: 'Affordable midnight data',
        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
        category: 'Data',
        onTap: () => _showComingSoon(context, 'Night Bundles'),
      ),
      // Convert Services
      _ServiceItem(
        icon: Icons.swap_horiz_rounded,
        title: 'Airtime to Cash',
        subtitle: 'Convert airtime to mobile money',
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        category: 'Convert',
        isNew: true,
        onTap: () => context.push('/airtime/converter'),
      ),
      _ServiceItem(
        icon: Icons.send_rounded,
        title: 'Airtime Transfer',
        subtitle: 'Send airtime to other numbers',
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        category: 'Convert',
        onTap: () => _showComingSoon(context, 'Airtime Transfer'),
      ),
      _ServiceItem(
        icon: Icons.card_giftcard_rounded,
        title: 'Gift Airtime',
        subtitle: 'Send airtime as a gift',
        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        category: 'Convert',
        onTap: () => _showComingSoon(context, 'Gift Airtime'),
      ),
      // Bills Services
      _ServiceItem(
        icon: Icons.bolt_rounded,
        title: 'Electricity',
        subtitle: 'Pay ECG, NEDCO bills',
        gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
        category: 'Bills',
        onTap: () => _showComingSoon(context, 'Electricity Bills'),
      ),
      _ServiceItem(
        icon: Icons.water_drop_rounded,
        title: 'Water',
        subtitle: 'Pay water utility bills',
        gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
        category: 'Bills',
        onTap: () => _showComingSoon(context, 'Water Bills'),
      ),
      _ServiceItem(
        icon: Icons.tv_rounded,
        title: 'TV Subscription',
        subtitle: 'DSTV, GOtv, StarTimes',
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        category: 'Bills',
        onTap: () => _showComingSoon(context, 'TV Subscription'),
      ),
    ];
  }

  List<_ServiceItem> get _filteredServices {
    List<_ServiceItem> services = _allServices;
    
    // Filter by category
    if (_selectedCategory > 0) {
      final categoryName = _categories[_selectedCategory].name;
      services = services.where((s) => s.category == categoryName).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      services = services.where((s) =>
        s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.subtitle.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return services;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategoryTabs(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeaturedServices(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAllServices(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPromoSection(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _isSearching ? _closeSearch() : context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _isSearching ? Icons.close_rounded : Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _isSearching
                        ? _buildSearchField()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Air Services',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                'Airtime • Data • Bills • Convert',
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                              ),
                            ],
                          ),
                  ),
                  if (!_isSearching)
                    GestureDetector(
                      onTap: _openSearch,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    context,
                    icon: Icons.bolt_rounded,
                    label: 'Instant',
                    value: 'Delivery',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    icon: Icons.public_rounded,
                    label: '150+',
                    value: 'Countries',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    icon: Icons.verified_rounded,
                    label: 'Secure',
                    value: 'Payments',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
        cursorColor: isDark ? Colors.white : Colors.black87,
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white : Colors.black54, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.asMap().entries.map((entry) {
            final isSelected = entry.key == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppShadows.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.value.icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildFeaturedServices(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Popular',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: HeroServiceCard(
                  icon: Icons.signal_cellular_alt_rounded,
                  title: 'Buy Airtime',
                  subtitle: 'Instant top-up worldwide',
                  gradient: AppColors.primaryGradient,
                  promoText: 'Popular',
                  onTap: () => context.push('/airtime/select-country'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: HeroServiceCard(
                  icon: Icons.wifi_rounded,
                  title: 'Data Bundles',
                  subtitle: 'High-speed internet',
                  gradient: AppColors.secondaryGradient,
                  onTap: () => context.push('/data/select-country'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                ServiceCard(
                  icon: Icons.phone_android_rounded,
                  title: 'Airtime',
                  gradient: AppColors.primaryGradient,
                  isCompact: true,
                  isPopular: true,
                  onTap: () => context.push('/airtime/select-country'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ServiceCard(
                  icon: Icons.wifi_rounded,
                  title: 'Data',
                  gradient: AppColors.secondaryGradient,
                  isCompact: true,
                  onTap: () => context.push('/data/select-country'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ServiceCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Convert',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  isCompact: true,
                  isNew: true,
                  onTap: () => context.push('/airtime/converter'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ServiceCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Gift',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  isCompact: true,
                  onTap: () => _showComingSoon(context, 'Gift Airtime'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ServiceCard(
                  icon: Icons.history_rounded,
                  title: 'History',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  isCompact: true,
                  onTap: () => context.push('/transactions'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ServiceCard(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  isCompact: true,
                  onTap: () => _showComingSoon(context, 'Favorites'),
                ),
                const SizedBox(width: AppSpacing.lg), // End padding
              ],
            ),
          ),
      ],
    ),
  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAllServices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = _filteredServices;
    
    // Group services by category for display
    final airtimeServices = services.where((s) => s.category == 'Airtime').toList();
    final dataServices = services.where((s) => s.category == 'Data').toList();
    final convertServices = services.where((s) => s.category == 'Convert').toList();
    final billsServices = services.where((s) => s.category == 'Bills').toList();
    
    // Check if we're filtering or searching
    final isFiltering = _selectedCategory > 0 || _searchQuery.isNotEmpty;
    
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No services found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try a different search term'
                  : 'No services in this category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFiltering ? 'Search Results' : 'All Services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (isFiltering)
                Text(
                  '${services.length} found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Show filtered results or grouped sections
          if (isFiltering)
            ...services.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ServiceCard(
                icon: service.icon,
                title: service.title,
                subtitle: service.subtitle,
                gradient: service.gradient,
                isNew: service.isNew,
                onTap: service.onTap,
              ),
            ))
          else ...[
            // Airtime Services
            if (airtimeServices.isNotEmpty)
              _buildServiceSection(context, title: 'Airtime & Recharge', services: airtimeServices),
            if (airtimeServices.isNotEmpty) const SizedBox(height: AppSpacing.lg),
            // Data Services
            if (dataServices.isNotEmpty)
              _buildServiceSection(context, title: 'Internet Data', services: dataServices),
            if (dataServices.isNotEmpty) const SizedBox(height: AppSpacing.lg),
            // Convert & Transfer
            if (convertServices.isNotEmpty)
              _buildServiceSection(context, title: 'Convert & Transfer', services: convertServices),
            if (convertServices.isNotEmpty) const SizedBox(height: AppSpacing.lg),
            // Bills & Utilities
            if (billsServices.isNotEmpty)
              _buildServiceSection(context, title: 'Bills & Utilities', services: billsServices),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildServiceSection(
    BuildContext context, {
    required String title,
    required List<_ServiceItem> services,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...services.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ServiceCard(
                icon: service.icon,
                title: service.title,
                subtitle: service.subtitle,
                gradient: service.gradient,
                isNew: service.isNew,
                onTap: service.onTap,
              ),
            )),
      ],
    );
  }

  Widget _buildPromoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassmorphicCard(
        blur: 15,
        opacity: 0.1,
        showGlow: true,
        gradientColors: [
          AppColors.primary,
          AppColors.secondary,
        ],
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      '🎉 LIMITED OFFER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Get 15% Bonus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'On your first international airtime purchase',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  void _showComingSoon(BuildContext context, String feature) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Coming Soon!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$feature is launching soon.\nWe\'ll notify you when it\'s ready!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ServiceCategory {
  final String name;
  final IconData icon;

  _ServiceCategory({required this.name, required this.icon});
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final String category;
  final VoidCallback? onTap;
  final bool isNew;

  _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.category = 'All',
    this.onTap,
    this.isNew = false,
  });
}
