import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_add_number_phone.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_review_and_confirm.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_date_and_seats.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_price_and_booking_type.dart';

/// Wizard with three slides:
///  0 → Date & Seats
///  1 → Price & Booking
///  2 → Phone & Submit
class TripCreateWizard extends StatefulWidget {
  const TripCreateWizard({super.key});

  @override
  State<TripCreateWizard> createState() => _TripCreateWizardState();
}

class _TripCreateWizardState extends State<TripCreateWizard> {
  late TripFrom _tripFrom;
  final _pageController = PageController();
  int _currentPage = 0;

  static const _totalSteps = 5; // map(1) + 4 wizard pages

  @override
  void initState() {
    super.initState();
    try {
      _tripFrom = Get.arguments as TripFrom;
    } catch (_) {
      _tripFrom = TripFrom();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _next() => _goToPage(_currentPage + 1);
  void _back() {
    if (_currentPage == 0) {
      Get.back();
    } else {
      _goToPage(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _WizardStepIndicator(
            currentStep: _currentPage + 2,
            totalSteps: _totalSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                TripSelectDateAndSeats(
                  tripFrom: _tripFrom,
                  onNext: (_) => _next(),
                ),
                TripSelectPriceAndBookingType(
                  tripFrom: _tripFrom,
                  onNext: (_) => _next(),
                  onBack: _back,
                ),
                TripAddNumberPhone(
                  tripFrom: _tripFrom,
                  isEmbedded: true,
                  onBack: _back,
                  onNext: (_) => _next(),
                ),
                TripReviewAndConfirm(
                  tripFrom: _tripFrom,
                  onBack: _back,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: MyColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward_ios_rounded,
            color: MyColors.primary, size: 20),
        onPressed: _back,
      ),
      title: Text("إضافة رحلة جديدة", style: AppTextStyles.titleMedium),
      centerTitle: true,
    );
  }
}

// ─── Step indicator ────────────────────────────────────────────────────────────

class _WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _WizardStepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "الخطوة $currentStep من $totalSteps",
            style: AppTextStyles.labelMedium
                .copyWith(color: MyColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: MyColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(MyColors.primary),
              minHeight: 5.h,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BlocProvider wrapper used by route_app.dart ────────────────────────────

/// Wrap [TripCreateWizard] with [PushRideCubit] at wizard level so all pages
/// can access it via `context.read`.
class TripCreateWizardProvider extends StatelessWidget {
  final PushRideCubit cubit;
  const TripCreateWizardProvider({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: const TripCreateWizard(),
    );
  }
}
