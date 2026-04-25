import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/announcement_model.dart';
import '../../data/announcement_service.dart';
import '../../../auth/data/token_storage.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  static const String routeName = '/announcements';

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _blue = Color(0xFF0B4D8B);

  final AnnouncementService _service = AnnouncementService();
  final TokenStorage _tokenStorage = SecureTokenStorage();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) throw Exception('No authentication token found.');

      final items = await _service.getAnnouncements(token);

      // Sort by latest first
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Mark latest as read by saving timestamp
      if (items.isNotEmpty) {
        final latestTime = items.first.createdAt.toIso8601String();
        await _storage.write(key: 'last_read_announcement_time', value: latestTime);
      }

      setState(() {
        _announcements = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(color: _blue, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _blue),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    if (_errorMessage != null && _announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load announcements',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1D4268)),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAnnouncements,
                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Color(0xFF98A2B3)),
                SizedBox(height: 16),
                Text(
                  'No announcements yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF344054)),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for updates.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final item = _announcements[index];
        return _buildAnnouncementCard(item);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final date = '${announcement.createdAt.day.toString().padLeft(2, '0')}/${announcement.createdAt.month.toString().padLeft(2, '0')}/${announcement.createdAt.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A2540),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_rounded, color: _blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4268),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}
