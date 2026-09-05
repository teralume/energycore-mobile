import 'package:flutter/foundation.dart';

import '../domain/app_failure.dart';

typedef CollectionLoader<T> = Future<List<T>> Function();

class RemoteCollectionController<T> extends ChangeNotifier {
  RemoteCollectionController(this._loader);

  final CollectionLoader<T> _loader;

  List<T> items = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  bool get isOffline => failure?.isOffline ?? false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      items = await _loader();
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> mutate(Future<void> Function() action) async {
    if (isMutating) return false;
    isMutating = true;
    failure = null;
    notifyListeners();
    try {
      await action();
      items = await _loader();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }
}
