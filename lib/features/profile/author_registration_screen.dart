import 'package:flutter/material.dart';

import '../../core/services/author_application_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/rest_api_client.dart';
import '../../core/theme/app_theme.dart';

class AuthorRegistrationScreen extends StatefulWidget {
  const AuthorRegistrationScreen({super.key});

  @override
  State<AuthorRegistrationScreen> createState() =>
      _AuthorRegistrationScreenState();
}

class _AuthorRegistrationScreenState extends State<AuthorRegistrationScreen> {
  static const _service = AuthorApplicationService();
  final _formKey = GlobalKey<FormState>();
  final _realName = TextEditingController();
  final _penName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _portfolio = TextEditingController();
  final _identityDocument = TextEditingController();

  AuthorApplication? _application;
  bool _loading = true;
  bool _submitting = false;
  bool _acceptedTerms = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _email.text = AuthSession.current?.user.identifier ?? '';
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.getMine();
      if (!mounted) return;
      setState(() {
        _application = value;
        _loading = false;
        _error = '';
      });
      if (value != null) _fill(value);
    } on RestApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _fill(AuthorApplication value) {
    _realName.text = value.realName;
    _penName.text = value.penName;
    _email.text = value.email;
    _phone.text = value.phone;
    _bio.text = value.bio;
    _portfolio.text = value.portfolioUrl;
    _identityDocument.text = value.identityDocumentUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng xác nhận cam kết bản quyền.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final value = await _service.submit(
        AuthorApplicationInput(
          realName: _realName.text.trim(),
          penName: _penName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          bio: _bio.text.trim(),
          identityDocumentUrl: _identityDocument.text.trim(),
          portfolioUrl: _portfolio.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _application = value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hồ sơ đã được gửi đến quản trị viên.')),
      );
    } on RestApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _realName.dispose();
    _penName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    _portfolio.dispose();
    _identityDocument.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _application?.status;
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(title: const Text('Đăng ký làm tác giả')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _ErrorState(message: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                const _AuthorHero(),
                const SizedBox(height: 22),
                const _Benefits(),
                const SizedBox(height: 24),
                const _ProcessSteps(),
                const SizedBox(height: 24),
                if (_application != null) ...[
                  _ApplicationStatus(application: _application!),
                  const SizedBox(height: 20),
                ],
                if (status != 'pending' && status != 'approved')
                  _buildForm(isResubmission: status == 'rejected'),
              ],
            ),
    );
  }

  Widget _buildForm({required bool isResubmission}) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isResubmission ? 'Bổ sung hồ sơ' : 'Hồ sơ đăng ký',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Thông tin có dấu * là bắt buộc. Admin sẽ dùng thông tin này để xác minh và liên hệ.',
          style: TextStyle(color: Colors.white54, height: 1.4),
        ),
        const SizedBox(height: 18),
        _field(
          _realName,
          'Họ và tên thật *',
          Icons.badge_outlined,
          required: true,
        ),
        _field(_penName, 'Bút danh', Icons.draw_outlined),
        _field(
          _email,
          'Email liên hệ *',
          Icons.email_outlined,
          required: true,
          keyboardType: TextInputType.emailAddress,
        ),
        _field(
          _phone,
          'Số điện thoại',
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _field(
          _bio,
          'Giới thiệu bản thân và định hướng sáng tác',
          Icons.auto_stories_outlined,
          maxLines: 5,
        ),
        _field(
          _portfolio,
          'Liên kết tác phẩm mẫu / portfolio',
          Icons.link_rounded,
          keyboardType: TextInputType.url,
        ),
        _field(
          _identityDocument,
          'Liên kết giấy tờ xác minh (chỉ admin xem)',
          Icons.verified_user_outlined,
          keyboardType: TextInputType.url,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: WakaColors.accent,
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          title: const Text(
            'Tôi cam kết nội dung gửi đăng là tác phẩm hợp pháp và không vi phạm bản quyền.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(isResubmission ? 'GỬI LẠI HỒ SƠ' : 'GỬI HỒ SƠ'),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập $label'
                : null
          : null,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
    ),
  );
}

class _AuthorHero extends StatelessWidget {
  const _AuthorHero();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0C665A), Color(0xFF17344A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Câu chuyện của bạn\nxứng đáng được sẻ chia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Gia nhập cộng đồng tác giả, xuất bản và đưa tác phẩm đến gần hơn với độc giả.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Icon(Icons.edit_note_rounded, color: WakaColors.accent, size: 72),
      ],
    ),
  );
}

class _Benefits extends StatelessWidget {
  const _Benefits();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _Benefit(
          icon: Icons.groups_2_outlined,
          value: 'Độc giả',
          label: 'Tiếp cận cộng đồng',
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: _Benefit(
          icon: Icons.copyright_rounded,
          value: 'Bản quyền',
          label: 'Quản lý minh bạch',
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: _Benefit(
          icon: Icons.insights_rounded,
          value: 'Dữ liệu',
          label: 'Theo dõi tác phẩm',
        ),
      ),
    ],
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(
      color: WakaColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, color: WakaColors.accent),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            height: 1.25,
          ),
        ),
      ],
    ),
  );
}

class _ProcessSteps extends StatelessWidget {
  const _ProcessSteps();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quy trình trở thành tác giả',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      SizedBox(height: 14),
      _Step(
        number: '1',
        title: 'Gửi hồ sơ',
        subtitle: 'Thông tin cá nhân, bút danh và tác phẩm mẫu',
      ),
      _Step(
        number: '2',
        title: 'Waka thẩm định',
        subtitle: 'Admin xác minh hồ sơ và nội dung trong hệ thống',
      ),
      _Step(
        number: '3',
        title: 'Bắt đầu xuất bản',
        subtitle: 'Nhận quyền tác giả và gửi tác phẩm để duyệt',
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final String number, title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: WakaColors.accent,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
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
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ApplicationStatus extends StatelessWidget {
  const _ApplicationStatus({required this.application});
  final AuthorApplication application;
  @override
  Widget build(BuildContext context) {
    final approved = application.status == 'approved';
    final rejected = application.status == 'rejected';
    final color = approved
        ? WakaColors.accent
        : rejected
        ? Colors.redAccent
        : Colors.amber;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved
                ? Icons.verified_rounded
                : rejected
                ? Icons.error_outline_rounded
                : Icons.hourglass_top_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approved
                      ? 'Hồ sơ đã được duyệt'
                      : rejected
                      ? 'Hồ sơ cần bổ sung'
                      : 'Hồ sơ đang chờ duyệt',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  approved
                      ? 'Bạn đã có quyền tác giả trong hệ thống.'
                      : rejected
                      ? (application.reviewNote.isEmpty
                            ? 'Vui lòng kiểm tra và gửi lại hồ sơ.'
                            : application.reviewNote)
                      : 'Admin đang thẩm định thông tin. Bạn sẽ nhận được kết quả sau khi duyệt.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 60),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('THỬ LẠI')),
        ],
      ),
    ),
  );
}
