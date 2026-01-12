import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class CountryFlagWidget extends StatelessWidget {
  final String flagUrl;
  final String countryCode;
  final double size;
  final BoxFit fit;

  const CountryFlagWidget({
    super.key,
    required this.flagUrl,
    required this.countryCode,
    this.size = 48,
    this.fit = BoxFit.cover,
  });

  /// Get a CORS-friendly flag URL using flagcdn.com
  /// This works reliably on both web and mobile
  String _getFlagCdnUrl() {
    final code = countryCode.toLowerCase().trim();
    if (code.isEmpty || code.length < 2) return '';
    
    // Use flagcdn.com which has proper CORS headers
    // w80 = 80px wide (good quality for our sizes)
    return 'https://flagcdn.com/w80/${code.substring(0, 2)}.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _buildFlagContent(isDark),
      ),
    );
  }

  Widget _buildFlagContent(bool isDark) {
    final fallback = _fallback(isDark);
    final code = countryCode.trim();
    
    if (code.isEmpty) return fallback;

    // Use flagcdn.com for reliable cross-platform flag loading
    // It has proper CORS headers and works on web
    final flagCdnUrl = _getFlagCdnUrl();
    
    if (flagCdnUrl.isNotEmpty) {
      return Image.network(
        flagCdnUrl,
        fit: fit,
        errorBuilder: (_, __, ___) {
          // If flagcdn fails, try the original URL on mobile
          if (!kIsWeb && flagUrl.isNotEmpty) {
            return _loadOriginalFlag(isDark);
          }
          return fallback;
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildLoadingIndicator(isDark);
        },
      );
    }

    // Fallback to original URL (for non-standard country codes)
    return _loadOriginalFlag(isDark);
  }

  Widget _loadOriginalFlag(bool isDark) {
    final fallback = _fallback(isDark);
    final url = flagUrl.trim();
    
    if (url.isEmpty) return fallback;

    final lower = url.toLowerCase();

    if (lower.endsWith('.svg') && !kIsWeb) {
      // SVG only on mobile (CORS issues on web)
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (_) => fallback,
      );
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildLoadingIndicator(isDark);
      },
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: SizedBox(
        width: size * 0.35,
        height: size * 0.35,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _fallback(bool isDark) {
    final text = countryCode.length > 2 
        ? countryCode.substring(0, 2).toUpperCase() 
        : countryCode.toUpperCase();

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightBg,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
