import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/rest_api_client.dart';
import '../../core/theme/app_theme.dart';
import '../welcome/welcome_screen.dart';
import 'admin_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.repository = const AdminApiService(),
  });

  final AdminRepository repository;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminSnapshot? _snapshot;
  String? _error;
  bool _isLoading = true;
  bool _isMutating = false;
  int _section = 0;
  int _authorSection = 0;
  int _commerceSection = 0;
  String _bookFilter = 'all';
  String _bookSearch = '';
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await widget.repository.load();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } on RestApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể tải dữ liệu: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runAction(String successMessage, Future<void> action) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await action;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on RestApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xử lý: $error')));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _openBookEditor([AdminBook? book]) async {
    final input = await showModalBottomSheet<AdminBookInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171719),
      builder: (_) => _BookEditorSheet(book: book),
    );
    if (input == null) return;
    await _runAction(
      book == null ? 'Đã thêm truyện mới.' : 'Đã cập nhật truyện.',
      book == null
          ? widget.repository.createBook(input)
          : widget.repository.updateBook(book.id, input),
    );
  }

  Future<void> _moderateBook(AdminBook book, String status) async {
    var note = '';
    if (status == 'rejected') {
      final result = await _askReason(
        title: 'Từ chối “${book.title}”',
        hint: 'Nêu rõ nội dung cần tác giả chỉnh sửa',
        required: true,
      );
      if (result == null) return;
      note = result;
    } else {
      final confirmed = await _confirm(
        title: 'Duyệt truyện?',
        message: '“${book.title}” sẽ được hiển thị cho độc giả.',
        action: 'DUYỆT',
      );
      if (!confirmed) return;
    }
    await _runAction(
      status == 'approved' ? 'Đã duyệt truyện.' : 'Đã từ chối truyện.',
      widget.repository.moderateBook(book.id, status, note: note),
    );
  }

  Future<void> _toggleBookLock(AdminBook book) async {
    var reason = '';
    if (!book.isLocked) {
      final result = await _askReason(
        title: 'Khóa “${book.title}”',
        hint: 'Ví dụ: vi phạm bản quyền hoặc nội dung',
        required: true,
      );
      if (result == null) return;
      reason = result;
    } else {
      final confirmed = await _confirm(
        title: 'Mở khóa truyện?',
        message: 'Truyện sẽ hoạt động lại theo trạng thái kiểm duyệt hiện tại.',
        action: 'MỞ KHÓA',
      );
      if (!confirmed) return;
    }
    await _runAction(
      book.isLocked ? 'Đã mở khóa truyện.' : 'Đã khóa truyện.',
      widget.repository.lockBook(book.id, !book.isLocked, reason: reason),
    );
  }

  Future<void> _reviewApplication(
    AdminAuthorApplication application,
    String status,
  ) async {
    var note = '';
    if (status == 'rejected') {
      final result = await _askReason(
        title: 'Từ chối hồ sơ',
        hint: 'Lý do từ chối hoặc giấy tờ cần bổ sung',
        required: true,
      );
      if (result == null) return;
      note = result;
    } else {
      final confirmed = await _confirm(
        title: 'Duyệt tác giả?',
        message:
            '${application.realName} sẽ được cấp quyền tác giả và có thể gửi truyện.',
        action: 'DUYỆT',
      );
      if (!confirmed) return;
    }
    await _runAction(
      status == 'approved' ? 'Đã duyệt tác giả.' : 'Đã từ chối hồ sơ.',
      widget.repository.reviewAuthorApplication(
        application.id,
        status,
        note: note,
      ),
    );
  }

  Future<void> _editAuthor(AdminAuthor author) async {
    final updated = await showModalBottomSheet<AdminAuthor>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171719),
      builder: (_) => _AuthorEditorSheet(author: author),
    );
    if (updated == null) return;
    await _runAction(
      'Đã cập nhật tác giả.',
      widget.repository.updateAuthor(updated),
    );
  }

  Future<void> _toggleAuthorLock(AdminAuthor author) async {
    var reason = '';
    if (author.status != 'locked') {
      final result = await _askReason(
        title: 'Khóa tác giả',
        hint: 'Nhập lý do khóa quyền đăng truyện',
        required: true,
      );
      if (result == null) return;
      reason = result;
    } else {
      final confirmed = await _confirm(
        title: 'Mở khóa tác giả?',
        message: '${author.displayName} sẽ được phép hoạt động trở lại.',
        action: 'MỞ KHÓA',
      );
      if (!confirmed) return;
    }
    await _runAction(
      author.status == 'locked' ? 'Đã mở khóa tác giả.' : 'Đã khóa tác giả.',
      widget.repository.lockAuthor(
        author.id,
        author.status != 'locked',
        reason: reason,
      ),
    );
  }

  Future<void> _updateOrderStatus(AdminOrder order, String status) async {
    if (order.status == status) return;
    if (status == 'cancelled') {
      final confirmed = await _confirm(
        title: 'Hủy đơn #${order.id}?',
        message: 'Đơn hàng sẽ được chuyển sang trạng thái đã hủy.',
        action: 'HỦY ĐƠN',
      );
      if (!confirmed) return;
    }
    await _runAction(
      'Đã cập nhật trạng thái đơn #${order.id}.',
      widget.repository.updateOrderStatus(order.id, status),
    );
  }

  Future<void> _reviewQrPayment(AdminOrder order, bool approved) async {
    final paymentId = order.paymentId;
    if (paymentId == null) return;
    final confirmed = await _confirm(
      title: approved ? 'Xác nhận đã nhận tiền?' : 'Từ chối thanh toán?',
      message: approved
          ? 'Đơn #${order.id} sẽ bắt đầu quy trình chuẩn bị và giao hàng.'
          : 'Đơn #${order.id} sẽ bị hủy vì không xác nhận được giao dịch.',
      action: approved ? 'XÁC NHẬN TIỀN' : 'TỪ CHỐI',
    );
    if (!confirmed) return;
    await _runAction(
      approved
          ? 'Đã xác nhận thanh toán đơn #${order.id}.'
          : 'Đã từ chối thanh toán đơn #${order.id}.',
      widget.repository.updatePaymentStatus(
        paymentId,
        approved ? 'paid' : 'failed',
      ),
    );
  }

  Future<void> _addShippingEvent(AdminOrder order) async {
    final input = await showModalBottomSheet<_ShippingEventInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171719),
      builder: (_) => _ShippingEventSheet(order: order),
    );
    if (input == null) return;
    await _runAction(
      'Đã cập nhật hành trình đơn #${order.id}.',
      widget.repository.addShippingEvent(
        order.id,
        status: input.status,
        location: input.location,
        description: input.description,
      ),
    );
  }

  Future<void> _updatePaymentStatus(AdminPayment payment, String status) async {
    if (payment.status == status) return;
    if (status == 'refunded') {
      final confirmed = await _confirm(
        title: 'Hoàn tiền giao dịch #${payment.id}?',
        message: 'Đơn hàng hoặc gói hội viên liên quan cũng sẽ bị hủy.',
        action: 'HOÀN TIỀN',
      );
      if (!confirmed) return;
    }
    await _runAction(
      'Đã cập nhật giao dịch #${payment.id}.',
      widget.repository.updatePaymentStatus(payment.id, status),
    );
  }

  Future<void> _editUser(AdminUserAccount user) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171719),
      builder: (_) => _UserEditorSheet(user: user),
    );
    if (result == null) return;
    await _runAction(
      'Đã cập nhật tài khoản ${user.identifier}.',
      widget.repository.updateUser(user.id, role: result.$1, status: result.$2),
    );
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
    required bool required,
  }) async {
    final controller = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF222225),
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hint,
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('HỦY'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (required && value.isEmpty) {
                  setDialogState(() => error = 'Vui lòng nhập lý do.');
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('XÁC NHẬN'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF222225),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('HỦY'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _logout() async {
    final confirmed = await _confirm(
      title: 'Đăng xuất?',
      message: 'Bạn sẽ rời Trung tâm quản trị và quay về màn hình chào mừng.',
      action: 'ĐĂNG XUẤT',
    );
    if (!confirmed || !mounted) return;
    AuthSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    const subtitles = [
      'Tình hình vận hành hệ thống',
      'Xuất bản và kiểm duyệt nội dung',
      'Hồ sơ và quyền tác giả',
      'Đơn hàng và dòng tiền',
      'Tài khoản và phân quyền',
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF09090A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101011),
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trung tâm quản trị',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              subtitles[_section],
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Thêm truyện',
            onPressed: _isMutating || (_section != 0 && _section != 1)
                ? null
                : () => _openBookEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            key: const ValueKey('admin-logout'),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading && snapshot == null)
            const Center(child: CircularProgressIndicator())
          else if (_error != null && snapshot == null)
            _AdminError(message: _error!, onRetry: _load)
          else if (snapshot != null)
            switch (_section) {
              0 => _OverviewSection(
                snapshot: snapshot,
                onRefresh: _load,
                onOpenBooks: () => setState(() => _section = 1),
                onOpenAuthors: () => setState(() => _section = 2),
                onModerateBook: _moderateBook,
                onReviewApplication: _reviewApplication,
              ),
              1 => _BooksSection(
                books: snapshot.books,
                filter: _bookFilter,
                search: _bookSearch,
                onFilterChanged: (value) => setState(() => _bookFilter = value),
                onSearchChanged: (value) => setState(() => _bookSearch = value),
                onRefresh: _load,
                onAdd: () => _openBookEditor(),
                onEdit: _openBookEditor,
                onModerate: _moderateBook,
                onToggleLock: _toggleBookLock,
              ),
              2 => _AuthorsSection(
                applications: snapshot.authorApplications,
                authors: snapshot.authors,
                section: _authorSection,
                onSectionChanged: (value) =>
                    setState(() => _authorSection = value),
                onRefresh: _load,
                onReview: _reviewApplication,
                onEdit: _editAuthor,
                onToggleLock: _toggleAuthorLock,
              ),
              3 => _CommerceSection(
                orders: snapshot.orders,
                payments: snapshot.payments,
                section: _commerceSection,
                onSectionChanged: (value) =>
                    setState(() => _commerceSection = value),
                onRefresh: _load,
                onOrderStatusChanged: _updateOrderStatus,
                onPaymentStatusChanged: _updatePaymentStatus,
                onReviewQrPayment: _reviewQrPayment,
                onAddShippingEvent: _addShippingEvent,
              ),
              _ => _SystemSection(
                users: snapshot.users,
                search: _userSearch,
                currentUserId: AuthSession.current?.user.id,
                onSearchChanged: (value) => setState(() => _userSearch = value),
                onRefresh: _load,
                onEdit: _editUser,
              ),
            },
          if (_isMutating)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _AdminBottomNavigation(
        selected: _section,
        onChanged: (value) => setState(() => _section = value),
      ),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onChanged,
      height: 72,
      backgroundColor: const Color(0xFF111113),
      indicatorColor: WakaColors.accent.withValues(alpha: 0.18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          key: ValueKey('admin-section-0'),
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          key: ValueKey('admin-section-1'),
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories_rounded),
          label: 'Truyện',
        ),
        NavigationDestination(
          key: ValueKey('admin-section-2'),
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group_rounded),
          label: 'Tác giả',
        ),
        NavigationDestination(
          key: ValueKey('admin-section-3'),
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Đơn hàng',
        ),
        NavigationDestination(
          key: ValueKey('admin-section-4'),
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts_rounded),
          label: 'Hệ thống',
        ),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.snapshot,
    required this.onRefresh,
    required this.onOpenBooks,
    required this.onOpenAuthors,
    required this.onModerateBook,
    required this.onReviewApplication,
  });

  final AdminSnapshot snapshot;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBooks;
  final VoidCallback onOpenAuthors;
  final Future<void> Function(AdminBook, String) onModerateBook;
  final Future<void> Function(AdminAuthorApplication, String)
  onReviewApplication;

  @override
  Widget build(BuildContext context) {
    final metrics = snapshot.metrics;
    final pendingBooks = snapshot.books
        .where((book) => book.moderationStatus == 'pending')
        .take(3)
        .toList();
    final pendingAuthors = snapshot.authorApplications
        .where((application) => application.status == 'pending')
        .take(3)
        .toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          const _AdminIntroCard(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 1.35 : 1.25,
                children: [
                  _MetricCard(
                    label: 'Truyện chờ duyệt',
                    value: metrics.pendingBooks,
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFFFB547),
                  ),
                  _MetricCard(
                    label: 'Hồ sơ tác giả',
                    value: metrics.pendingAuthorApplications,
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF7AA7FF),
                  ),
                  _MetricCard(
                    label: 'Truyện đang khóa',
                    value: metrics.lockedBooks,
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFFFF6577),
                  ),
                  _MetricCard(
                    label: 'Tác giả hoạt động',
                    value: metrics.activeAuthors,
                    icon: Icons.verified_user_outlined,
                    color: WakaColors.accent,
                  ),
                  _MetricCard(
                    label: 'Tổng đơn hàng',
                    value: metrics.totalOrders,
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFFB69CFF),
                  ),
                  _MetricCard(
                    label: 'Giao dịch thành công',
                    value: metrics.paidPayments,
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF5ED6C0),
                  ),
                  _MetricCard(
                    label: 'Tài khoản',
                    value: metrics.totalUsers,
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF8EB1FF),
                  ),
                  _MetricCard(
                    label: 'Tài khoản bị khóa',
                    value: metrics.lockedUsers,
                    icon: Icons.person_off_outlined,
                    color: const Color(0xFFFF7585),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeading(
            title: 'Truyện cần kiểm duyệt',
            count: metrics.pendingBooks,
            onSeeAll: onOpenBooks,
          ),
          const SizedBox(height: 10),
          if (pendingBooks.isEmpty)
            const _EmptyAdminCard(
              icon: Icons.task_alt_rounded,
              message: 'Không còn truyện chờ duyệt.',
            )
          else
            for (final book in pendingBooks) ...[
              _BookModerationCard(
                book: book,
                compact: true,
                onApprove: () => onModerateBook(book, 'approved'),
                onReject: () => onModerateBook(book, 'rejected'),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          _SectionHeading(
            title: 'Đăng ký tác giả',
            count: metrics.pendingAuthorApplications,
            onSeeAll: onOpenAuthors,
          ),
          const SizedBox(height: 10),
          if (pendingAuthors.isEmpty)
            const _EmptyAdminCard(
              icon: Icons.how_to_reg_rounded,
              message: 'Không còn hồ sơ tác giả chờ duyệt.',
            )
          else
            for (final application in pendingAuthors) ...[
              _ApplicationCard(
                application: application,
                onApprove: () => onReviewApplication(application, 'approved'),
                onReject: () => onReviewApplication(application, 'rejected'),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _BooksSection extends StatelessWidget {
  const _BooksSection({
    required this.books,
    required this.filter,
    required this.search,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.onModerate,
    required this.onToggleLock,
  });

  final List<AdminBook> books;
  final String filter;
  final String search;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<AdminBook> onEdit;
  final Future<void> Function(AdminBook, String) onModerate;
  final ValueChanged<AdminBook> onToggleLock;

  @override
  Widget build(BuildContext context) {
    final normalized = search.trim().toLowerCase();
    final visibleBooks = books.where((book) {
      final matchesFilter = switch (filter) {
        'locked' => book.isLocked,
        'all' => true,
        _ => book.moderationStatus == filter,
      };
      final matchesSearch =
          normalized.isEmpty ||
          book.title.toLowerCase().contains(normalized) ||
          book.author.toLowerCase().contains(normalized);
      return matchesFilter && matchesSearch;
    }).toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('admin-book-search'),
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên truyện hoặc tác giả',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFF19191B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                key: const ValueKey('admin-add-book'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('THÊM'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: WakaColors.accent,
                  minimumSize: const Size(0, 54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in const [
                  ('all', 'Tất cả'),
                  ('pending', 'Chờ duyệt'),
                  ('approved', 'Đã duyệt'),
                  ('rejected', 'Từ chối'),
                  ('locked', 'Đang khóa'),
                ]) ...[
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: filter == item.$1,
                    onSelected: (_) => onFilterChanged(item.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${visibleBooks.length} truyện',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          if (visibleBooks.isEmpty)
            const _EmptyAdminCard(
              icon: Icons.menu_book_outlined,
              message: 'Không tìm thấy truyện phù hợp.',
            )
          else
            for (final book in visibleBooks) ...[
              _BookManagementCard(
                book: book,
                onEdit: () => onEdit(book),
                onApprove: () => onModerate(book, 'approved'),
                onReject: () => onModerate(book, 'rejected'),
                onToggleLock: () => onToggleLock(book),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AuthorsSection extends StatelessWidget {
  const _AuthorsSection({
    required this.applications,
    required this.authors,
    required this.section,
    required this.onSectionChanged,
    required this.onRefresh,
    required this.onReview,
    required this.onEdit,
    required this.onToggleLock,
  });

  final List<AdminAuthorApplication> applications;
  final List<AdminAuthor> authors;
  final int section;
  final ValueChanged<int> onSectionChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AdminAuthorApplication, String) onReview;
  final ValueChanged<AdminAuthor> onEdit;
  final ValueChanged<AdminAuthor> onToggleLock;

  @override
  Widget build(BuildContext context) {
    final pending = applications
        .where((application) => application.status == 'pending')
        .toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                icon: const Icon(Icons.pending_actions_rounded),
                label: Text('Chờ duyệt (${pending.length})'),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.people_alt_outlined),
                label: Text('Tác giả (${authors.length})'),
              ),
            ],
            selected: {section},
            onSelectionChanged: (values) => onSectionChanged(values.first),
          ),
          const SizedBox(height: 18),
          if (section == 0) ...[
            if (pending.isEmpty)
              const _EmptyAdminCard(
                icon: Icons.how_to_reg_rounded,
                message: 'Không còn hồ sơ chờ duyệt.',
              )
            else
              for (final application in pending) ...[
                _ApplicationCard(
                  application: application,
                  expanded: true,
                  onApprove: () => onReview(application, 'approved'),
                  onReject: () => onReview(application, 'rejected'),
                ),
                const SizedBox(height: 10),
              ],
          ] else ...[
            if (authors.isEmpty)
              const _EmptyAdminCard(
                icon: Icons.person_search_rounded,
                message: 'Chưa có tác giả đã được duyệt.',
              )
            else
              for (final author in authors) ...[
                _AuthorCard(
                  author: author,
                  onEdit: () => onEdit(author),
                  onToggleLock: () => onToggleLock(author),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _CommerceSection extends StatelessWidget {
  const _CommerceSection({
    required this.orders,
    required this.payments,
    required this.section,
    required this.onSectionChanged,
    required this.onRefresh,
    required this.onOrderStatusChanged,
    required this.onPaymentStatusChanged,
    required this.onReviewQrPayment,
    required this.onAddShippingEvent,
  });

  final List<AdminOrder> orders;
  final List<AdminPayment> payments;
  final int section;
  final ValueChanged<int> onSectionChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AdminOrder, String) onOrderStatusChanged;
  final Future<void> Function(AdminPayment, String) onPaymentStatusChanged;
  final Future<void> Function(AdminOrder, bool) onReviewQrPayment;
  final ValueChanged<AdminOrder> onAddShippingEvent;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text('Đơn hàng (${orders.length})'),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.payments_outlined),
                label: Text('Giao dịch (${payments.length})'),
              ),
            ],
            selected: {section},
            onSelectionChanged: (values) => onSectionChanged(values.first),
          ),
          const SizedBox(height: 16),
          if (section == 0) ...[
            if (orders.isEmpty)
              const _EmptyAdminCard(
                icon: Icons.inventory_2_outlined,
                message: 'Chưa có đơn hàng trong hệ thống.',
              )
            else
              for (final order in orders) ...[
                _AdminOrderCard(
                  order: order,
                  onStatusChanged: (status) {
                    onOrderStatusChanged(order, status);
                  },
                  onApprovePayment: () => onReviewQrPayment(order, true),
                  onRejectPayment: () => onReviewQrPayment(order, false),
                  onAddShippingEvent: () => onAddShippingEvent(order),
                ),
                const SizedBox(height: 10),
              ],
          ] else ...[
            if (payments.isEmpty)
              const _EmptyAdminCard(
                icon: Icons.account_balance_wallet_outlined,
                message: 'Chưa có giao dịch thanh toán.',
              )
            else
              for (final payment in payments) ...[
                _AdminPaymentCard(
                  payment: payment,
                  onStatusChanged: (status) {
                    onPaymentStatusChanged(payment, status);
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.onStatusChanged,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onAddShippingEvent,
  });

  final AdminOrder order;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApprovePayment;
  final VoidCallback onRejectPayment;
  final VoidCallback onAddShippingEvent;

  @override
  Widget build(BuildContext context) {
    final customer = order.customerName.isEmpty
        ? order.account
        : order.customerName;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF213D37),
                child: Text(
                  '#${order.id}',
                  style: const TextStyle(
                    color: WakaColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${order.itemCount} sản phẩm · ${_formatDate(order.createdAt)}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
              if (order.status == 'cancelled')
                _StatusMenu(
                  value: order.status,
                  values: const ['cancelled'],
                  onChanged: onStatusChanged,
                ),
            ],
          ),
          const SizedBox(height: 9),
          _TinyBadge(
            label: _adminPaymentLabel(order.paymentMethod, order.paymentStatus),
            color: order.paymentStatus == 'paid'
                ? WakaColors.accent
                : const Color(0xFFFFBD5A),
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in order.items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
          ],
          if (order.shippingAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${order.shippingRecipient} · ${order.shippingPhone}\n${order.shippingAddress}',
              style: const TextStyle(color: Colors.white54, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              Text(
                _money(order.total),
                style: const TextStyle(
                  color: WakaColors.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.paymentMethod == 'bank_qr' &&
              order.paymentStatus == 'proof_submitted')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRejectPayment,
                    child: const Text('TỪ CHỐI'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('admin-confirm-payment-${order.id}'),
                    onPressed: onApprovePayment,
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('XÁC NHẬN TIỀN'),
                    style: FilledButton.styleFrom(
                      backgroundColor: WakaColors.accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            )
          else if (order.status != 'cancelled' && order.status != 'delivered')
            FilledButton.icon(
              key: ValueKey('admin-shipping-event-${order.id}'),
              onPressed: onAddShippingEvent,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('CẬP NHẬT KHO VẬN'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(0xFF263A36),
                foregroundColor: WakaColors.accent,
              ),
            ),
          if (order.shippingEvents.isNotEmpty) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final latest = order.shippingEvents.last;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: WakaColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${_statusLabel(latest.status)} · ${latest.location}\n${latest.description}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({
    required this.payment,
    required this.onStatusChanged,
  });

  final AdminPayment payment;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final subject = payment.orderId != null
        ? 'Đơn hàng #${payment.orderId}'
        : payment.membershipTitle.isEmpty
        ? 'Gói hội viên'
        : payment.membershipTitle;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF242D42),
                child: Icon(Icons.payments_outlined, color: Color(0xFF8EB1FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      payment.customerName.isEmpty
                          ? payment.account
                          : payment.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: payment.status),
              _StatusMenu(
                value: payment.status,
                values: const [
                  'pending',
                  'proof_submitted',
                  'paid',
                  'failed',
                  'refunded',
                ],
                onChanged: onStatusChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            payment.transactionRef,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${payment.provider.toUpperCase()} · ${_formatDate(payment.createdAt)}',
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              Text(
                _money(payment.amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Đổi trạng thái',
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final status in values)
          PopupMenuItem(
            value: status,
            child: Row(
              children: [
                if (status == value)
                  const Icon(Icons.check_rounded, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(_statusLabel(status)),
              ],
            ),
          ),
      ],
    );
  }
}

class _SystemSection extends StatelessWidget {
  const _SystemSection({
    required this.users,
    required this.search,
    required this.currentUserId,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onEdit,
  });

  final List<AdminUserAccount> users;
  final String search;
  final int? currentUserId;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<AdminUserAccount> onEdit;

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final visible = users.where((user) {
      return query.isEmpty ||
          user.identifier.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          TextField(
            key: const ValueKey('admin-user-search'),
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm email, tên hoặc quyền tài khoản',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFF19191B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${visible.length} tài khoản',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const _EmptyAdminCard(
              icon: Icons.person_search_rounded,
              message: 'Không tìm thấy tài khoản phù hợp.',
            )
          else
            for (final user in visible) ...[
              _AdminUserCard(
                user: user,
                isCurrent: user.id == currentUserId,
                onEdit: () => onEdit(user),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.isCurrent,
    required this.onEdit,
  });

  final AdminUserAccount user;
  final bool isCurrent;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final locked = user.accountStatus == 'locked';
    return _AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: locked
                ? const Color(0xFF4A282D)
                : const Color(0xFF213D37),
            child: Icon(
              locked ? Icons.person_off_outlined : Icons.person_outline,
              color: locked ? const Color(0xFFFF7585) : WakaColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isEmpty ? user.identifier : user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user.identifier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _TinyBadge(
                      label: _roleLabel(user.role),
                      color: const Color(0xFF8EB1FF),
                    ),
                    _StatusBadge(status: user.accountStatus),
                    if (isCurrent)
                      const _TinyBadge(label: 'BẠN', color: WakaColors.accent),
                  ],
                ),
                if (user.orderCount > 0 || user.totalSpent > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${user.orderCount} đơn · ${_money(user.totalSpent)} đã chi',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: isCurrent ? 'Không thể tự sửa quyền' : 'Sửa quyền',
            onPressed: isCurrent ? null : onEdit,
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
        ],
      ),
    );
  }
}

class _AdminIntroCard extends StatelessWidget {
  const _AdminIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF063E35), Color(0xFF12231F)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WakaColors.accent.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0x3300D9A5),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: WakaColors.accent,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vận hành Waka',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Theo dõi nội dung, doanh thu, giao dịch và tài khoản trong một nơi.',
                  style: TextStyle(color: Colors.white60, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.count,
    required this.onSeeAll,
  });

  final String title;
  final int count;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB547).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFFFFC568),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        TextButton(onPressed: onSeeAll, child: const Text('XEM TẤT CẢ')),
      ],
    );
  }
}

class _BookModerationCard extends StatelessWidget {
  const _BookModerationCard({
    required this.book,
    required this.onApprove,
    required this.onReject,
    this.compact = false,
  });

  final AdminBook book;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminBookCover(book: book),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        child: const Text('TỪ CHỐI'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: WakaColors.accent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('DUYỆT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookManagementCard extends StatelessWidget {
  const _BookManagementCard({
    required this.book,
    required this.onEdit,
    required this.onApprove,
    required this.onReject,
    required this.onToggleLock,
  });

  final AdminBook book;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminBookCover(book: book, width: 70),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'lock') onToggleLock();
                        if (value == 'approve') onApprove();
                        if (value == 'reject') onReject();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Sửa truyện'),
                        ),
                        if (book.moderationStatus != 'approved')
                          const PopupMenuItem(
                            value: 'approve',
                            child: Text('Duyệt truyện'),
                          ),
                        if (book.moderationStatus != 'rejected')
                          const PopupMenuItem(
                            value: 'reject',
                            child: Text('Từ chối'),
                          ),
                        PopupMenuItem(
                          value: 'lock',
                          child: Text(
                            book.isLocked ? 'Mở khóa' : 'Khóa truyện',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${book.author} · ${_money(book.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _StatusBadge(status: book.moderationStatus),
                    if (book.isLocked) const _StatusBadge(status: 'locked'),
                    if (book.isFeatured)
                      const _TinyBadge(
                        label: 'NỔI BẬT',
                        color: Color(0xFF9A75FF),
                      ),
                  ],
                ),
                if (book.isLocked && book.lockReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lý do khóa: ${book.lockReason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFF8B98),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
    this.expanded = false,
  });

  final AdminAuthorApplication application;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final initials = application.realName.trim().isEmpty
        ? 'TG'
        : application.realName
              .trim()
              .split(RegExp(r'\s+'))
              .last
              .characters
              .first;
    return _AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF263B38),
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: WakaColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.realName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (application.penName.isNotEmpty)
                      Text(
                        'Bút danh: ${application.penName}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    Text(
                      application.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusBadge(status: 'pending'),
            ],
          ),
          if (expanded && application.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                application.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('TỪ CHỐI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('DUYỆT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: WakaColors.accent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.author,
    required this.onEdit,
    required this.onToggleLock,
  });

  final AdminAuthor author;
  final VoidCallback onEdit;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: author.status == 'locked'
                ? const Color(0xFF4A282D)
                : const Color(0xFF213D37),
            child: Icon(
              author.status == 'locked'
                  ? Icons.person_off_outlined
                  : Icons.person_outline_rounded,
              color: author.status == 'locked'
                  ? const Color(0xFFFF7D8B)
                  : WakaColors.accent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  author.penName.isEmpty
                      ? author.email
                      : '${author.penName} · ${author.bookCount} truyện',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 6),
                _StatusBadge(status: author.status),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sửa',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: author.status == 'locked' ? 'Mở khóa' : 'Khóa',
            onPressed: onToggleLock,
            icon: Icon(
              author.status == 'locked'
                  ? Icons.lock_open_rounded
                  : Icons.lock_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBookCover extends StatelessWidget {
  const _AdminBookCover({required this.book, this.width = 58});

  final AdminBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFF263A36),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_stories_rounded, color: WakaColors.accent),
    );
    return Container(
      width: width,
      height: width * 1.38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: book.imageUrl.isEmpty
          ? fallback
          : Image.network(
              book.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('ĐÃ DUYỆT', WakaColors.accent),
      'paid' => ('ĐÃ THANH TOÁN', WakaColors.accent),
      'proof_submitted' => ('CHỜ XÁC NHẬN TIỀN', const Color(0xFFFFBD5A)),
      'payment_review' => ('CHỜ XÁC NHẬN QR', const Color(0xFFFFBD5A)),
      'confirmed' => ('ĐÃ XÁC NHẬN', const Color(0xFF8EB1FF)),
      'packing' => ('ĐANG ĐÓNG GÓI', const Color(0xFFB69CFF)),
      'in_transit' => ('ĐANG VẬN CHUYỂN', const Color(0xFF8EB1FF)),
      'at_hub' => ('TẠI KHO VẬN', const Color(0xFF8EB1FF)),
      'out_for_delivery' => ('ĐANG GIAO HÀNG', const Color(0xFFFFBD5A)),
      'delivered' => ('ĐÃ GIAO', WakaColors.accent),
      'pending' => ('CHỜ XỬ LÝ', const Color(0xFFFFBD5A)),
      'cancelled' => ('ĐÃ HỦY', const Color(0xFF9FA5B5)),
      'failed' => ('THẤT BẠI', const Color(0xFFFF7585)),
      'refunded' => ('ĐÃ HOÀN TIỀN', const Color(0xFF8EB1FF)),
      'rejected' => ('TỪ CHỐI', const Color(0xFFFF7585)),
      'locked' => ('ĐANG KHÓA', const Color(0xFFFF7585)),
      'active' => ('HOẠT ĐỘNG', WakaColors.accent),
      'draft' => ('BẢN NHÁP', const Color(0xFF9FA5B5)),
      _ => ('CHỜ DUYỆT', const Color(0xFFFFBD5A)),
    };
    return _TinyBadge(label: label, color: color);
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF18181A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _EmptyAdminCard extends StatelessWidget {
  const _EmptyAdminCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 42),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('THỬ LẠI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShippingEventInput {
  const _ShippingEventInput({
    required this.status,
    required this.location,
    required this.description,
  });

  final String status;
  final String location;
  final String description;
}

class _ShippingEventSheet extends StatefulWidget {
  const _ShippingEventSheet({required this.order});

  final AdminOrder order;

  @override
  State<_ShippingEventSheet> createState() => _ShippingEventSheetState();
}

class _ShippingEventSheetState extends State<_ShippingEventSheet> {
  late String _status;
  final _location = TextEditingController();
  final _description = TextEditingController();
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _status = _nextShippingStatus(widget.order.status);
  }

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final location = _location.text.trim();
    if (location.isEmpty && _status != 'cancelled') {
      setState(
        () => _locationError = 'Vui lòng nhập kho hoặc vị trí hiện tại.',
      );
      return;
    }
    Navigator.pop(
      context,
      _ShippingEventInput(
        status: _status,
        location: location,
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật đơn #${widget.order.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.order.shippingAddress,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái giao hàng',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'packing',
                  child: Text('Đang đóng gói'),
                ),
                DropdownMenuItem(
                  value: 'in_transit',
                  child: Text('Đang vận chuyển'),
                ),
                DropdownMenuItem(
                  value: 'at_hub',
                  child: Text('Đã đến kho vận'),
                ),
                DropdownMenuItem(
                  value: 'out_for_delivery',
                  child: Text('Đang giao đến khách'),
                ),
                DropdownMenuItem(
                  value: 'delivered',
                  child: Text('Giao hàng thành công'),
                ),
                DropdownMenuItem(value: 'cancelled', child: Text('Hủy đơn')),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('admin-shipping-location'),
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Kho vận / vị trí hiện tại *',
                hintText: 'Ví dụ: Kho Cầu Giấy, Hà Nội',
                errorText: _locationError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_locationError != null) {
                  setState(() => _locationError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho khách hàng',
                hintText:
                    'Ví dụ: Đơn đã rời kho và đang đến điểm trung chuyển.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('admin-save-shipping-event'),
              onPressed: _submit,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('CẬP NHẬT HÀNH TRÌNH'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: WakaColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserEditorSheet extends StatefulWidget {
  const _UserEditorSheet({required this.user});

  final AdminUserAccount user;

  @override
  State<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<_UserEditorSheet> {
  late String _role;
  late String _status;

  @override
  void initState() {
    super.initState();
    _role = widget.user.role;
    _status = widget.user.accountStatus;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân quyền tài khoản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(user.identifier, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Quyền tài khoản',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'reader', child: Text('Người đọc')),
              DropdownMenuItem(value: 'author', child: Text('Tác giả')),
              DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
            ],
            onChanged: (value) => setState(() => _role = value!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
              DropdownMenuItem(value: 'locked', child: Text('Đã khóa')),
            ],
            onChanged: (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('admin-save-user'),
            onPressed: () => Navigator.pop(context, (_role, _status)),
            icon: const Icon(Icons.save_outlined),
            label: const Text('LƯU THAY ĐỔI'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: WakaColors.accent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookEditorSheet extends StatefulWidget {
  const _BookEditorSheet({this.book});

  final AdminBook? book;

  @override
  State<_BookEditorSheet> createState() => _BookEditorSheetState();
}

class _BookEditorSheetState extends State<_BookEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sourceUrl;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late bool _featured;
  late String _status;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _description = TextEditingController(text: book?.description ?? '');
    _imageUrl = TextEditingController(text: book?.imageUrl ?? '');
    _sourceUrl = TextEditingController(text: book?.sourceUrl ?? '');
    _price = TextEditingController(text: book == null ? '' : '${book.price}');
    _discount = TextEditingController(
      text: book == null ? '0' : '${book.discountPercent}',
    );
    _featured = book?.isFeatured ?? false;
    _status = book?.moderationStatus ?? 'approved';
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _sourceUrl.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AdminBookInput(
        title: _title.text.trim(),
        author: _author.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        sourceUrl: _sourceUrl.text.trim(),
        price: int.tryParse(_price.text.trim()) ?? 0,
        discountPercent: int.tryParse(_discount.text.trim()) ?? 0,
        isFeatured: _featured,
        moderationStatus: _status,
        categoryId: widget.book?.categoryId,
        authorId: widget.book?.authorId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.book == null ? 'Thêm truyện mới' : 'Chỉnh sửa truyện',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _AdminField(
                controller: _title,
                label: 'Tên truyện *',
                validator: _requiredValidator,
              ),
              _AdminField(
                controller: _author,
                label: 'Tác giả *',
                validator: _requiredValidator,
              ),
              _AdminField(
                controller: _description,
                label: 'Giới thiệu',
                minLines: 3,
                maxLines: 5,
              ),
              _AdminField(controller: _imageUrl, label: 'URL ảnh bìa'),
              _AdminField(controller: _sourceUrl, label: 'URL nội dung/nguồn'),
              Row(
                children: [
                  Expanded(
                    child: _AdminField(
                      controller: _price,
                      label: 'Giá (đ)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminField(
                      controller: _discount,
                      label: 'Giảm giá (%)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái xuất bản',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Bản nháp')),
                  DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                  DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đánh dấu nội dung nổi bật'),
                value: _featured,
                onChanged: (value) => setState(() => _featured = value),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const ValueKey('admin-save-book'),
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.book == null ? 'THÊM TRUYỆN' : 'LƯU THAY ĐỔI',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: WakaColors.accent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Không được để trống.';
    return null;
  }
}

class _AuthorEditorSheet extends StatefulWidget {
  const _AuthorEditorSheet({required this.author});

  final AdminAuthor author;

  @override
  State<_AuthorEditorSheet> createState() => _AuthorEditorSheetState();
}

class _AuthorEditorSheetState extends State<_AuthorEditorSheet> {
  late final TextEditingController _displayName;
  late final TextEditingController _penName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final author = widget.author;
    _displayName = TextEditingController(text: author.displayName);
    _penName = TextEditingController(text: author.penName);
    _email = TextEditingController(text: author.email);
    _phone = TextEditingController(text: author.phone);
    _bio = TextEditingController(text: author.bio);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _penName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Chỉnh sửa tác giả',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            _AdminField(controller: _displayName, label: 'Họ và tên *'),
            _AdminField(controller: _penName, label: 'Bút danh'),
            _AdminField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            _AdminField(
              controller: _phone,
              label: 'Điện thoại',
              keyboardType: TextInputType.phone,
            ),
            _AdminField(
              controller: _bio,
              label: 'Giới thiệu',
              minLines: 3,
              maxLines: 5,
            ),
            FilledButton(
              onPressed: () {
                if (_displayName.text.trim().isEmpty) return;
                final author = widget.author;
                Navigator.pop(
                  context,
                  AdminAuthor(
                    id: author.id,
                    account: author.account,
                    displayName: _displayName.text.trim(),
                    penName: _penName.text.trim(),
                    email: _email.text.trim(),
                    phone: _phone.text.trim(),
                    bio: _bio.text.trim(),
                    avatarUrl: author.avatarUrl,
                    status: author.status,
                    lockReason: author.lockReason,
                    bookCount: author.bookCount,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: WakaColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('LƯU THAY ĐỔI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

String _money(int value) {
  final text = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    output.write(text[index]);
    final remaining = text.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) output.write('.');
  }
  return '${output.toString()}đ';
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Không rõ ngày';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _statusLabel(String status) => switch (status) {
  'proof_submitted' => 'Chờ xác nhận tiền',
  'payment_review' => 'Chờ xác nhận QR',
  'confirmed' => 'Đã xác nhận đơn',
  'packing' => 'Đang đóng gói',
  'in_transit' => 'Đang vận chuyển',
  'at_hub' => 'Đã đến kho vận',
  'out_for_delivery' => 'Đang giao đến khách',
  'delivered' => 'Giao hàng thành công',
  'paid' => 'Đã thanh toán',
  'cancelled' => 'Đã hủy',
  'failed' => 'Thất bại',
  'refunded' => 'Đã hoàn tiền',
  _ => 'Chờ xử lý',
};

String _roleLabel(String role) => switch (role) {
  'admin' => 'QUẢN TRỊ',
  'author' => 'TÁC GIẢ',
  _ => 'NGƯỜI ĐỌC',
};

String _nextShippingStatus(String current) => switch (current) {
  'confirmed' => 'packing',
  'packing' => 'in_transit',
  'in_transit' => 'at_hub',
  'at_hub' => 'out_for_delivery',
  'out_for_delivery' => 'delivered',
  _ => 'packing',
};

String _adminPaymentLabel(String method, String status) {
  if (method == 'cod') {
    return status == 'paid' ? 'COD · ĐÃ THU TIỀN' : 'COD · CHƯA THU TIỀN';
  }
  return switch (status) {
    'proof_submitted' => 'QR · CHỜ ADMIN XÁC NHẬN',
    'paid' => 'QR · ĐÃ XÁC NHẬN TIỀN',
    'failed' => 'QR · KHÔNG HỢP LỆ',
    'refunded' => 'QR · ĐÃ HOÀN TIỀN',
    _ => 'QR · CHỜ THANH TOÁN',
  };
}
