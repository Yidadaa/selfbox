import 'package:objectbox/objectbox.dart';

import '../../domain/repositories/web_research_repository.dart';

@Entity()
class LinkPreviewEntity {
  LinkPreviewEntity({
    required this.sourceUrl,
    required this.url,
    required this.title,
    required this.description,
    required this.iconUrl,
    this.id = 0,
    this.unavailable = false,
    this.fetchVersion = 0,
  });

  @Id()
  int id;
  @Unique()
  String sourceUrl;
  String url;
  String title;
  String description;
  String iconUrl;
  bool unavailable;
  int fetchVersion;
}

extension LinkPreviewMapper on LinkPreviewEntity {
  WebPageContent toDomain() => WebPageContent(
    title: title,
    url: url,
    text: '',
    description: description,
    iconUrl: iconUrl,
  );
}
