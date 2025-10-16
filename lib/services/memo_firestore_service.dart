import 'package:cloud_firestore/cloud_firestore.dart';
import '../Memo.dart';
import 'auth_service.dart';

class MemoFirestoreService {
  MemoFirestoreService._();
  static final _collection = FirebaseFirestore.instance.collection('memos');

  /// Stream memos for the current user ordered by date descending.
  static Stream<List<Memo>> memoStream() {
    return AuthService.authStateChanges().asyncExpand((user) {
      print("USER ID : ${user?.uid}");
      if (user == null) {
        return Stream<List<Memo>>.value([]);
      }
      return _collection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .handleError((e, st) {
        print('🔥 Firestore stream error → $e');
      }).map((snap) => snap.docs
              .map((doc) => Memo.fromJson({'id': doc.id, ...doc.data()}))
              .toList());
    });
  }

  /// Add or update a memo.
  static Future<void> upsertMemo(Memo memo) async {
    final user = await AuthService.authStateChanges().first;
    if (user == null) throw Exception('User not logged in');
    final data = memo.toJson()..['userId'] = user.uid;
    print('Saving memo data to Firestore: $data');
    if (memo.id == null) {
      await _collection.add(data);
    } else {
      await _collection.doc(memo.id).set(data);
    }
  }

  static Future<void> deleteMemo(Memo memo) async {
    if (memo.id == null) return;
    await _collection.doc(memo.id).delete();
  }
}
