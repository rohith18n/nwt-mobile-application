import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/dashboard/types/blogs.dart';
import 'package:nwt_app/screens/dashboard/widgets/explore_investing.dart';

class AllBlogsScreen extends StatelessWidget {
  final List<BlogItem> blogs;

  const AllBlogsScreen({super.key, required this.blogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "All Blogs",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.history_toggle_off)),
          ],
        ),
      ),
      body:
          blogs.isEmpty
              ? const Center(child: Text("No blogs found"))
              : GridView.builder(
                padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.8,
                ),
                itemCount: blogs.length,
                itemBuilder: (context, index) {
                  return BlogCard(blog: blogs[index], isGrid: true);
                },
              ),
    );
  }
}
