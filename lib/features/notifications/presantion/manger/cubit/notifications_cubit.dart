import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:alatarekak/features/notifications/domain/repo/notifications_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'notifications_state.dart';

class NotificationsCubit extends SafeCubit<NotificationsState> {
  final NotificationsRepo _repo;

  NotificationsCubit(this._repo) : super(NotificationsInitial());

  static const _perPage = 15;

  final List<NotificationEntity> _items = [];
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _categoryFilter;

  // ---------------------------------------------------------------
  // تحميل وتصفية
  // ---------------------------------------------------------------

  /// تحميل الصفحة الأولى (أو إعادة التحميل عند السحب للأسفل).
  /// بلا فلتر: الكاش يُعرض فوراً ثم يُحدَّث من الشبكة.
  Future<void> load({String? category}) async {
    _categoryFilter = category;
    _currentPage = 1;

    final cached = category == null ? _repo.getCachedFirstPage() : null;
    if (cached != null && cached.items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(cached.items);
      _unreadCount = cached.unreadCount;
      _hasMore = false; // التحديث الشبكي يصحح القيمة
      _emitLoaded();
    } else {
      emit(NotificationsLoading());
    }

    final result = await _repo.getNotifications(
      page: 1,
      perPage: _perPage,
      category: _categoryFilter,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(NotificationsError(
          message: failure.arabic(HandelErorrMessage.notifications))),
      (pageData) {
        _items
          ..clear()
          ..addAll(pageData.items);
        _unreadCount = pageData.unreadCount;
        _hasMore = pageData.hasMore;
        _emitLoaded();
      },
    );
  }

  /// تحميل الصفحة التالية عند الوصول لنهاية القائمة
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is! NotificationsLoaded) return;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await _repo.getNotifications(
      page: _currentPage + 1,
      perPage: _perPage,
      category: _categoryFilter,
    );
    if (isClosed) return;
    _isLoadingMore = false;

    result.fold(
      (_) => _emitLoaded(), // فشل صامت — نبقي القائمة الحالية
      (pageData) {
        _currentPage++;
        final existingIds = _items.map((n) => n.id).toSet();
        _items.addAll(
            pageData.items.where((n) => !existingIds.contains(n.id)));
        _unreadCount = pageData.unreadCount;
        _hasMore = pageData.hasMore;
        _emitLoaded();
      },
    );
  }

  /// تحديث عداد غير المقروء فقط (للـ badge دون إعادة تحميل القائمة)
  Future<void> refreshUnreadCount() async {
    final result = await _repo.getUnreadCount();
    if (isClosed) return;
    result.fold((_) {}, (count) {
      _unreadCount = count;
      if (state is NotificationsLoaded) _emitLoaded();
    });
  }

  // ---------------------------------------------------------------
  // إجراءات
  // ---------------------------------------------------------------

  Future<void> markRead(int id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;

    // التوائم المخفيّة تُعلَّم معه: قراءة ما يراه المستخدم يجب أن تُنهي
    // العدّاد، ولا يبقى رقم يشير إلى إشعار لا يظهر في القائمة أصلاً.
    final twins = _twinsOf(_items[index]).where((n) => !n.isRead).toList();

    // تحديث تفاؤلي فوري
    _replaceAt(index, isRead: true);
    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    for (final twin in twins) {
      final at = _items.indexWhere((n) => n.id == twin.id);
      if (at != -1) {
        _replaceAt(at, isRead: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
    }
    _emitLoaded();

    final result = await _repo.markRead(id);
    if (isClosed) return;
    await result.fold(
      (_) async {
        // §10.5: حتى 404 يعني "حدّث القائمة بصمت" — نعيد المزامنة
        load(category: _categoryFilter);
      },
      (_) async {
        // فشل تعليم توأم مخفيّ لا يستحق رسالة: المستخدم لا يراه أصلاً،
        // وأول إعادة تحميل تُصحّح العدّاد من الخادم.
        for (final twin in twins) {
          await _repo.markRead(twin.id);
          if (isClosed) return;
        }
        _persistCache();
      },
    );
  }

  Future<void> markAllRead() async {
    final result = await _repo.markAllRead();
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionFailed(
          failure.arabic(HandelErorrMessage.notifications)),
      (newUnreadCount) {
        for (var i = 0; i < _items.length; i++) {
          if (!_items[i].isRead) _replaceAt(i, isRead: true);
        }
        _unreadCount = newUnreadCount;
        _emitLoaded();
        _persistCache();
      },
    );
  }

  Future<void> deleteNotification(int id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final removed = _items.removeAt(index);
    if (!removed.isRead && _unreadCount > 0) _unreadCount--;
    _emitLoaded();

    // حدّث الكاش فوراً حتى لا يعود المحذوف عند إعادة فتح الشاشة
    _persistCache();

    final result = await _repo.deleteNotification(id);
    if (isClosed) return;
    result.fold(
      (_) => load(category: _categoryFilter), // إعادة مزامنة عند الفشل
      (_) {},
    );
  }

  // ---------------------------------------------------------------

  /// حفظ الحالة الحالية في كاش Hive — يُستدعى بعد كل تعديل محلي
  /// (حذف/قراءة) حتى لا يعرض الكاشُ القديم بياناتٍ مُلغاة عند إعادة الفتح.
  /// الكاش يخص القائمة غير المفلترة فقط (نفس شرط التخزين في الـ repo).
  void _persistCache() {
    if (_categoryFilter != null) return;
    _repo.cacheFirstPage(_items.take(_perPage).toList(), _unreadCount);
  }

  void _replaceAt(int index, {required bool isRead}) {
    final n = _items[index];
    _items[index] = NotificationEntity(
      id: n.id,
      title: n.title,
      message: n.message,
      category: n.category,
      type: n.type,
      priority: n.priority,
      isRead: isRead,
      createdAt: n.createdAt,
      data: n.data,
    );
  }

  void _emitLoaded() => emit(NotificationsLoaded(
        notifications: List.unmodifiable(_deduped()),
        unreadCount: _unreadCount,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ));

  /// القائمة كما تُعرض — بلا تكرار الخادم.
  ///
  /// كل بلاغ غياب يصل الطرف المستهدف مرّتين: الخدمة والكونترولر يرسلان
  /// كلٌّ إشعاره عن الحدث نفسه. تُخفى الثانية من العرض **ولا تُحذف من
  /// [_items]**: القائمة الكاملة هي ما يُرقَّم ويُخزَّن ويُعلَّم مقروءاً،
  /// وحذفها منها كان سيُربك الترقيم والكاش.
  ///
  /// والأحدث يُبقى — القائمة تصل من الخادم مرتَّبة تنازلياً.
  List<NotificationEntity> _deduped() {
    final seen = <String>{};
    return [
      for (final item in _items)
        if (item.dedupeKey == null || seen.add(item.dedupeKey!)) item,
    ];
  }

  /// توائم إشعارٍ مخفيّة — تُعلَّم مقروءةً معه.
  ///
  /// بدونها يبقى التوأم المخفيّ غير مقروء، فيعلق شارة العدّاد على رقم
  /// لا يجد المستخدم ما يُقابله في القائمة.
  Iterable<NotificationEntity> _twinsOf(NotificationEntity item) {
    final key = item.dedupeKey;
    if (key == null) return const [];
    return _items.where((n) => n.id != item.id && n.dedupeKey == key);
  }

  void _emitActionFailed(String error) => emit(NotificationsActionFailed(
        notifications: List.unmodifiable(_items),
        unreadCount: _unreadCount,
        hasMore: _hasMore,
        error: error,
      ));
}
