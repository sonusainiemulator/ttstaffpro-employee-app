import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../../models/notice_model.dart';

part 'notice_board_store.g.dart';

class NoticeBoardStore = NoticeBoardStoreBase with _$NoticeBoardStore;

abstract class NoticeBoardStoreBase with Store {
  @observable
  bool isLoading = false;

  final Box<NoticeModel> _noticeBox = Hive.box<NoticeModel>('noticeBoardBox');

  @observable
  ObservableList<NoticeModel> notices = ObservableList<NoticeModel>();

  @action
  Future<void> getNoticeBoard() async {
    isLoading = true;
    if (_noticeBox.isNotEmpty) {
      notices.clear();
      notices.addAll(_noticeBox.values);
    }
    await updateNoticeBoardInBackground();
    isLoading = false;
  }

  Future<void> updateNoticeBoardInBackground() async {
    try {
      // Fetch the latest notices from the server
      final apiNotices = await apiService.getNotices();

      // Keep previously cached notices if fetch failed/unauthorized and returned empty.
      if (apiNotices.isNotEmpty) {
        await _noticeBox.clear();
        for (var notice in apiNotices) {
          await _noticeBox.add(notice);
        }
      }

      // Update the in-memory list to reflect the current state of the Hive box
      notices
        ..clear()
        ..addAll(_noticeBox.values);

      log('${apiNotices.length} notices synced');
    } catch (e) {
      log('Error updating notices: ${e.toString()}');
      // Handle the error appropriately
    }
  }
}
