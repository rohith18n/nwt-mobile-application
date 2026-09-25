import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/dashboard/types/blogs.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:nwt_app/screens/dashboard/all_blogs_screen.dart';

class ExploreInvesting extends StatelessWidget {
  final List<BlogItem> blogs;

  const ExploreInvesting({super.key, required this.blogs});

  @override
  Widget build(BuildContext context) {
    if (blogs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "Blogs",
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      "Learn, watch, and invest smarter",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),
                  ],
                ),
              ),
              if (blogs.length > 5)
                Semantics(
                  label: 'View all blogs',
                  link: true,
                  child: GestureDetector(
                    onTap: () => Get.to(() => AllBlogsScreen(blogs: blogs)),
                    child: AppText(
                      "View All",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.link,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 200.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: min(5, blogs.length),
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              return BlogCard(blog: blogs[index]);
            },
          ),
        ),
      ],
    );
  }
}

class BlogCard extends StatelessWidget {
  final BlogItem blog;
  final bool isGrid;

  const BlogCard({super.key, required this.blog, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${blog.title}. Double tap to read.',
      button: true,
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => AppWebViewScreen(url: blog.redirectUrl, title: blog.title),
          );
        },
        child: Container(
          width: isGrid ? double.infinity : 240.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            image: DecorationImage(
              image: NetworkImage(blog.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [

              // Title Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),
                      bottomRight: Radius.circular(24.r),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: AppText(
                      blog.title,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
