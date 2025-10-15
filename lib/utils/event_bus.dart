// ignore: depend_on_referenced_packages
import 'package:event_bus/event_bus.dart';

final eventBus = EventBus();

// 定义事件
class BlogCreatedEvent {
  BlogCreatedEvent();
}

// 未读消息数量更新事件
class UnreadCountUpdateEvent {
  UnreadCountUpdateEvent();
}

// 通知页面刷新事件
class NotificationsRefreshEvent {
  NotificationsRefreshEvent();
}

// 社区页面刷新事件
class MessagePageRefreshEvent {
  MessagePageRefreshEvent();
}

// 首页刷新事件
class HomePageRefreshEvent {
  HomePageRefreshEvent();
}

// 我的页面刷新事件
class MinePageRefreshEvent {
  MinePageRefreshEvent();
}
