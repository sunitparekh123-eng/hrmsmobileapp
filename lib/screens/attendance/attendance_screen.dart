import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance.dart';
import '../../models/geo_location.dart';
import '../../widgets/common/common_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceStatus? _selectedStatusFilter;
  bool _showAllLogs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().initialize();
    });
  }

  void _showPunchResult(AttendanceProvider provider) {
    if (provider.punchResultMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(
          provider.punchResultMessage!,
          isError: provider.isPunchError,
        );
        provider.clearPunchMessage();
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return RefreshIndicator(
      onRefresh: () async => provider.initialize(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context),
            const SizedBox(height: 20),
            _buildGeoFenceBanner(provider),
            const SizedBox(height: 16),
            if (provider.isDisabledDay) ...[
              _buildDisabledDayBanner(provider),
              const SizedBox(height: 16),
            ],
            _buildLocationMap(provider),
            const SizedBox(height: 16),
            _buildPunchCard(provider),
            const SizedBox(height: 20),
            _buildMonthlySection(provider),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGE HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPageHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'GPS-based punch in/out with geo-fencing',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DISABLED DAY BANNER (Holiday / Weekend)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDisabledDayBanner(AttendanceProvider provider) {
    final reason = provider.disabledReason ?? 'Attendance is not required today';
    final isHoliday = reason.toLowerCase().contains('holiday');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHoliday
              ? [const Color(0xFFFEF3C7), const Color(0xFFFDE68A).withValues(alpha: 0.4)]
              : [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE).withValues(alpha: 0.4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHoliday
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isHoliday
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isHoliday ? Icons.celebration_rounded : Icons.weekend_rounded,
              color: isHoliday ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHoliday ? 'Public Holiday' : 'Weekend Off',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isHoliday ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isHoliday
                        ? const Color(0xFF92400E).withValues(alpha: 0.7)
                        : const Color(0xFF1E40AF).withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Punch in / out is disabled for today.',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isHoliday
                        ? const Color(0xFF92400E).withValues(alpha: 0.5)
                        : const Color(0xFF1E40AF).withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GEO-FENCE STATUS BANNER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGeoFenceBanner(AttendanceProvider provider) {
    final office = provider.selectedOffice;
    final isUnknown = provider.geoFenceStatus == GeoFenceStatus.unknown;
    final isInRange = provider.geoFenceStatus == GeoFenceStatus.withinRange;
    final distanceStr = GeoUtils.formatDistance(provider.currentDistance);

    // Unknown state — GPS still loading or no office data
    if (isUnknown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.gps_not_fixed,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acquiring Location…',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    office != null
                        ? 'Checking distance to ${office.name}…'
                        : 'Loading office data…',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final officeName = office?.name ?? 'Office';
    final radiusMeters = office?.radiusMeters.toInt() ?? 200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isInRange ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInRange
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isInRange
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isInRange ? Icons.location_on : Icons.location_off,
              color: isInRange ? AppColors.success : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInRange ? 'Within Geo-Fence' : 'Outside Geo-Fence',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isInRange ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isInRange
                      ? '$distanceStr from $officeName'
                      : '$distanceStr away — ${radiusMeters}m limit',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isInRange
                        ? AppColors.success.withValues(alpha: 0.8)
                        : AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOCATION MAP (Google Maps — lazy-loaded behind "View Map" button)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLocationMap(AttendanceProvider provider) {
    final office = provider.selectedOffice;
    final userLat = provider.currentLat;
    final userLon = provider.currentLon;
    final isInRange = provider.geoFenceStatus == GeoFenceStatus.withinRange;
    final distanceStr = GeoUtils.formatDistance(provider.currentDistance);

    // ── Off state: GPS still loading, no map shown ──
    if (provider.isLoadingLocation) {
      return _buildMapPlaceholder(
        icon: Icons.gps_fixed,
        iconColor: AppColors.info,
        title: 'Acquiring GPS Location…',
        subtitle: 'Please wait while we get your position',
        action: null,
      );
    }

    // ── Off state: GPS / permission error (no coords) ──
    if (provider.locationError != null && userLat == null) {
      return _buildMapPlaceholder(
        icon: Icons.gps_off_rounded,
        iconColor: AppColors.error,
        title: 'Location Unavailable',
        subtitle: provider.locationError!,
        action: OutlinedButton.icon(
          onPressed: () => provider.refreshLocation(),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry GPS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      );
    }

    // ── Off state: no office data ──
    if (office == null) {
      return _buildMapPlaceholder(
        icon: Icons.business_outlined,
        iconColor: AppColors.warning,
        title: 'Loading Office Data…',
        subtitle: 'Retrieving your office location',
        action: null,
      );
    }

    // ── Map not yet shown — "View Map" button ──
    if (!provider.showMap) {
      return _buildViewMapButton(provider, office, userLat, userLon,
          isInRange, distanceStr);
    }

    // ── Fetching API key ──
    if (provider.mapsState == GoogleMapsState.fetchingKey) {
      return _buildMapPlaceholder(
        icon: Icons.map_outlined,
        iconColor: AppColors.primary,
        title: 'Loading Map…',
        subtitle: 'Fetching Google Maps configuration',
        action: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    // ── Key missing ──
    if (provider.mapsState == GoogleMapsState.keyMissing) {
      return _buildMapPlaceholder(
        icon: Icons.vpn_key_off_rounded,
        iconColor: Colors.amber.shade700,
        title: 'Map Not Configured',
        subtitle: provider.mapsError ?? 'Google Maps API key is missing.',
        action: OutlinedButton.icon(
          onPressed: () => provider.hideMap(),
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Dismiss'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber.shade700,
            side: BorderSide(color: Colors.amber.shade700),
          ),
        ),
      );
    }

    // ── Error fetching key ──
    if (provider.mapsState == GoogleMapsState.error) {
      return _buildMapPlaceholder(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.error,
        title: 'Map Failed to Load',
        subtitle: provider.mapsError ?? 'An unexpected error occurred.',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => provider.fetchGoogleMapsKey(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => provider.hideMap(),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Dismiss'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ],
        ),
      );
    }

    // ── Key ready — render GoogleMap with overlays ──
    final centreLat = userLat ?? office.latitude;
    final centreLon = userLon ?? office.longitude;

    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('geo-fence'),
        center: LatLng(office.latitude, office.longitude),
        radius: office.radiusMeters,
        strokeColor: const Color(0xFF10B981), // emerald-500 matches web app
        strokeWidth: 2,
        fillColor: const Color(0xFF10B981).withValues(alpha: 0.1),
      ),
    };

    final Set<Marker> markers = {
      // Office marker (green dot — matches web app)
      Marker(
        markerId: const MarkerId('office'),
        position: LatLng(office.latitude, office.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: office.name,
          snippet:
              'Geo-fence: ${office.radiusMeters.toInt()}m radius',
        ),
      ),
      // Employee marker (red hue — matches web app #EF4444)
      if (userLat != null && userLon != null)
        Marker(
          markerId: const MarkerId('employee'),
          position: LatLng(userLat, userLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: '📍 You are here',
            snippet: 'Your current GPS location',
          ),
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map header bar
        _buildMapHeader(
          officeName: office.name,
          isInRange: isInRange,
          distanceStr: userLat != null ? distanceStr : 'GPS pending',
          onClose: () => provider.hideMap(),
        ),
        const SizedBox(height: 10),

        // Google Map container
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(centreLat, centreLon),
                    zoom: 15.5,
                  ),
                  circles: circles,
                  markers: markers,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) {
                    // Auto-fit bounds to show both office + employee
                    if (userLat != null && userLon != null) {
                      _fitBounds(controller, office, userLat, userLon);
                    }
                  },
                ),
                // Legend overlay (matches web app's bottom-left legend)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981),
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Geo-fence: ${office.radiusMeters.toInt()}m',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: "View Map" button (lazy-load trigger) ──
  Widget _buildViewMapButton(
    AttendanceProvider provider,
    OfficeLocation office,
    double? userLat,
    double? userLon,
    bool isInRange,
    String distanceStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Icon(Icons.map_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your Location → ${office.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: userLat == null
                    ? AppColors.surfaceSecondary
                    : isInRange
                        ? AppColors.successBg
                        : AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: userLat == null
                      ? AppColors.border
                      : isInRange
                          ? AppColors.success.withValues(alpha: 0.25)
                          : AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                userLat != null ? distanceStr : 'GPS pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: userLat == null
                      ? AppColors.textSecondary
                      : isInRange
                          ? AppColors.success
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // "View Map" button card
        InkWell(
          onTap: () => provider.fetchGoogleMapsKey(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBg,
                  AppColors.primaryBg.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View Map',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'See your location relative to office',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        AppColors.primaryDark.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: map header bar (with close button) ──
  Widget _buildMapHeader({
    required String officeName,
    required bool isInRange,
    required String distanceStr,
    required VoidCallback onClose,
  }) {
    return Row(
      children: [
        const Icon(Icons.map_outlined,
            size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your Location → $officeName',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isInRange ? AppColors.successBg : AppColors.errorBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isInRange
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.error.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            distanceStr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isInRange ? AppColors.success : AppColors.error,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: placeholder card for all non-map states ──
  Widget _buildMapPlaceholder({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  /// Auto-fit the map camera to show both office geo-fence and employee
  /// location, matching the web app's fitBounds behavior.
  void _fitBounds(
    GoogleMapController controller,
    OfficeLocation office,
    double userLat,
    double userLon,
  ) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(office.latitude, userLat),
        math.min(office.longitude, userLon),
      ),
      northeast: LatLng(
        math.max(office.latitude, userLat),
        math.max(office.longitude, userLon),
      ),
    );

    // Expand bounds to include the full geo-fence circle
    final latDelta =
        office.radiusMeters / 111320.0; // 1° lat ≈ 111.32 km
    final lngDelta = office.radiusMeters /
        (111320.0 * math.cos(office.latitude * math.pi / 180.0));

    final expandedBounds = LatLngBounds(
      southwest: LatLng(
        math.min(bounds.southwest.latitude, office.latitude - latDelta),
        math.min(
            bounds.southwest.longitude, office.longitude - lngDelta),
      ),
      northeast: LatLng(
        math.max(bounds.northeast.latitude, office.latitude + latDelta),
        math.max(
            bounds.northeast.longitude, office.longitude + lngDelta),
      ),
    );

    controller
        .animateCamera(CameraUpdate.newLatLngBounds(expandedBounds, 60));
  }

  // ═══════════════════════════════════════════════════════════════
  // PUNCH CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPunchCard(AttendanceProvider provider) {
    final canPunchIn = !provider.isCheckedIn || provider.isCheckedOut;
    final canPunchOut = provider.isCheckedIn && !provider.isCheckedOut;
    final isInRange = provider.geoFenceStatus == GeoFenceStatus.withinRange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBg,
            AppColors.primaryBg.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPunchStatusIcon(provider),
          const SizedBox(height: 12),

          // Status text
          Text(
            provider.isDisabledDay
                ? 'Day Off'
                : provider.isCheckedIn
                    ? (provider.isCheckedOut ? 'Day Complete' : 'Working...')
                    : 'Ready to Punch In',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (provider.isLateToday && !provider.isCheckedOut)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Late by ${provider.lateByMinutes} min',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ),



          const SizedBox(height: 16),

          _buildTimeRow(provider),
          if (provider.totalHoursToday != null) ...[
            const SizedBox(height: 12),
            _buildTotalHours(provider),
          ],

          const SizedBox(height: 20),

          // Punch buttons (only show when not checked out)
          if (!provider.isCheckedOut) ...[
            Row(
              children: [
                Expanded(
                  child: _punchButton(
                    label: !provider.isPunchInAllowed
                        ? 'OUTSIDE SHIFT'
                        : (canPunchIn ? 'PUNCH IN' : 'ALREADY IN'),
                    icon: Icons.login_rounded,
                    color: AppColors.success,
                    enabled: canPunchIn && isInRange && !provider.isPunching && provider.isPunchInAllowed,
                    isLoading: provider.isPunching && canPunchIn,
                    onTap: canPunchIn ? () => _handlePunchIn(provider) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _punchButton(
                    label: canPunchOut ? 'PUNCH OUT' : '—',
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                    enabled: canPunchOut && isInRange && !provider.isPunching && provider.isPunchOutAllowed,
                    isLoading: provider.isPunching && canPunchOut,
                    onTap: canPunchOut
                        ? () => _handlePunchOut(provider)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPunchStatusIcon(AttendanceProvider provider) {
    IconData icon;
    Color color;
    if (provider.isCheckedOut) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
    } else if (provider.isCheckedIn) {
      icon = Icons.timelapse_rounded;
      color = AppColors.info;
    } else {
      icon = Icons.fingerprint_rounded;
      color = AppColors.primary;
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }

  Widget _buildTimeRow(AttendanceProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeColumn('Check In', provider.formattedCheckIn,
            provider.formattedDistanceIn, AppColors.success),
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
          margin: const EdgeInsets.symmetric(horizontal: 28),
        ),
        _timeColumn('Check Out', provider.formattedCheckOut,
            provider.formattedDistanceOut, AppColors.error),
      ],
    );
  }

  Widget _timeColumn(
      String label, String time, String distance, Color color) {
    return Column(
      children: [
        Text(
          time,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          distance,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalHours(AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            'Total: ${provider.formattedTotalHours}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePunchIn(AttendanceProvider provider) async {
    await provider.punchIn();
    if (mounted) {
      _showPunchResult(provider);
    }
  }

  Future<void> _handlePunchOut(AttendanceProvider provider) async {
    await provider.punchOut();
    if (mounted) {
      _showPunchResult(provider);
    }
  }

  Widget _punchButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isLoading ? 'PROCESSING' : label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 13,
            ),
            maxLines: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 2 : 0,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY SECTION (summary + log)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMonthlySection(AttendanceProvider provider) {
    if (provider.isLoadingMonthly) {
      return _buildLoadingMonthly();
    }

    if (provider.monthlyError != null && provider.currentMonth == null) {
      return _buildMonthlyError(provider);
    }

    if (provider.currentMonth == null) {
      return _buildEmptyMonthly();
    }

    return Column(
      children: [
        _buildMonthlySummary(provider, provider.currentMonth!),
        const SizedBox(height: 20),
        _buildAttendanceLog(provider.currentMonth!),
      ],
    );
  }

  Widget _buildLoadingMonthly() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading attendance data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyError(AttendanceProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 32, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            provider.monthlyError ?? 'Failed to load',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => provider.refreshMonthly(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMonthly() {
    return const SizedBox.shrink();
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY SUMMARY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMonthlySummary(
      AttendanceProvider provider, MonthlyAttendance month) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'My Monthly Summary',
                subtitle: _getMonthName(month.month),
              ),
            ),
            if (provider.isLoadingMonthly)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                onPressed: () => provider.refreshMonthly(),
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(Icons.check_circle, 'Present',
                      month.presentDays.toString(), AppColors.success),
                  _statChip(Icons.warning_amber, 'Late',
                      month.lateDays.toString(), AppColors.warning),
                  _statChip(Icons.cancel, 'Absent',
                      month.absentDays.toString(), AppColors.error),
                  _statChip(Icons.hourglass_bottom, 'Half',
                      month.halfDays.toString(), AppColors.purple),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance %',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${month.attendancePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: month.attendancePercentage >= 90
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: month.attendancePercentage / 100,
                      backgroundColor: AppColors.borderLight,
                      color: month.attendancePercentage >= 90
                          ? AppColors.success
                          : AppColors.warning,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTENDANCE LOG
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAttendanceLog(MonthlyAttendance month) {
    final filteredRecords = month.records.where((record) {
      if (_selectedStatusFilter == null) return true;
      return record.status == _selectedStatusFilter;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayedRecords = _showAllLogs
        ? filteredRecords
        : filteredRecords.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Attendance Log'),
        const SizedBox(height: 10),
        _buildAttendanceFilterChips(),
        const SizedBox(height: 14),
        if (filteredRecords.isEmpty)
          _buildEmptyAttendanceState()
        else ...[
          ...displayedRecords.map((record) {
            final statusColor = switch (record.status) {
              AttendanceStatus.present => AppColors.success,
              AttendanceStatus.late => AppColors.warning,
              AttendanceStatus.absent => AppColors.error,
              AttendanceStatus.halfDay => AppColors.purple,
              _ => AppColors.textTertiary,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${record.date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.statusLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _getDayName(record.date.weekday),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.formattedCheckIn} - ${record.formattedCheckOut}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (filteredRecords.length > 5) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllLogs = !_showAllLogs;
                  });
                },
                icon: Icon(
                  _showAllLogs ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: Text(
                  _showAllLogs ? 'Show Less' : 'Show All (${filteredRecords.length})',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAttendanceFilterChips() {
    final filters = [
      (label: 'All', value: null),
      (label: 'Present', value: AttendanceStatus.present),
      (label: 'Late', value: AttendanceStatus.late),
      (label: 'Absent', value: AttendanceStatus.absent),
      (label: 'Half Day', value: AttendanceStatus.halfDay),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedStatusFilter == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatusFilter = filter.value;
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSecondary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyAttendanceState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'No attendance logs found for this filter',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}