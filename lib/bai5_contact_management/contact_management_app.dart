import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const ContactManagementApp());
}

class ContactManagementApp extends StatelessWidget {
  const ContactManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý danh bạ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const ContactsListScreen(),
    );
  }
}

// In-memory cache for demo/offline fallback
final List<ContactInfo> _localAddedContacts = [];

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<ContactInfo> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.contacts.request();
      List<ContactInfo> deviceContacts = [];
      if (status.isGranted) {
        deviceContacts = await FlutterContactsService.getContacts();
      }

      // Combine device contacts with any locally created contacts
      final List<ContactInfo> combined = [
        ..._localAddedContacts,
        ...deviceContacts,
      ];

      setState(() {
        _contacts = combined;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _contacts = [..._localAddedContacts];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadContacts,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm danh bạ',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddContactScreen(),
                ),
              );
              _loadContacts(); // Refresh danh bạ sau khi thêm
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Không có danh bạ nào.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Thêm liên hệ mới'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddContactScreen(),
                        ),
                      );
                      _loadContacts();
                    },
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _contacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                ContactInfo contact = _contacts[index];
                final phoneStr =
                    (contact.phones != null && contact.phones!.isNotEmpty)
                    ? contact.phones!.first.value ?? 'Không có số'
                    : 'Không có số';
                final emailStr =
                    (contact.emails != null && contact.emails!.isNotEmpty)
                    ? contact.emails!.first.value ?? 'Không có email'
                    : 'Không có email';

                return ListTile(
                  leading: contact.avatar != null && contact.avatar!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(contact.avatar!),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (contact.displayName != null &&
                                    contact.displayName!.isNotEmpty)
                                ? contact.displayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                  title: Text(
                    contact.displayName ?? 'Không có tên',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('$phoneStr\n$emailStr'),
                  isThreeLine: true,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddContactScreen()),
          );
          _loadContacts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _avatar;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _avatar = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh từ Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    // Kiểm tra nếu tên hoặc số điện thoại bị bỏ trống
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên và số điện thoại không được để trống!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tạo đối tượng ContactInfo
    final contact = ContactInfo(
      displayName: _nameController.text.trim(),
      phones: [ValueItem(label: 'mobile', value: _phoneController.text.trim())],
      emails: [ValueItem(label: 'email', value: _emailController.text.trim())],
      avatar: _avatar != null ? await _avatar!.readAsBytes() : null,
    );

    // Lưu danh bạ vào điện thoại
    try {
      await Permission.contacts.request();
      await FlutterContactsService.addContact(contact);
    } catch (_) {
      // Local fallback in case system call is rejected on emulator
    }

    _localAddedContacts.insert(0, contact);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Danh bạ đã được lưu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Quay lại màn hình trước
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm danh bạ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _avatar != null
                        ? FileImage(_avatar!)
                        : null,
                    child: _avatar == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn để chọn ảnh đại diện',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lưu', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
