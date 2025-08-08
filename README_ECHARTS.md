# ECharts 中国地图 Coach门店分布系统

## 功能特性

### 🗺️ 地图功能
- **中国地图显示**: 使用ECharts显示中国各省份的Coach门店分布
- **省份切换**: 点击省份可以放大显示该省份的详细地图
- **城市级别**: 在省份地图中显示各城市的Coach数量分布
- **交互式操作**: 支持地图缩放、拖拽等操作

### 📊 数据可视化
- **颜色映射**: 根据Coach数量使用不同颜色深浅显示
- **数据标签**: 在地图上显示具体的Coach数量
- **统计信息**: 实时显示当前视图的门店数量和Coach总数

### 🏪 门店详情
- **弹框显示**: 点击地区后右侧弹出门店详情框
- **门店列表**: 显示门店名称、地址、电话等信息
- **Coach数量**: 每个门店显示具体的Coach人数

## 文件结构

```
lib/
├── models/
│   └── coach_data.dart          # Coach数据模型
├── services/
│   └── coach_service.dart       # 数据服务层
├── widgets/
│   └── store_detail_dialog.dart # 门店详情弹框组件
├── pages/
│   ├── shopDetailEcharts.dart   # 主要的地图页面
│   └── test_map_page.dart       # 测试页面
└── router/
    └── router.dart              # 路由配置
```

## 使用方法

### 1. 访问地图页面
- 在首页点击"测试ECharts地图"按钮
- 或直接访问路由 `/test-map`

### 2. 地图交互
- **全国视图**: 显示中国各省份的Coach分布
- **省份视图**: 点击省份进入该省份的详细地图
- **快速访问**: 右侧提供快速访问按钮，可直接点击进入特定地区

### 3. 查看门店详情
- 点击地图上的地区或快速访问按钮
- 右侧会弹出门店详情框
- 显示该地区的所有门店信息和Coach数量

## 数据模型

### CoachData
```dart
class CoachData {
  final String province;      // 省份
  final String city;          // 城市
  final String storeName;     // 门店名称
  final String address;       // 地址
  final String phone;         // 电话
  final double latitude;      // 纬度
  final double longitude;     // 经度
  final int coachCount;       // Coach数量
}
```

### ProvinceData
```dart
class ProvinceData {
  final String name;          // 省份名称
  final int coachCount;       // 总Coach数量
  final List<CityData> cities; // 城市列表
}
```

## 技术实现

### ECharts配置
- 使用 `flutter_echarts` 包集成ECharts
- 支持中国地图和省份地图的切换
- 自定义颜色主题和交互效果

### 状态管理
- 使用 `StatefulWidget` 管理地图状态
- 支持全国视图和省份视图的切换
- 动态更新门店数据和统计信息

### UI设计
- 现代化的Material Design风格
- 响应式布局，适配不同屏幕尺寸
- 优雅的动画效果和交互反馈

## 自定义配置

### 修改数据
在 `lib/services/coach_service.dart` 中修改模拟数据：
```dart
static List<CoachData> getMockCoachData() {
  return [
    CoachData(
      province: '北京',
      city: '北京市',
      storeName: 'Coach北京三里屯店',
      address: '北京市朝阳区三里屯路19号',
      phone: '010-12345678',
      latitude: 39.9042,
      longitude: 116.4074,
      coachCount: 15,
    ),
    // 添加更多数据...
  ];
}
```

### 修改地图样式
在 `lib/pages/shopDetailEcharts.dart` 中修改ECharts配置：
```dart
String _getChinaMapOption() {
  // 修改标题、颜色、布局等配置
  return '''
  {
    "title": {
      "text": "自定义标题",
      // ...
    },
    "visualMap": {
      "inRange": {
        "color": ["#自定义颜色1", "#自定义颜色2", "#自定义颜色3"]
      }
    }
  }
  ''';
}
```

## 依赖包

确保在 `pubspec.yaml` 中包含以下依赖：
```yaml
dependencies:
  flutter_echarts: ^2.5.0
  go_router: ^7.0.0
  # 其他依赖...
```

## 注意事项

1. **地图数据**: 当前使用模拟数据，实际使用时需要替换为真实的API数据
2. **省份地图**: 某些省份可能需要额外的地图数据文件
3. **性能优化**: 大量数据时建议使用分页加载
4. **网络请求**: 实际项目中需要添加错误处理和加载状态

## 扩展功能

### 可以添加的功能
- 搜索功能：按地区或门店名称搜索
- 筛选功能：按Coach数量范围筛选
- 排序功能：按各种条件排序门店
- 导出功能：导出门店数据为Excel或PDF
- 实时数据：集成实时数据API
- 地图标记：在地图上显示门店位置标记

### 技术优化
- 缓存机制：缓存地图数据和门店信息
- 懒加载：按需加载省份地图数据
- 性能监控：添加性能监控和错误追踪
- 单元测试：添加完整的测试覆盖 