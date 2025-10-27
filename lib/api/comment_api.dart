class NftApi {
  static const String getComments = 'comment';
  static String getBlogDetail(String id) => 'blogs/detail/$id';
  static const String createComment = 'comment/create';
  static String deleteBlog(String id) => 'blogs/delete/$id';

  static String deleteComment(String id) => 'blogs/delete/$id';
  static String getCommentHistory(String id) => 'blogs/history/$id';
  static const String createBlog = 'blogs/create';

  static const String getUnreadCount = 'notifications/unread-count';
}

class CommentApi {
  static String replyComment = 'comment/reply';
}