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
      _hasMore = result.data!.length >= _perPage;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  // ── Load More (next page) ──────────────────────
  Future<void> loadMoreTodos({required String authToken}) async {
    if (_isLoadingMore || !_hasMore) return;

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
      _currentPage = nextPage;
      _todos.addAll(result.data!);
      _hasMore = result.data!.length >= _perPage;
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
      // Reload from page 1
      final listResult = await _repository.getTodos(
        authToken: authToken,
        page: 1,
        perPage: _currentPage * _perPage,
      );
      if (listResult.success && listResult.data != null) {
        _todos = listResult.data!;
      }
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
      final results = await Future.wait([
        _repository.getTodoById(authToken: authToken, todoId: todoId),
        _repository.getTodos(
          authToken: authToken,
          page: 1,
          perPage: _currentPage * _perPage,
        ),
      ]);

      final detailResult = results[0];
      final listResult   = results[1];

      if (detailResult.success && detailResult.data != null) {
        _selectedTodo = detailResult.data as TodoModel;
      }
      if (listResult.success && listResult.data != null) {
        _todos = listResult.data as List<TodoModel>;
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
      final results = await Future.wait([
        _repository.getTodoById(authToken: authToken, todoId: todoId),
        _repository.getTodos(
          authToken: authToken,
          page: 1,
          perPage: _currentPage * _perPage,
        ),
      ]);

      final detailResult = results[0];
      final listResult   = results[1];

      if (detailResult.success && detailResult.data != null) {
        _selectedTodo = detailResult.data as TodoModel;
      }
      if (listResult.success && listResult.data != null) {
        _todos = listResult.data as List<TodoModel>;
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