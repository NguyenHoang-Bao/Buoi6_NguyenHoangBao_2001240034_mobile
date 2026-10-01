import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SmsAnalyzerApp());
}

class SmsModel {
  final String id;
  final String address;
  final String body;
  final DateTime date;

  SmsModel({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
  });

  bool get isQC => body.trim().toUpperCase().startsWith('[QC]');

  bool get isOTP {
    if (!body.toUpperCase().contains('[OTP]')) return false;
    return extractOtpCode() != null;
  }

  String? extractOtpCode() {
    // Tìm chuỗi 6 ký số liên tiếp liên quan tới OTP
    final regex = RegExp(r'\b\d{6}\b');
    final match = regex.firstMatch(body);
    return match?.group(0);
  }
}

class SmsAnalyzerApp extends StatelessWidget {
  const SmsAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const SmsAnalyzerScreen(),
    );
  }
}

class SmsAnalyzerScreen extends StatefulWidget {
  const SmsAnalyzerScreen({super.key});

  @override
  State<SmsAnalyzerScreen> createState() => _SmsAnalyzerScreenState();
}

class _SmsAnalyzerScreenState extends State<SmsAnalyzerScreen> {
  final Telephony _telephony = Telephony.instance;
  List<SmsModel> _allMessages = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, qc, otp, other
  String _selectedSender = 'all';
  String _selectedMonth = 'all';

  @override
  void initState() {
    super.initState();
    _loadSampleMessages(); // Load rich sample data first
    _fetchRealSms(); // Then attempt to load real device SMS if available
  }

  void _loadSampleMessages() {
    final now = DateTime.now();
    final samples = [
      SmsModel(
        id: 's1',
        address: 'VIETTEL_QC',
        body: '[QC] Khuyen mai 50% goi cuoc DATA 4G toc do cao duy nhat hom nay. Soan KM50 gui 191.',
        date: now.subtract(const Duration(hours: 2)),
      ),
      SmsModel(
        id: 's2',
        address: 'TECHCOMBANK',
        body: '[OTP] Ma xac thuc giao dich chuyen tien la 839201. Ma co hieu luc trong 3 phut. Khong chia se cho bat ky ai.',
        date: now.subtract(const Duration(hours: 5)),
      ),
      SmsModel(
        id: 's3',
        address: '0987654321',
        body: 'Toi nay nho gui slide thuyet trinh Lap trinh di dong buoi 6 nha Bao!',
        date: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      SmsModel(
        id: 's4',
        address: 'SHOPEE_OFFICIAL',
        body: '[QC] Tang voucher giam 50.000d don tu 0d. Nhap ma SHOPEE06 ngay tai gio hang!',
        date: now.subtract(const Duration(days: 2)),
      ),
      SmsModel(
        id: 's5',
        address: 'MOMO',
        body: '[OTP] 491203 la ma xac nhan OTP dang nhap vi MoMo cua ban. Tuyet doi khong cung cap cho ai.',
        date: now.subtract(const Duration(days: 4)),
      ),
      SmsModel(
        id: 's6',
        address: '0912345678',
        body: 'Chieu mai 14h co tiet hoc tai phong Lab 04 nha mn.',
        date: now.subtract(const Duration(days: 10)),
      ),
      SmsModel(
        id: 's7',
        address: 'ZALO_AUTH',
        body: '[OTP] 105829 la ma OTP de thiet lap mat khau Zalo cua ban.',
        date: now.subtract(const Duration(days: 35)),
      ),
      SmsModel(
        id: 's8',
        address: 'VINAPHONE_KM',
        body: '[QC] Dang ky goi cuoc D50 chi 50k/thang co ngay 30GB data toc do cao.',
        date: now.subtract(const Duration(days: 40)),
      ),
    ];

    setState(() {
      _allMessages = samples;
    });
  }

  Future<void> _fetchRealSms() async {
    setState(() => _isLoading = true);
    try {
      final statuses = await [Permission.sms, Permission.phone].request();
      if (statuses[Permission.sms]?.isGranted ?? false) {
        final messages = await _telephony.getInboxSms(
          columns: [
            SmsColumn.ID,
            SmsColumn.ADDRESS,
            SmsColumn.BODY,
            SmsColumn.DATE,
          ],
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        );

        if (messages.isNotEmpty) {
          final realList = messages.map((m) {
            final dateMs = m.date ?? DateTime.now().millisecondsSinceEpoch;
            return SmsModel(
              id: m.id?.toString() ?? UniqueKey().toString(),
              address: m.address ?? 'Không rõ',
              body: m.body ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(dateMs),
            );
          }).toList();

          setState(() {
            _allMessages = realList;
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  // Lọc danh sách
  List<SmsModel> get _filteredMessages {
    return _allMessages.where((sms) {
      // Lọc theo nhóm
      if (_selectedFilter == 'qc' && !sms.isQC) return false;
      if (_selectedFilter == 'otp' && !sms.isOTP) return false;
      if (_selectedFilter == 'other' && (sms.isQC || sms.isOTP)) return false;

      // Lọc theo người gửi
      if (_selectedSender != 'all' && sms.address != _selectedSender) {
        return false;
      }

      // Lọc theo tháng
      if (_selectedMonth != 'all') {
        final mStr = DateFormat('MM/yyyy').format(sms.date);
        if (mStr != _selectedMonth) return false;
      }

      return true;
    }).toList();
  }

  // Danh sách người gửi duy nhất
  List<String> get _sendersList {
    final senders = _allMessages.map((e) => e.address).toSet().toList();
    senders.sort();
    return ['all', ...senders];
  }

  // Danh sách các tháng duy nhất
  List<String> get _monthsList {
    final months = _allMessages
        .map((e) => DateFormat('MM/yyyy').format(e.date))
        .toSet()
        .toList();
    months.sort((a, b) => b.compareTo(a));
    return ['all', ...months];
  }

  // Thống kê tin nhắn theo tháng
  Map<String, int> get _statsByMonth {
    final Map<String, int> stats = {};
    for (var m in _allMessages) {
      final key = DateFormat('MM/yyyy').format(m.date);
      stats[key] = (stats[key] ?? 0) + 1;
    }
    return stats;
  }

  // Thống kê tin nhắn theo ngày
  Map<String, int> get _statsByDate {
    final Map<String, int> stats = {};
    for (var m in _allMessages) {
      final key = DateFormat('dd/MM/yyyy').format(m.date);
      stats[key] = (stats[key] ?? 0) + 1;
    }
    return stats;
  }

  void _showOtpModal(SmsModel sms) {
    final otp = sms.extractOtpCode();
    if (otp == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'MÃ XÁC THỰC OTP PHÁT HIỆN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gửi từ: ${sms.address}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // 6 ô ký số OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: otp.split('').map((char) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 42,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.indigo.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        char,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sms.body,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text(
                    'Sao chép mã OTP (6 số)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: otp));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép mã OTP: $otp'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Thống kê theo ngày/tháng'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thống kê theo Tháng:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._statsByMonth.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tháng ${entry.key}:',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} tin nhắn',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Thống kê theo Ngày gần nhất:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._statsByDate.entries
                    .take(5)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${entry.value} tin nhắn',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _allMessages.length;
    final qcCount = _allMessages.where((m) => m.isQC).length;
    final otpCount = _allMessages.where((m) => m.isOTP).length;
    final otherCount = total - qcCount - otpCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SMS Analyzer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Xem thống kê ngày/tháng',
            onPressed: _showStatsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Đọc SMS từ thiết bị',
            onPressed: _fetchRealSms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Dashboard Cards
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            'Tổng tin nhắn',
                            total.toString(),
                            Icons.mark_email_read,
                            Colors.indigo,
                            () => setState(() => _selectedFilter = 'all'),
                            isSelected: _selectedFilter == 'all',
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Quảng cáo [QC]',
                            qcCount.toString(),
                            Icons.campaign,
                            Colors.orange,
                            () => setState(() => _selectedFilter = 'qc'),
                            isSelected: _selectedFilter == 'qc',
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Mã OTP [OTP]',
                            otpCount.toString(),
                            Icons.security,
                            Colors.green,
                            () => setState(() => _selectedFilter = 'otp'),
                            isSelected: _selectedFilter == 'otp',
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Khác',
                            otherCount.toString(),
                            Icons.message,
                            Colors.blueGrey,
                            () => setState(() => _selectedFilter = 'other'),
                            isSelected: _selectedFilter == 'other',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Dropdown filter by Sender & Month
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSender,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Lọc theo SĐT',
                                prefixIcon: const Icon(Icons.phone, size: 18),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _sendersList.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s == 'all' ? 'Tất cả người gửi' : s,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSender = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedMonth,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Lọc theo Tháng',
                                prefixIcon: const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _monthsList.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m == 'all' ? 'Tất cả tháng' : m,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMonth = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Filters and count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kết quả: ${_filteredMessages.length} tin nhắn',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedFilter != 'all' ||
                          _selectedSender != 'all' ||
                          _selectedMonth != 'all')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                              _selectedSender = 'all';
                              _selectedMonth = 'all';
                            });
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                ),

                // SMS List
                Expanded(
                  child: _filteredMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy tin nhắn phù hợp.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            final sms = _filteredMessages[index];
                            final isQC = sms.isQC;
                            final isOTP = sms.isOTP;
                            final otpCode = sms.extractOtpCode();

                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isOTP
                                      ? Colors.green.shade300
                                      : isQC
                                      ? Colors.orange.shade300
                                      : Colors.transparent,
                                  width: (isOTP || isQC) ? 1.5 : 0,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (isOTP) {
                                    _showOtpModal(sms);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: isOTP
                                                    ? Colors.green.shade100
                                                    : isQC
                                                    ? Colors.orange.shade100
                                                    : Colors.indigo.shade100,
                                                child: Icon(
                                                  isOTP
                                                      ? Icons.security
                                                      : isQC
                                                      ? Icons.campaign
                                                      : Icons.person,
                                                  size: 16,
                                                  color: isOTP
                                                      ? Colors.green.shade800
                                                      : isQC
                                                      ? Colors.orange.shade800
                                                      : Colors.indigo,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                sms.address,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              if (isQC)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '[QC]',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .orange
                                                          .shade900,
                                                    ),
                                                  ),
                                                ),
                                              if (isOTP)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '[OTP: $otpCode]',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.green.shade900,
                                                    ),
                                                  ),
                                                ),
                                              Text(
                                                DateFormat('dd/MM HH:mm')
                                                    .format(sms.date),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        sms.body,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.3,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (isOTP) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Nhấn để xem & trích xuất mã OTP 👉',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
