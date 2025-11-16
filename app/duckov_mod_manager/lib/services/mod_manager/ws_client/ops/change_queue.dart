class ChangeQueue {
  final Set<String> _enable = <String>{};
  final Set<String> _disable = <String>{};

  bool get isEmpty => _enable.isEmpty && _disable.isEmpty;

  void apply(String modId, bool enabled) {
    if (enabled) {
      _disable.remove(modId);
      _enable.add(modId);
    } else {
      _enable.remove(modId);
      _disable.add(modId);
    }
  }

  void applyBatch(Iterable<String> enableIds, Iterable<String> disableIds) {
    for (final id in enableIds) {
      _disable.remove(id);
      _enable.add(id);
    }
    for (final id in disableIds) {
      _enable.remove(id);
      _disable.add(id);
    }
  }

  ({List<String> enable, List<String> disable}) take(int maxCount) {
    final e = _enable.take(maxCount).toList();
    final d = _disable.take(maxCount).toList();
    for (final id in e) {
      _enable.remove(id);
    }
    for (final id in d) {
      _disable.remove(id);
    }
    return (enable: e, disable: d);
  }

  int get length => _enable.length + _disable.length;
}