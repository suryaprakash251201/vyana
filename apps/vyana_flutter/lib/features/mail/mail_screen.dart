import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:flutter_html/flutter_html.dart';

final unreadProvider = FutureProvider<int>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final unread = await apiClient.get('/gmail/unread');
    return unread['count'] is int ? unread['count'] : 0;
  } catch (e) {
    return 0;
  }
});

final mailFamilyProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, category) async {
  final apiClient = ref.watch(apiClientProvider);
  
  // Check connection via unread endpoint for now (heuristic)
  bool isConnected = false;
  try {
    final unread = await apiClient.get('/gmail/unread');
    isConnected = unread['count'] is int;
  } catch (e) {
    isConnected = false;
  }

  List<dynamic> messages = [];
  if (isConnected) {
      try {
        final url = category != null ? '/gmail/list?limit=20&category=$category' : '/gmail/list?limit=20';
        final listRes = await apiClient.get(url);
        if (listRes['messages'] != null) {
          messages = listRes['messages'];
        }
      } catch (e) {
        // Handle error
      }
  }
  return {'messages': messages, 'connected': isConnected};
});

class MailScreen extends ConsumerWidget {
  const MailScreen({super.key});

  Future<void> _connectGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/google/start');
      final authUrl = response['auth_url'];
      if (authUrl != null && await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
        // Show instruction to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Complete login in browser, then refresh this page.")),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open auth URL: $authUrl")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error connecting: $e")),
        );
      }
    }
  }

  void _showEmailDetails(BuildContext context, WidgetRef ref, String id, String subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => _EmailDetailSheet(id: id, subject: subject),
    );
  }

  void _showComposeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ComposeEmailSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unreadAsync = ref.watch(unreadProvider);

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.errorRed.withOpacity(0.03),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.errorRed, AppColors.warmOrange],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.errorRed.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mail_rounded, color: Colors.white, size: 24),
                          ),
                          const Gap(16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gmail',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              unreadAsync.when(
                                data: (count) => Text(
                                  '$count Unread',
                                  style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                                ),
                                loading: () => const Text("Checking...", style: TextStyle(fontSize: 12)),
                                error: (_, __) => const SizedBox(),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              ref.refresh(unreadProvider);
                              ref.refresh(mailFamilyProvider(null)); // primary
                              ref.refresh(mailFamilyProvider('social'));
                              ref.refresh(mailFamilyProvider('updates'));
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const Gap(16),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                          ),
                          labelColor: AppColors.errorRed,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: "Primary"),
                            Tab(text: "Social"),
                            Tab(text: "Updates"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTabContent(context, ref, null, theme),
                      _buildTabContent(context, ref, 'social', theme),
                      _buildTabContent(context, ref, 'updates', theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComposeDialog(context),
        backgroundColor: AppColors.errorRed,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, String? category, ThemeData theme) {
    final mailAsync = ref.watch(mailFamilyProvider(category));
    
    return mailAsync.when(
      data: (data) {
        final bool isConnected = data['connected'] ?? false;
        if (!isConnected) {
          return _buildNotConnectedView(context, ref, theme);
        }
        final messages = data['messages'] as List<dynamic>? ?? [];
        if (messages.isEmpty) {
           return const Center(child: Text("No emails found"));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length + 1, // Space at bottom
          itemBuilder: (context, index) {
            if (index == messages.length) return const Gap(80);
            return _buildEmailTile(context, ref, messages[index], theme);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmailTile(BuildContext context, WidgetRef ref, dynamic email, ThemeData theme) {
     return Container(
       margin: const EdgeInsets.only(bottom: 8),
       decoration: BoxDecoration(
         color: theme.colorScheme.surface,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey.withOpacity(0.05)),
       ),
       child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryPurple.withOpacity(0.05),
          radius: 20,
          child: Text(
            (email['sender'] as String).substring(0, 1).toUpperCase(),
            style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          email['sender'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email['subject'] ?? '(No Subject)',
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            if (email['snippet'] != null)
              Text(
                email['snippet'],
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Timestamp could go here if available
             Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
          ],
        ),
        onTap: () => _showEmailDetails(context, ref, email['id'], email['subject'] ?? 'Email'),
      ),
    );
  }

  Widget _buildNotConnectedView(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mail_lock_outlined, size: 64, color: AppColors.errorRed),
            ),
            const Gap(24),
            Text(
              'Sign in to Gmail',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              'Connect your account to view and send emails',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () => _connectGoogle(context, ref),
              icon: const Icon(Icons.login),
              label: const Text('Connect Google Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailDetailSheet extends ConsumerStatefulWidget {
  final String id;
  final String subject;
  const _EmailDetailSheet({required this.id, required this.subject});

  @override
  ConsumerState<_EmailDetailSheet> createState() => _EmailDetailSheetState();
}

class _EmailDetailSheetState extends ConsumerState<_EmailDetailSheet> {
  late Future<Map<String, dynamic>> _detailsFuture;
  bool _showHtml = true;

  @override
  void initState() {
    super.initState();
    _detailsFuture = ref.read(apiClientProvider).get('/gmail/message/${widget.id}')
        .then((data) => Map<String, dynamic>.from(data as Map));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              AppBar(
                title: Text(widget.subject, style: const TextStyle(fontSize: 16)),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _detailsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    final data = snapshot.data!;
                    if (data.containsKey('error')) {
                       return Center(child: Text("Error: ${data['error']}"));
                    }
                    
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person)),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['sender'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(data['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(20),
                          const Divider(),
                          const Gap(20),
                          Row(
                            children: [
                              Text('View', style: Theme.of(context).textTheme.labelMedium),
                              const Gap(8),
                              ChoiceChip(
                                label: const Text('HTML'),
                                selected: _showHtml,
                                onSelected: (_) => setState(() => _showHtml = true),
                              ),
                              const Gap(6),
                              ChoiceChip(
                                label: const Text('Plain'),
                                selected: !_showHtml,
                                onSelected: (_) => setState(() => _showHtml = false),
                              ),
                            ],
                          ),
                          const Gap(12),
                          if (_showHtml && (data['html_body'] ?? '').toString().isNotEmpty)
                            Html(
                              data: data['html_body'] ?? '',
                            )
                          else
                            SelectableText(
                              data['body'] ?? 'No Content',
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposeEmailSheet extends ConsumerStatefulWidget {
  const _ComposeEmailSheet();

  @override
  ConsumerState<_ComposeEmailSheet> createState() => _ComposeEmailSheetState();
}

class _ComposeEmailSheetState extends ConsumerState<_ComposeEmailSheet> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_toController.text.isEmpty || _bodyController.text.isEmpty) return;
    
    setState(() => _sending = true);
    try {
      final res = await ref.read(apiClientProvider).post('/gmail/send', body: {
        'to_email': _toController.text,
        'subject': _subjectController.text,
        'body': _bodyController.text,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sent: ${res['result']}")));
        ref.invalidate(unreadProvider);
        ref.invalidate(mailFamilyProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Compose Email", style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            TextField(
              controller: _toController,
              decoration: const InputDecoration(labelText: "To", border: OutlineInputBorder()),
            ),
            const Gap(12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder()),
            ),
            const Gap(12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: "Message", border: OutlineInputBorder()),
              maxLines: 5,
            ),
            const Gap(20),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
              label: const Text("Send"),
            ),
            const Gap(10),
          ],
        ),
      );
  }
}
