import 'package:objectbox/objectbox.dart';

/// Independent ID set: pin changes never rewrite immutable message rows.
@Entity()
class PinnedMessageStateEntity {
  PinnedMessageStateEntity({this.id = 1, this.messageIds = const []});

  @Id(assignable: true)
  int id;

  List<int> messageIds;
}
