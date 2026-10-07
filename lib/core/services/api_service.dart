import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5050/api';

  // ============================================================

  // USERS

  // ============================================================

  static Future<Map<String, dynamic>> createUser({
    required String fullName,

    String? phone,

    String? email,

    String? profileImage,

    String currency = 'INR',

    String? passcode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'full_name': fullName,

        'phone': phone,

        'email': email,

        'profile_image': profileImage,

        'currency': currency,

        'passcode': passcode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Failed to create user');
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(data['message'] ?? 'Failed to get user');
  }

  static Future<Map<String, dynamic>> loginWithPhone(
    String phone,

    String passcode,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'phone': phone, 'passcode': passcode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(data['message'] ?? 'Login failed');
  }

  static Future<void> updateUser({
    required int userId,

    required String fullName,

    String? phone,

    String? email,

    String? profileImage,

    String currency = 'INR',

    String? passcode,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'full_name': fullName,

        'phone': phone,

        'email': email,

        'profile_image': profileImage,

        'currency': currency,

        'passcode': passcode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(data['message'] ?? 'Failed to update user');
  }

  // ============================================================

  static Future<void> changePasscode({
    required int userId,

    required String currentPasscode,

    required String newPasscode,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/passcode'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'currentPasscode': currentPasscode,

        'newPasscode': newPasscode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(data['message'] ?? 'Failed to change passcode');
  }

  static Future<void> forgotPasscode({
    String? phone,
    String? email,
    required String newPasscode,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/forgot-passcode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'email': email,
        'newPasscode': newPasscode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(data['message'] ?? 'Failed to reset passcode');
  }

  // TRANSACTIONS

  // ============================================================

  static Future<Map<String, dynamic>> createTransaction({
    required int userId,

    int? categoryId,

    required String type,

    required double amount,

    String? note,

    DateTime? transactionDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'category_id': categoryId,

        'type': type,

        'amount': amount,

        'note': note,

        'transaction_date': transactionDate?.toIso8601String(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Failed to create transaction');
  }

  static Future<List<Map<String, dynamic>>> getTransactions(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/user/$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to get transactions');
  }

  // ============================================================

  // EMI

  // ============================================================

  static Future<List<Map<String, dynamic>>> getEmis(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/emis/user/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['emis'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load EMIs');
  }

  static Future<void> createEmi({
    required int userId,

    required String name,

    String? lenderName,

    required double totalAmount,

    required double monthlyAmount,

    required double interestRate,

    required int totalInstallments,

    required DateTime startDate,

    required int dueDay,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emis'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'name': name,

        'lender_name': lenderName,

        'total_amount': totalAmount,

        'monthly_amount': monthlyAmount,

        'interest_rate': interestRate,

        'total_installments': totalInstallments,

        'start_date': startDate.toIso8601String().split('T').first,

        'due_day': dueDay,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create EMI');
    }
  }

  static Future<void> updateEmi({
    required int emiId,

    required String name,

    String? lenderName,

    required double totalAmount,

    required double monthlyAmount,

    required double interestRate,

    required int totalInstallments,

    required DateTime startDate,

    required int dueDay,

    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/emis/$emiId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'name': name,

        'lender_name': lenderName,

        'total_amount': totalAmount,

        'monthly_amount': monthlyAmount,

        'interest_rate': interestRate,

        'total_installments': totalInstallments,

        'start_date': startDate.toIso8601String().split('T').first,

        'due_day': dueDay,

        'status': status,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update EMI');
    }
  }

  static Future<void> deleteEmi(int emiId) async {
    final response = await http.delete(Uri.parse('$baseUrl/emis/$emiId'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete EMI');
    }
  }

  // ============================================================

  // DEBTS - BORROW & LEND

  // ============================================================

  static Future<List<Map<String, dynamic>>> getDebts(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/debts/user/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['debts'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load debts');
  }

  static Future<void> createDebt({
    required int userId,

    required String personName,

    required String type,

    required double totalAmount,

    double paidAmount = 0,

    DateTime? dueDate,

    String status = 'active',

    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/debts'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'person_name': personName,

        'type': type,

        'total_amount': totalAmount,

        'paid_amount': paidAmount,

        'due_date': dueDate?.toIso8601String().split('T').first,

        'status': status,

        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create debt');
    }
  }

  static Future<void> settleDebt(int debtId, {double? amount}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/debts/$debtId/settle'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'amount': amount}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to settle debt');
    }
  }

  static Future<void> deleteDebt(int debtId) async {
    final response = await http.delete(Uri.parse('$baseUrl/debts/$debtId'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete debt');
    }
  }

  // ============================================================

  // BILLS

  // ============================================================

  static Future<List<Map<String, dynamic>>> getBills(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/bills/user/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['bills'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load bills');
  }

  static Future<Map<String, dynamic>> getBill(int billId) async {
    final response = await http.get(Uri.parse('$baseUrl/bills/$billId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['bill']);
    }

    throw Exception(data['message'] ?? 'Failed to get bill');
  }

  static Future<void> createBill({
    required int userId,

    required String name,

    String? provider,

    required double amount,

    required String frequency,

    required DateTime dueDate,

    required bool autoRepeat,

    String status = 'active',

    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bills'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'name': name,

        'provider': provider,

        'amount': amount,

        'frequency': frequency,

        'due_date': dueDate.toIso8601String().split('T').first,

        'auto_repeat': autoRepeat,

        'status': status,

        'notes': notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create bill');
    }
  }

  static Future<void> updateBill({
    required int billId,

    required String name,

    String? provider,

    required double amount,

    required String frequency,

    required DateTime dueDate,

    required bool autoRepeat,

    required String status,

    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bills/$billId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'name': name,

        'provider': provider,

        'amount': amount,

        'frequency': frequency,

        'due_date': dueDate.toIso8601String().split('T').first,

        'auto_repeat': autoRepeat,

        'status': status,

        'notes': notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update bill');
    }
  }

  static Future<void> markBillAsPaid(int billId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bills/$billId/pay'),

      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to mark bill as paid');
    }
  }

  static Future<void> deleteBill(int billId) async {
    final response = await http.delete(Uri.parse('$baseUrl/bills/$billId'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete bill');
    }
  }

  // ============================================================

  // NOTES

  // ============================================================

  static Future<List<Map<String, dynamic>>> getNotes(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/notes/user/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['notes'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load notes');
  }

  static Future<Map<String, dynamic>> getNote(int noteId) async {
    final response = await http.get(Uri.parse('$baseUrl/notes/$noteId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['note']);
    }

    throw Exception(data['message'] ?? 'Failed to get note');
  }

  static Future<Map<String, dynamic>> createNote({
    required int userId,

    required String title,

    String? content,

    bool pinned = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'title': title,

        'content': content,

        'pinned': pinned,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data['note']);
    }

    throw Exception(data['message'] ?? 'Failed to create note');
  }

  static Future<Map<String, dynamic>> updateNote({
    required int noteId,

    required String title,

    String? content,

    bool pinned = false,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$noteId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'title': title, 'content': content, 'pinned': pinned}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['note']);
    }

    throw Exception(data['message'] ?? 'Failed to update note');
  }

  static Future<Map<String, dynamic>> toggleNotePin(int noteId) async {
    final response = await http.patch(Uri.parse('$baseUrl/notes/$noteId/pin'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['note']);
    }

    throw Exception(data['message'] ?? 'Failed to update note pin');
  }

  static Future<void> deleteNote(int noteId) async {
    final response = await http.delete(Uri.parse('$baseUrl/notes/$noteId'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete note');
    }
  }

  // ============================================================

  // NOTIFICATIONS

  // ============================================================

  static Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user/$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load notifications');
  }

  static Future<List<Map<String, dynamic>>> getUnreadNotifications(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user/$userId/unread'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load unread notifications');
  }

  static Future<Map<String, dynamic>> createNotification({
    required int userId,

    required String title,

    String? message,

    String type = 'general',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'title': title,

        'message': message,

        'type': type,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data['notification']);
    }

    throw Exception(data['message'] ?? 'Failed to create notification');
  }

  static Future<Map<String, dynamic>> getNotification(
    int notificationId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/$notificationId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['notification']);
    }

    throw Exception(data['message'] ?? 'Failed to get notification');
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsAsRead(int userId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/user/$userId/read-all'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? 'Failed to mark all notifications as read',
      );
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$notificationId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete notification');
    }
  }

  static Future<void> deleteAllNotifications(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/user/$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete all notifications');
    }
  }

  // ============================================================

  // REPORTS

  // ============================================================

  static Future<Map<String, dynamic>> getReportSummary(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId/summary'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Failed to load report summary');
  }

  static Future<List<Map<String, dynamic>>> getCategoryReport(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId/categories'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load category report');
  }

  static Future<List<Map<String, dynamic>>> getMonthlyReport(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId/monthly'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['monthly'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load monthly report');
  }

  static Future<List<Map<String, dynamic>>> getWeeklyReport(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId/weekly'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['weekly'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load weekly report');
  }

  static Future<List<Map<String, dynamic>>> getTopSpendingCategories(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId/top-categories'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }

    throw Exception(
      data['message'] ?? 'Failed to load top spending categories',
    );
  }

  // ============================================================

  // CATEGORIES

  // ============================================================

  static Future<List<Map<String, dynamic>>> getCategories(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/user/$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }

    throw Exception(data['message'] ?? 'Failed to load categories');
  }

  static Future<Map<String, dynamic>> createCategory({
    required int userId,

    required String name,

    String? icon,

    String? color,

    String type = 'expense',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'user_id': userId,

        'name': name,

        'icon': icon,

        'color': color,

        'type': type,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data['category'] ?? data);
    }

    throw Exception(data['message'] ?? 'Failed to create category');
  }

  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,

    required String name,

    String? icon,

    String? color,

    String? type,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$categoryId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'name': name,

        'icon': icon,

        'color': color,

        'type': type,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['category'] ?? data);
    }

    throw Exception(data['message'] ?? 'Failed to update category');
  }

  static Future<void> deleteCategory(int categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$categoryId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete category');
    }
  }
}
