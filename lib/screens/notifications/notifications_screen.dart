import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  bool _isActionLoading = false;

  List<Map<String, dynamic>> _notifications = [];

  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();

    _loadNotifications();
  }

  // ============================================================

  // LOAD NOTIFICATIONS

  // ============================================================

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final notifications = await ApiService.getNotifications(widget.userId);

      if (!mounted) return;

      setState(() {
        _notifications = notifications;

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Notifications error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not load notifications: $error');
    }
  }

  // ============================================================

  // UNREAD COUNT

  // ============================================================

  int get _unreadCount {
    return _notifications.where((notification) {
      return !_isRead(notification);
    }).length;
  }

  // ============================================================

  // FILTERED NOTIFICATIONS

  // ============================================================

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 1) {
      return _notifications.where((notification) {
        return !_isRead(notification);
      }).toList();
    }

    return _notifications;
  }

  // ============================================================

  // CHECK READ STATUS

  // ============================================================

  bool _isRead(Map<String, dynamic> notification) {
    final value = notification['is_read'];

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();

      return normalized == '1' || normalized == 'true' || normalized == 'read';
    }

    return false;
  }

  // ============================================================

  // GET NOTIFICATION ID

  // ============================================================

  int? _notificationId(Map<String, dynamic> notification) {
    final value = notification['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  // ============================================================

  // MARK ONE AS READ

  // ============================================================

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (_isRead(notification)) {
      return;
    }

    final id = _notificationId(notification);

    if (id == null) {
      return;
    }

    try {
      await ApiService.markNotificationAsRead(id);

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (item) => _notificationId(item) == id,
        );

        if (index != -1) {
          _notifications[index] = {..._notifications[index], 'is_read': 1};
        }
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not mark notification as read: $error');
    }
  }

  // ============================================================

  // MARK ALL AS READ

  // ============================================================

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) {
      _showMessage('All notifications are already read.');

      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      await ApiService.markAllNotificationsAsRead(widget.userId);

      if (!mounted) return;

      setState(() {
        _notifications = _notifications.map((notification) {
          return {...notification, 'is_read': 1};
        }).toList();
      });

      _showMessage('All notifications marked as read.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not mark all as read: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  // ============================================================

  // DELETE ONE

  // ============================================================

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final id = _notificationId(notification);

    if (id == null) {
      return;
    }

    try {
      await ApiService.deleteNotification(id);

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere((item) => _notificationId(item) == id);
      });

      _showMessage('Notification deleted.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not delete notification: $error');
    }
  }

  // ============================================================

  // DELETE ALL

  // ============================================================

  Future<void> _deleteAllNotifications() async {
    if (_notifications.isEmpty) {
      _showMessage('There are no notifications to delete.');

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: const Text(
            'Delete all notifications?',

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'This will permanently remove all your notifications.',

            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: const Text(
                'Delete all',

                style: TextStyle(
                  color: AppColors.expense,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      await ApiService.deleteAllNotifications(widget.userId);

      if (!mounted) return;

      setState(() {
        _notifications.clear();
      });

      _showMessage('All notifications deleted.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not delete notifications: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  // ============================================================

  // OPEN NOTIFICATION

  // ============================================================

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    await _markAsRead(notification);

    if (!mounted) return;

    final title = notification['title']?.toString() ?? 'Notification';

    final message = notification['message']?.toString() ?? '';

    final type = notification['type']?.toString() ?? 'general';

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),

          decoration: const BoxDecoration(
            color: AppColors.surface,

            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,

                    height: 4,

                    decoration: BoxDecoration(
                      color: AppColors.border,

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Container(
                      width: 48,

                      height: 48,

                      decoration: BoxDecoration(
                        color: _notificationColor(type).withValues(alpha: 0.12),

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Icon(
                        _notificationIcon(type),

                        color: _notificationColor(type),

                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,

                        style: const TextStyle(
                          color: AppColors.textPrimary,

                          fontSize: 18,

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (message.isNotEmpty)
                  Text(
                    message,

                    style: const TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 13,

                      height: 1.5,
                    ),
                  )
                else
                  const Text(
                    'No additional message.',

                    style: TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,

                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.background,

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Text(
                    'Type: ${_formatType(type)}',

                    style: const TextStyle(
                      color: AppColors.textSecondary,

                      fontSize: 11,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  height: 50,

                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },

                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================

  // DELETE SWIPE

  // ============================================================

  Widget _buildDismissible(Map<String, dynamic> notification, Widget child) {
    final id = _notificationId(notification);

    if (id == null) {
      return child;
    }

    return Dismissible(
      key: ValueKey('notification_$id'),

      direction: DismissDirection.endToStart,

      background: Container(
        alignment: Alignment.centerRight,

        padding: const EdgeInsets.only(right: 20),

        decoration: BoxDecoration(
          color: AppColors.expense,

          borderRadius: BorderRadius.circular(18),
        ),

        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),

      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,

          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.surface,

              title: const Text(
                'Delete notification?',

                style: TextStyle(
                  color: AppColors.textPrimary,

                  fontWeight: FontWeight.w700,
                ),
              ),

              content: const Text(
                'This notification will be permanently removed.',

                style: TextStyle(color: AppColors.textSecondary),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },

                  child: const Text('Cancel'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },

                  child: const Text(
                    'Delete',

                    style: TextStyle(
                      color: AppColors.expense,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },

      onDismissed: (_) async {
        try {
          await ApiService.deleteNotification(id);

          if (!mounted) return;

          setState(() {
            _notifications.removeWhere((item) => _notificationId(item) == id);
          });
        } catch (error) {
          if (!mounted) return;

          _showMessage('Could not delete notification: $error');

          await _loadNotifications();
        }
      },

      child: child,
    );
  }

  // ============================================================

  // BUILD

  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: const Text(
          'Notifications',

          style: TextStyle(
            color: AppColors.textPrimary,

            fontSize: 20,

            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          if (_unreadCount > 0)
            IconButton(
              onPressed: _isActionLoading ? null : _markAllAsRead,

              tooltip: 'Mark all as read',

              icon: const Icon(
                Icons.done_all_rounded,

                color: AppColors.primary,
              ),
            ),

          PopupMenuButton<String>(
            enabled: !_isActionLoading && _notifications.isNotEmpty,

            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllNotifications();
              }
            },

            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete_all',

                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,

                      color: AppColors.expense,

                      size: 19,
                    ),

                    SizedBox(width: 10),

                    Text('Delete all'),
                  ],
                ),
              ),
            ],

            icon: const Icon(
              Icons.more_vert_rounded,

              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,

              onRefresh: _loadNotifications,

              child: Column(
                children: [
                  _buildHeader(),

                  _buildFilter(),

                  Expanded(child: _buildNotificationList()),
                ],
              ),
            ),
    );
  }

  // ============================================================

  // HEADER

  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Stay updated',

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: 24,

                    fontWeight: FontWeight.w700,

                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _unreadCount == 0
                      ? 'You are all caught up.'
                      : '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}.',

                  style: const TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),

              decoration: BoxDecoration(
                color: AppColors.primaryLight,

                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                '$_unreadCount new',

                style: const TextStyle(
                  color: AppColors.primary,

                  fontSize: 10,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================

  // FILTER

  // ============================================================

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),

      child: Container(
        height: 46,

        padding: const EdgeInsets.all(4),

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: AppColors.border),
        ),

        child: Row(
          children: [
            Expanded(
              child: _buildFilterButton(
                title: 'All',

                selected: _selectedFilter == 0,

                onTap: () {
                  setState(() {
                    _selectedFilter = 0;
                  });
                },
              ),
            ),

            Expanded(
              child: _buildFilterButton(
                title: 'Unread',

                selected: _selectedFilter == 1,

                onTap: () {
                  setState(() {
                    _selectedFilter = 1;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String title,

    required bool selected,

    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,

          borderRadius: BorderRadius.circular(10),
        ),

        child: Text(
          title,

          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,

            fontSize: 12,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================

  // LIST

  // ============================================================

  Widget _buildNotificationList() {
    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(24, 25, 24, 100),

        children: [_buildEmptyState()],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),

      itemCount: notifications.length,

      itemBuilder: (context, index) {
        final notification = notifications[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),

          child: _buildDismissible(
            notification,

            _buildNotificationCard(notification),
          ),
        );
      },
    );
  }

  // ============================================================

  // NOTIFICATION CARD

  // ============================================================

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final read = _isRead(notification);

    final title = notification['title']?.toString() ?? 'Notification';

    final message = notification['message']?.toString() ?? '';

    final type = notification['type']?.toString() ?? 'general';

    final date = notification['created_at']?.toString() ?? '';

    final color = _notificationColor(type);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          _openNotification(notification);
        },

        borderRadius: BorderRadius.circular(18),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: read
                ? AppColors.surface
                : AppColors.primaryLight.withValues(alpha: 0.55),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: read
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.20),
            ),
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 46,

                height: 46,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(_notificationIcon(type), color: color, size: 21),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Text(
                            title,

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: AppColors.textPrimary,

                              fontSize: 13,

                              fontWeight: read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),

                        if (!read)
                          Container(
                            width: 7,

                            height: 7,

                            margin: const EdgeInsets.only(top: 5, left: 7),

                            decoration: const BoxDecoration(
                              color: AppColors.primary,

                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 5),

                      Text(
                        message,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: AppColors.textSecondary,

                          fontSize: 11,

                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    Text(
                      _formatDate(date),

                      style: const TextStyle(
                        color: AppColors.textMuted,

                        fontSize: 9,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,

                icon: const Icon(
                  Icons.more_horiz_rounded,

                  color: AppColors.textMuted,

                  size: 20,
                ),

                onSelected: (value) {
                  if (value == 'read') {
                    _markAsRead(notification);
                  }

                  if (value == 'delete') {
                    _deleteNotification(notification);
                  }
                },

                itemBuilder: (context) {
                  return [
                    if (!read)
                      const PopupMenuItem<String>(
                        value: 'read',

                        child: Row(
                          children: [
                            Icon(Icons.done_rounded, size: 18),

                            SizedBox(width: 9),

                            Text('Mark as read'),
                          ],
                        ),
                      ),

                    const PopupMenuItem<String>(
                      value: 'delete',

                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,

                            color: AppColors.expense,

                            size: 18,
                          ),

                          SizedBox(width: 9),

                          Text('Delete'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================

  // EMPTY STATE

  // ============================================================

  Widget _buildEmptyState() {
    final unreadOnly = _selectedFilter == 1;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        children: [
          Container(
            width: 64,

            height: 64,

            decoration: const BoxDecoration(
              color: AppColors.primaryLight,

              shape: BoxShape.circle,
            ),

            child: Icon(
              unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,

              color: AppColors.primary,

              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            unreadOnly ? 'No unread notifications' : 'No notifications',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: AppColors.textPrimary,

              fontSize: 16,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            unreadOnly
                ? 'You have read all your notifications.'
                : 'You are all caught up. New alerts will appear here.',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: AppColors.textSecondary,

              fontSize: 12,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // NOTIFICATION ICON

  // ============================================================

  IconData _notificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'bill':
        return Icons.receipt_long_rounded;

      case 'emi':
        return Icons.credit_card_rounded;

      case 'debt':
      case 'borrow':
      case 'lend':
        return Icons.handshake_rounded;

      case 'transaction':
        return Icons.swap_horiz_rounded;

      case 'reminder':
        return Icons.alarm_rounded;

      case 'warning':
        return Icons.warning_amber_rounded;

      case 'success':
        return Icons.check_circle_outline_rounded;

      case 'system':
        return Icons.settings_outlined;

      default:
        return Icons.notifications_rounded;
    }
  }

  // ============================================================

  // NOTIFICATION COLOR

  // ============================================================

  Color _notificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'bill':
        return AppColors.info;

      case 'emi':
        return const Color(0xFF8E5AD9);

      case 'debt':
      case 'borrow':
      case 'lend':
        return AppColors.warning;

      case 'transaction':
        return AppColors.primary;

      case 'reminder':
        return const Color(0xFF4C8DFF);

      case 'warning':
        return AppColors.warning;

      case 'success':
        return AppColors.income;

      case 'system':
        return AppColors.textSecondary;

      default:
        return AppColors.primary;
    }
  }

  // ============================================================

  // FORMAT TYPE

  // ============================================================

  String _formatType(String type) {
    if (type.isEmpty) {
      return 'General';
    }

    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  // ============================================================

  // FORMAT DATE

  // ============================================================

  String _formatDate(String value) {
    if (value.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(value).toLocal();

      final now = DateTime.now();

      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      }

      final day = date.day.toString().padLeft(2, '0');

      final month = date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }

  // ============================================================

  // MESSAGE

  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
