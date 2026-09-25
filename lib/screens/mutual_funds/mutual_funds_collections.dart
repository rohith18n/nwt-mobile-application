import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/screens/dashboard/widgets/mf_top_performers_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/search/global_search/global_search.dart';

class MutualFundsCollectionsScreen extends StatefulWidget {
  const MutualFundsCollectionsScreen({
    super.key,
    required this.title,
    required this.type,
  });
  final String title;
  final String type;

  @override
  State<MutualFundsCollectionsScreen> createState() =>
      _MutualFundsCollectionsScreenState();
}

class _MutualFundsCollectionsScreenState
    extends State<MutualFundsCollectionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final MFTopPerformersController mfTopPerformersController = Get.put(
    MFTopPerformersController(),
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchCollections();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger when scrolled to 80% of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (mfTopPerformersController.hasMore.value &&
          !mfTopPerformersController.isLoading.value &&
          !mfTopPerformersController.isPaginating.value) {
        fetchMoreCollections();
      }
    }
  }

  void fetchCollections() async {
    Future.delayed(const Duration(seconds: 0), () async {
      await mfTopPerformersController.fetchTopPerformers(
        dashboard: false,
        limit: 50,
        type: widget.type,
      );
    });
  }

  void fetchMoreCollections() async {
    await mfTopPerformersController.fetchTopPerformers(
      dashboard: false,
      limit: 50,
      offset: mfTopPerformersController.currentOffset,
      type: widget.type,
      isLoadMore: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppColors.darkBackground,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  AppText(
                    widget.title,
                    variant: AppTextVariant.headline6,
                    weight: AppTextWeight.semiBold,
                  ),
                  const WhatsAppSupportButton(
                    size: 20,
                    color: AppColors.darkPrimary,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Search Bar
                  InkWell(
                    onTap:
                        () => Get.to(
                          () => GlobalSearchScreen(),
                          transition: Transition.rightToLeft,
                        ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search for mutual funds...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(
                () => MFTopPerformersWidget(
                  data: mfTopPerformersController.collections.value,
                  controller: mfTopPerformersController,
                  dashboard: false,
                  assetclass: widget.title,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollController: _scrollController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
