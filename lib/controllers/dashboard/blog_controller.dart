import 'package:get/get.dart';
import 'package:nwt_app/screens/dashboard/types/blogs.dart';
import 'package:nwt_app/services/dashboard/blogs.dart';
import 'package:nwt_app/utils/logger.dart';

class BlogController extends GetxController {
  final _blogService = BlogService();

  final isLoading = false.obs;
  final blogs = <BlogItem>[].obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchBlogs() async {
    final response = await _blogService.getBlogs(
      onLoading: (loading) => isLoading.value = loading,
    );

    if (response != null && response.success) {
      blogs.assignAll(response.data.blogs);
    } else {
      AppLogger.error('Failed to fetch blogs', tag: 'BlogController');
    }
  }
}
