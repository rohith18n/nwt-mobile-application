import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.white, size: 28.sp),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: AppText(
        title,
        variant: AppTextVariant.headline5,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
