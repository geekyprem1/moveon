import 'package:cloud_firestore/cloud_firestore.dart';

class TasksRepository {
  final FirebaseFirestore _firestore;

  TasksRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch completed tasks for a specific day
  Future<Set<String>> getCompletedTasks(String uid, String dateStr) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(dateStr)
          .get();

      if (doc.exists && doc.data() != null) {
        final List<dynamic> list = doc.data()!['completedTaskIds'] as List<dynamic>? ?? [];
        return list.map((e) => e.toString()).toSet();
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Watch completed tasks for a specific day (Stream)
  Stream<Set<String>> watchCompletedTasks(String uid, String dateStr) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(dateStr)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final List<dynamic> list = doc.data()!['completedTaskIds'] as List<dynamic>? ?? [];
        return list.map((e) => e.toString()).toSet();
      }
      return {};
    });
  }

  /// Save completed tasks for a specific day
  Future<void> saveCompletedTasks(String uid, String dateStr, Set<String> completedIds) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(dateStr)
        .set({
      'id': dateStr,
      'completedTaskIds': completedIds.toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle a task status
  Future<void> toggleTask(String uid, String dateStr, String taskId, bool completed) async {
    final current = await getCompletedTasks(uid, dateStr);
    if (completed) {
      current.add(taskId);
    } else {
      current.remove(taskId);
    }
    await saveCompletedTasks(uid, dateStr, current);
  }
}
