import '../core/config/app_config.dart';
import '../core/utils/json_utils.dart';

class BannerItem {
  const BannerItem({required this.id, this.title, this.imageUrl});

  final int id;
  final String? title;
  final String? imageUrl;

  factory BannerItem.fromJson(dynamic json) {
    final map = unwrapMap(asMap(json));
    return BannerItem(
      id: readInt(map, 'id') ?? 0,
      title: readString(map, 'title') ?? readString(map, 'titulo'),
      imageUrl: AppConfig.resolveImageUrl(
        readString(map, 'imageUrl') ??
            readString(map, 'image') ??
            readString(map, 'imagen'),
      ),
    );
  }
}
