import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class AdvisoryIntelligenceScreen extends StatefulWidget {
  const AdvisoryIntelligenceScreen({super.key});

  @override
  State<AdvisoryIntelligenceScreen> createState() =>
      _AdvisoryIntelligenceScreenState();
}

class _AdvisoryIntelligenceScreenState
    extends State<AdvisoryIntelligenceScreen> {
  final PageController _offeringsController = PageController(
    viewportFraction: 0.82,
  );
  int _currentOfferingIndex = 0;

  final PageController _plansController = PageController(
    viewportFraction: 0.85,
  );
  int _currentPlanIndex = 0;

  final PageController _reviewsController = PageController();
  int _currentReviewIndex = 0;

  final List<Map<String, String>> _reviews = [
    {
      "name": "Kaushik,30",
      "review":
          "My experience has been great with Pivot money so far, I was able to link my MF investments easily, understand my fund performance, got brilliant insights. Really helpful app.",
    },
    {
      "name": "Ritesh Sunil Doshi,27",
      "review":
          "Best app to track your net worth. You get all your bank bal, investments in shares and mutual funds, insurance in one place. Kudos to developers for launching this app. Area for improvement is to link bank accounts with joint holders.",
    },
    {
      "name": "Dimpy Gandhi,25",
      "review":
          "Really useful app Love it! All my investments and bank balance in one screen. Super easy to check my net worth now. Was worried about security at first but they have bank level protection so it's safe. Saves me so much time.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      // appBar: AppBar(
      //   surfaceTintColor: Colors.transparent,
      //   backgroundColor: Colors.transparent,
      //   automaticallyImplyLeading: false,
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       GestureDetector(
      //         onTap: () => Get.back(),
      //         child: Container(
      //           padding: const EdgeInsets.all(8),
      //           decoration: const BoxDecoration(
      //             color: AppColors.darkCardBG,
      //             shape: BoxShape.circle,
      //           ),
      //           child: const Icon(
      //             Icons.chevron_left,
      //             color: Colors.white,
      //             size: 20,
      //           ),
      //         ),
      //       ),
      //       AppText(
      //         "Advisory Intelligence",
      //         variant: AppTextVariant.headline6,
      //         weight: AppTextWeight.semiBold,
      //       ),
      //       const Opacity(
      //         opacity: 0,
      //         child: Icon(Icons.chevron_left, size: 32),
      //       ),
      //     ],
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildOurOfferingsSection(),
            const SizedBox(height: 12),
            _buildFounderAdvisorSection(context),
            const SizedBox(height: 48),
            _buildPopularPlansSection(),
            const SizedBox(height: 48),
            _buildReturningToIndiaSection(),
            const SizedBox(height: 48),
            _buildBuiltForGlobalIndiansSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOurOfferingsSection() {
    final List<Map<String, String>> offerings = [
      {
        'title': 'US–India Tax Planning',
        'desc':
            'DTAA structuring. Capital gains mapping. Reporting compliance.',
      },
      {
        'title': 'Return to India Planning (2026 Ready)',
        'desc': 'RNOR strategy. Asset restructuring before move.',
      },
      {
        'title': 'NRE / NRO Optimisation',
        'desc': 'Repatriation strategy. Interest taxation review.',
      },
      {
        'title': 'Mutual Fund & Equity Review',
        'desc': 'Tax-efficient portfolio realignment.',
      },
      {
        'title': 'FATCA & CRS Advisory',
        'desc': ' Global reporting risk mitigation.',
      },
      {
        'title': 'Cross-Border Estate Planning',
        'desc': 'Nomination, inheritance & global compliance.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Back',
                button: true,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.darkCardBG,
                      shape: BoxShape.circle,
                    ),
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              AppText(
                "Our Offerings",
                variant: AppTextVariant.headline3,
                weight: AppTextWeight.bold,
              ),
              const WhatsAppSupportButton(
                size: 20,
                color: AppColors.darkPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            height: 150.h,
            child: PageView.builder(
              padEnds: false,
              clipBehavior: Clip.none,
              itemCount: offerings.length,
              controller: _offeringsController,
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                setState(() {
                  _currentOfferingIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final offering = offerings[index];
                final isSelected = index == _currentOfferingIndex;

                return Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _offeringsController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Semantics(
                    label:
                        'Offering ${index + 1} of ${offerings.length}: ${offering['title']!}. ${offering['desc']!}',
                    hint: 'Swipe left or right to see more offerings',
                    focusable: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBG,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white24 : Colors.white10,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                        ],
                      ),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              offering['title']!,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.bold,
                              maxLines: 2,
                              colorType: AppTextColorType.secondary,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              offering['desc']!,
                              variant: AppTextVariant.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        ExcludeSemantics(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                offerings.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentOfferingIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        index == _currentOfferingIndex
                            ? Colors.white
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFounderAdvisorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Founder Card
            Expanded(
              flex: 2,
              child: Semantics(
                label: 'Jash Koradia, Founder of PivotMoney',
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/app/image 2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Advisor Card
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E75FF), Color(0xFF1A5ACF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E75FF).withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "SEBI Registered Investment Advisor",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.bold,
                      customColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      "Strategic partnerships with US–India corridor Chartered Accountants",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      customColor: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Talk to Founder',
                      button: true,
                      hint: 'Opens advisor contact',
                      child: ElevatedButton(
                        onPressed: () {
                          SpeakToAdvisor.speakToAdvisor();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E75FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                "Talk to Founder",
                                variant: AppTextVariant.bodySmall,
                                weight: AppTextWeight.bold,
                                customColor: const Color(0xFF2E75FF),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularPlansSection() {
    final List<Map<String, dynamic>> plans = [
      {
        'category': 'PAID',
        'title': 'NRI Tax Review',
        'items': [
          'US–India capital gains analysis',
          'Double taxation review',
          'CA coordination',
          '60-minute deep session',
        ],
        'color': const Color(0xFF4CAF50),
        'titlecolor': const Color(0xFF4CAF50),
      },
      {
        'category': 'Premium',
        'title': 'Return-to-India Strategy Package',
        'items': [
          'RNOR mapping',
          'Asset transition plan',
          'NRE/NRO restructuring',
          '90-day action roadmap',
        ],
        'color': const Color(0xFF4CAF50),
        'titlecolor': const Color(0xFF8C894D),
      },
      {
        'category': 'Comprehensive',
        'title': 'Full Wealth + Tax Structuring',
        'items': [
          'Investment realignment',
          'Tax optimisation modelling',
          'Cash flow mapping',
          'Dedicated CA consultation',
        ],
        'color': const Color(0xFF4CAF50),
        'titlecolor': const Color(0xFF2983FF),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                "Explore Our Popular Plans",
                variant: AppTextVariant.headline2,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 8),
              AppText(
                "Some situations require detailed structuring beyond the free session.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            height: 320.h,
            child: PageView.builder(
              padEnds: false,
              clipBehavior: Clip.none,
              controller: _plansController,
              itemCount: plans.length,
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                setState(() {
                  _currentPlanIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final plan = plans[index];
                final itemsList = (plan['items'] as List<String>).join(', ');
                return Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _plansController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Semantics(
                    label:
                        'Plan ${index + 1} of ${plans.length}: ${plan['category']} plan: ${plan['title']}. Includes: $itemsList',
                    hint: 'Swipe left or right to see more plans',
                    focusable: true,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: index == _currentPlanIndex ? 1.0 : 0.95,
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: 8,
                          left: 8,
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.darkCardBG,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppText(
                                  plan['category'],
                                  variant: AppTextVariant.bodySmall,
                                  weight: AppTextWeight.bold,
                                  customColor: plan['titlecolor'],
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppText(
                                plan['title'],
                                variant: AppTextVariant.headline4,
                                weight: AppTextWeight.bold,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 20),
                              ...List.generate(
                                plan['items'].length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      ExcludeSemantics(
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: plan['color'],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppText(
                                          plan['items'][i],
                                          variant: AppTextVariant.bodyMedium,
                                          colorType: AppTextColorType.primary,
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
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        ExcludeSemantics(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                plans.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPlanIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        index == _currentPlanIndex
                            ? Colors.white
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturningToIndiaSection() {
    final List<String> checklist = [
      '80% Error reduction',
      '90% Accuracy in Data Logs',
      '60+ Hours Saved',
      '30% Faster Delivery',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                AppText(
                  "Returning to India Soon?",
                  variant: AppTextVariant.headline2,
                  weight: AppTextWeight.bold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        "High Demand Service",
                        variant: AppTextVariant.tiny,
                        customColor: Colors.green,
                        weight: AppTextWeight.bold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppText(
                  "Don't move assets before understanding RNOR benefits.",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "Pre-Return Checklist",
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  checklist.length,
                  (index) => Semantics(
                    label: checklist[index],
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 14),
                          ExcludeSemantics(
                            child: AppText(
                              checklist[index],
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildFeatureTag("FEMA Compliant"),
                    const SizedBox(width: 8),
                    _buildFeatureTag("RNOR 2026 Ready"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText(
        label,
        variant: AppTextVariant.tiny,
        customColor: Colors.green,
        weight: AppTextWeight.medium,
      ),
    );
  }

  Widget _buildBuiltForGlobalIndiansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            text: TextSpan(
              text: "Built For ",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
              children: [
                TextSpan(
                  text: "Global Indians",
                  style: const TextStyle(color: Color(0xFF00AFDA)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250.h,
          child: PageView.builder(
            controller: _reviewsController,
            itemCount: _reviews.length,
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() {
                _currentReviewIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _reviewsController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Semantics(
                  label:
                      'Review ${index + 1} of ${_reviews.length}: ${review['name']}, 5 stars. ${review['review']}',
                  hint: 'Swipe left or right to see more reviews',
                  focusable: true,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/app/reviewicon.png',
                            height: 48.h,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          AppText(
                            review['name']!,
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(
                              5,
                              (i) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppText(
                            review['review']!,
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ExcludeSemantics(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _reviews.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentReviewIndex ? 20 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        index == _currentReviewIndex
                            ? Colors.white
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
