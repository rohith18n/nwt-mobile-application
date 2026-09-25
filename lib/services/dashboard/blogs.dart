import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/dashboard/types/blogs.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class BlogService {
  Future<BlogResponse?> getBlogs({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_BLOGS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Blogs Response: ${responseData.toString()}',
          tag: 'blog',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return BlogResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Blogs Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'blog',
      );
      return null;
    } finally {
      onLoading(false);
    }
  }
}
