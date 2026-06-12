import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/custom_date_picker.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/search_cubit.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/show_dialog_empty_search.dart';

class TripSearch extends StatefulWidget {
  const TripSearch({super.key});

  @override
  State<TripSearch> createState() => _TripSearchState();
}

class _TripSearchState extends State<TripSearch>
    with SingleTickerProviderStateMixin {
  String? sourceLat;
  String? sourceLng;
  String? sourceAddress;
  String? destLat;
  String? destLng;
  String? destAddress;
  DateTime? selectedDate;
  int seats = 1;

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _titleSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.25, 0.65, curve: Curves.easeOut)),
    );
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.25, 0.6, curve: Curves.easeIn)),
    );
    _cardSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOut)),
    );
    _cardFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.9, curve: Curves.easeIn)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(dt.year, dt.month, dt.day).difference(today).inDays;
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final day = '${dt.day} ${months[dt.month - 1]}';
    if (diff == 0) return 'اليوم، $day';
    if (diff == 1) return 'غداً، $day';
    return day;
  }

  void _validateAndSearch(BuildContext ctx) {
    if (sourceLat == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('اختر مكان الانطلاق')),
      );
      return;
    }
    if (destLat == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('اختر الوجهة')),
      );
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('اختر تاريخ الرحلة')),
      );
      return;
    }
    ctx.read<SearchCubit>().search(
          sourceLat!,
          sourceLng!,
          destLat!,
          destLng!,
          DateFormat('yyyy-MM-dd').format(selectedDate!),
          seats,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchCubit, SearchState>(
      listener: (context, state) {
        if (state is SearchSucces) {
          if (state.trips.isEmpty) {
            showNoTripsDialog(context);
          } else {
            Get.toNamed(RouteName.tripSearchList, arguments: state.trips);
          }
        }
        if (state is SearchErorr) {
          final msg = state.error.contains('verified as a passenger')
              ? 'يجب توثيق هويتك أولاً'
              : 'حدثت مشكلة، حاول مجدداً';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          if (state.error.contains('verified as a passenger')) {
            Get.toNamed(RouteName.verfiyUser, arguments: 'passanger');
          }
        }
      },
      child: Scaffold(
        backgroundColor: MyColors.background,
        body: Column(
          children: [
            // ━━ Header ━━
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MyColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
                  child: Column(
                    children: [
                      // Logo: scale + fade
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 90.w,
                            height: 90.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Title + subtitle: slide up + fade
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            children: [
                              Text(
                                'ابحث عن رحلة',
                                style: AppTextStyles.titleLarge
                                    .copyWith(color: MyColors.textOnDark),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'وين طريقك ؟',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: MyColors.textOnDark
                                        .withValues(alpha: 0.7)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ),

            // ━━ Search Card (يطفو فوق الـ header) ━━
            Expanded(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Transform.translate(
                      offset: Offset(0, -24.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _SearchCard(
                          sourceAddress: sourceAddress,
                          destAddress: destAddress,
                          selectedDate: selectedDate,
                          seats: seats,
                          formatDate: _formatDate,
                          onSourceTap: () async {
                            final result = await Get.toNamed(
                              RouteName.pickLocation,
                              arguments: {'type': 'source'},
                            );
                            if (result != null) {
                              setState(() {
                                sourceAddress = result['placeName'];
                                sourceLat = result['lat'];
                                sourceLng = result['lng'];
                              });
                            }
                          },
                          onDestTap: () async {
                            final result = await Get.toNamed(
                              RouteName.pickLocation,
                              arguments: {'type': 'destination'},
                            );
                            if (result != null) {
                              setState(() {
                                destAddress = result['placeName'];
                                destLat = result['lat'];
                                destLng = result['lng'];
                              });
                            }
                          },
                          onDateTap: () async {
                            final picked = await showAppDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          onSeatsChanged: (v) => setState(() => seats = v),
                          onSearch: () => _validateAndSearch(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Search Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SearchCard extends StatelessWidget {
  final String? sourceAddress;
  final String? destAddress;
  final DateTime? selectedDate;
  final int seats;
  final String Function(DateTime) formatDate;
  final VoidCallback onSourceTap;
  final VoidCallback onDestTap;
  final VoidCallback onDateTap;
  final ValueChanged<int> onSeatsChanged;
  final VoidCallback onSearch;

  _SearchCard({
    required this.sourceAddress,
    required this.destAddress,
    required this.selectedDate,
    required this.seats,
    required this.formatDate,
    required this.onSourceTap,
    required this.onDestTap,
    required this.onDateTap,
    required this.onSeatsChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ━━ الانطلاق ━━
          _LocationRow(
            icon: Icons.my_location_rounded,
            iconColor: MyColors.primary,
            hint: 'من أين تنطلق؟',
            value: sourceAddress,
            onTap: onSourceTap,
            isTop: true,
          ),

          Divider(height: 1, indent: 16.w, endIndent: 16.w),

          // ━━ الوجهة ━━
          _LocationRow(
            icon: Icons.location_on_rounded,
            iconColor: MyColors.accent,
            hint: 'إلى أين تتجه؟',
            value: destAddress,
            onTap: onDestTap,
            isTop: false,
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: const Divider(height: 1),
          ),

          // ━━ الركاب + التاريخ ━━
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                // التاريخ
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'التاريخ',
                    value: selectedDate != null
                        ? formatDate(selectedDate!)
                        : 'اختر التاريخ',
                    onTap: onDateTap,
                  ),
                ),
                SizedBox(width: 10.w),
                // الركاب
                Expanded(
                  child: _SeatsChip(
                    seats: seats,
                    onChanged: onSeatsChanged,
                  ),
                ),
              ],
            ),
          ),

          // ━━ زر البحث ━━
          Padding(
            padding:
                EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                final isLoading = state is SearchLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('بحث عن رحلة',
                            style: AppTextStyles.buttonLarge),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Location Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hint;
  final String? value;
  final VoidCallback onTap;
  final bool isTop;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.value,
    required this.onTap,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isTop
          ? BorderRadius.vertical(top: Radius.circular(20.r))
          : BorderRadius.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value ?? hint,
                    style: value != null
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium
                            .copyWith(color: MyColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (value != null)
                    Text(hint,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: MyColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_rounded,
                size: 14, color: MyColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Info Chip (التاريخ)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: MyColors.background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: MyColors.primary),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textSecondary)),
                  SizedBox(height: 2.h),
                  Text(value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: MyColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Seats Chip (الركاب)
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SeatsChip extends StatelessWidget {
  final int seats;
  final ValueChanged<int> onChanged;

  const _SeatsChip({required this.seats, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, size: 16, color: MyColors.primary),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الركاب',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textSecondary)),
                SizedBox(height: 2.h),
                Text('$seats راكب',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textPrimary)),
              ],
            ),
          ),
          // ━━ - و + ━━
          GestureDetector(
            onTap: () { if (seats > 1) onChanged(seats - 1); },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: MyColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: MyColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.remove, size: 12, color: MyColors.primary),
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () { if (seats < 8) onChanged(seats + 1); },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: MyColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
