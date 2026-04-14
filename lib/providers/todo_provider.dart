// lib/providers/todo_provider.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/models/todo_model.dart';
import '../data/services/todo_repository.dart';

enum TodoStatus { initial, loading, success, error }
enum TodoFilter { all, done, pending }

class TodoProvider extends ChangeNotifier {
  TodoProvider({TodoRepository? repository})
      : _repository = repository ?? TodoRepository();

  final TodoRepository _repository;

  // ── State ────────────────────────────────────
  TodoStatus _status      = TodoStatus.initial;
  List<TodoModel> _todos  = [];
  TodoModel? _selectedTodo;
  String _errorMessage    = '';
  String _searchQuery     = '';
  TodoFilter _filter      = TodoFilter.all;

  // ── Pagination ────────────────────────────────
  int _currentPage    = 1;
  static const int _perPage = 10;
  bool _hasMore       = true;
  bool _isLoadingMore = false;

  // ── Getters ──────────────────────────────────
  TodoStatus get status       => _status;
  TodoModel? get selectedTodo => _selectedTodo;
  String get errorMessage     => _errorMessage;
  TodoFilter get filter       => _filter;
  bool get hasMore            => _hasMore;
  bool get isLoadingMore      => _isLoadingMore;

  List<TodoModel> get todos {
    List<TodoModel> result = _todos;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply filter
    switch (_filter) {
      case TodoFilter.done:
        return result.where((t) => t.isDone).toList();
      case TodoFilter.pending:
        return result.where((t) => !t.isDone).toList();
      case TodoFilter.all:
        return List.unmodifiable(result);
    }
  }

  int get totalTodos   => _todos.length;
  int get doneTodos    => _todos.where((t) => t.isDone).length;
  int get pendingTodos => _todos.where((t) => !t.isDone).length;

  // ── Load Todos (first page) ───────────────────
  Future<void> loadTodos({required String authToken}) async {
    _setStatus(TodoStatus.loading);
    _currentPage = 1;
    _hasMore = true;

    final result = await _repository.getTodos(
      authToken: authToken,
      page: _currentPage,
      perPage: _perPage,
    );

    if (result.success && result.data != null) {
      _todos = result.data!;
      // FIX: hanya lanjut fetch jika data yang diterima sama dengan perPage
      // Jika lebih kecil, berarti ini halaman terakhir
      _hasMore = result.data!.length >= _perPage;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  // ── Load More (next page) ──────────────────────
  Future<void> loadMoreTodos({required String authToken}) async {
    // FIX: guard berlapis — jangan fetch jika sedang loading, tidak ada data
    // baru, atau sedang loading halaman pertama
    if (_isLoadingMore || !_hasMore || _status == TodoStatus.loading) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await _repository.getTodos(
      authToken: authToken,
      page: nextPage,
      perPage: _perPage,
    );

    _isLoadingMore = false;

    if (result.success && result.data != null) {
      final newItems = result.data!;

      if (newItems.isEmpty) {
        // FIX: server mengembalikan list kosong = tidak ada data lagi
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        // FIX: hindari duplikat dengan mengecek ID sebelum menambahkan
        final existingIds = _todos.map((t) => t.id).toSet();
        final uniqueNewItems = newItems.where((t) => !existingIds.contains(t.id)).toList();
        _todos.addAll(uniqueNewItems);
        // FIX: jika item baru < perPage, berarti ini halaman terakhir
        _hasMore = newItems.length >= _perPage;
      }
    } else {
      // Gagal load more — jangan ubah _hasMore, biarkan user bisa retry
      // dengan scroll lagi
    }

    notifyListeners();
  }

  // ── Load Single Todo ──────────────────────────
  Future<void> loadTodoById({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodoById(
        authToken: authToken, todoId: todoId);
    if (result.success && result.data != null) {
      _selectedTodo = result.data;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  // ── Create Todo ───────────────────────────────
  Future<bool> addTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.createTodo(
      authToken:   authToken,
      title:       title,
      description: description,
    );
    if (result.success) {
      // FIX: selalu reload dari halaman 1 dengan jumlah item yang sudah
      // di-load saat ini agar list tidak reset ke 10 item saja,
      // tapi juga tidak melipatgandakan data
      await _reloadCurrentList(authToken: authToken);
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Todo ───────────────────────────────
  Future<bool> editTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodo(
      authToken:   authToken,
      todoId:      todoId,
      title:       title,
      description: description,
      isDone:      isDone,
    );
    if (result.success) {
      // FIX: update item di list secara lokal terlebih dahulu (optimistic update)
      // lalu fetch detail yang baru untuk selectedTodo
      final detailResult = await _repository.getTodoById(
        authToken: authToken,
        todoId: todoId,
      );
      if (detailResult.success && detailResult.data != null) {
        _selectedTodo = detailResult.data;
        // Update item di list lokal tanpa harus fetch ulang seluruh list
        final idx = _todos.indexWhere((t) => t.id == todoId);
        if (idx != -1) {
          _todos[idx] = detailResult.data!;
        }
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Cover ──────────────────────────────
  Future<bool> updateCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodoCover(
      authToken:     authToken,
      todoId:        todoId,
      imageFile:     imageFile,
      imageBytes:    imageBytes,
      imageFilename: imageFilename,
    );
    if (result.success) {
      // FIX: sama seperti editTodo — update lokal saja, tidak perlu reload list
      final detailResult = await _repository.getTodoById(
        authToken: authToken,
        todoId: todoId,
      );
      if (detailResult.success && detailResult.data != null) {
        _selectedTodo = detailResult.data;
        final idx = _todos.indexWhere((t) => t.id == todoId);
        if (idx != -1) {
          _todos[idx] = detailResult.data!;
        }
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Delete Todo ───────────────────────────────
  Future<bool> removeTodo({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.deleteTodo(
        authToken: authToken, todoId: todoId);
    if (result.success) {
      _todos.removeWhere((t) => t.id == todoId);
      _selectedTodo = null;
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Helper: reload list tanpa reset pagination ─
  // Mengambil semua halaman yang sudah di-load sebelumnya dalam satu request
  Future<void> _reloadCurrentList({required String authToken}) async {
    // FIX: hitung total item yang saat ini sudah ada di list
    // agar setelah add/edit, jumlah yang tampil tidak berubah drastis
    final loadedCount = _todos.isEmpty ? _perPage : _todos.length;
    // Ambil semua item yang sudah di-load dalam satu request (page 1, perPage = loadedCount + 1 untuk item baru)
    final reloadResult = await _repository.getTodos(
      authToken: authToken,
      page: 1,
      perPage: loadedCount + 1, // +1 untuk mengakomodasi item baru
    );
    if (reloadResult.success && reloadResult.data != null) {
      _todos = reloadResult.data!;
      // Jika data yang dikembalikan < perPage asli, tidak ada lagi data
      _hasMore = reloadResult.data!.length >= _perPage;
      // Reset current page agar loadMore berjalan dari titik yang benar
      _currentPage = (reloadResult.data!.length / _perPage).ceil();
      if (_currentPage < 1) _currentPage = 1;
    }
  }

  // ── Filter ────────────────────────────────────
  void setFilter(TodoFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSelectedTodo() {
    _selectedTodo = null;
    notifyListeners();
  }

  void _setStatus(TodoStatus status) {
    _status = status;
    notifyListeners();
  }
}