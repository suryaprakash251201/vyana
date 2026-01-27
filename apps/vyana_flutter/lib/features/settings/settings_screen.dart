import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';
import 'package:vyana_flutter/features/settings/low_cost_provider.dart';
import 'package:vyana_flutter/features/auth/supabase_auth_service.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/mcp/mcp_screen.dart';

class _ModelOption {
  final String id;
  final String name;
  final String description;
  final String badge;

  const _ModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.badge,
  });
}

const List<_ModelOption> _groqModels = [
  // DeepSeek Models (via OpenRouter) - Best for reasoning and coding
  _ModelOption(
    id: 'openrouter/deepseek/deepseek-chat',
    name: 'DeepSeek Chat',
    description: 'Excellent reasoning, coding & tool calling. Very cost effective.',
    badge: 'Recommended',
  ),
  _ModelOption(
    id: 'openrouter/deepseek/deepseek-r1',
    name: 'DeepSeek R1',
    description: 'State-of-the-art reasoning model with chain-of-thought.',
    badge: 'Reasoning',
  ),
  _ModelOption(
    id: 'openrouter/deepseek/deepseek-r1-0528',
    name: 'DeepSeek R1 (Latest)',
    description: 'Latest R1 with improved reasoning capabilities.',
    badge: 'New',
  ),
  // Groq Models - Fast inference
  _ModelOption(
    id: 'llama-3.1-70b-versatile',
    name: 'Llama 3.1 70B',
    description: 'Versatile model with good tool calling. Fast on Groq.',
    badge: 'Fast',
  ),
  _ModelOption(
    id: 'meta-llama/llama-4-scout-17b-16e-instruct',
    name: 'Llama 4 Scout',
    description: 'Latest Llama model with strong tool calling.',
    badge: 'New',
  ),
  _ModelOption(
    id: 'qwen/qwen3-32b',
    name: 'Qwen 3 32B',
    description: 'Strong reasoning and tool calling capabilities.',
    badge: 'Balanced',
  ),
  _ModelOption(
    id: 'moonshotai/kimi-k2-instruct',
    name: 'Kimi K2',
    description: 'Advanced model with excellent tool use.',
    badge: 'Quality',
  ),
  // Legacy Models
  _ModelOption(
    id: 'llama-3.1-8b-instant',
    name: 'Llama 3.1 8B',
    description: 'Fast, low cost, great for quick tasks and chat.',
    badge: 'Fast',
  ),
  _ModelOption(
    id: 'llama-3.3-70b-versatile',
    name: 'Llama 3.3 70B',
    description: 'Latest 70B variant with improved instruction following.',
    badge: 'Quality',
  ),
  _ModelOption(
    id: 'mixtral-8x7b-32768',
    name: 'Mixtral 8x7B',
    description: 'Strong for multi-step tasks with wide context.',
    badge: 'Long context',
  ),
  _ModelOption(
    id: 'gemma2-9b-it',
    name: 'Gemma 2 9B',
    description: 'Compact and efficient for daily assistant tasks.',
    badge: 'Compact',
  ),
];

final gmailStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/google/status');
    return response['authenticated'] == true;
  } catch (_) {
    return false;
  }
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _customInstructionsController;
  late TextEditingController _customModelController;
  late TextEditingController _calendarIdController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _customInstructionsController = TextEditingController();
    _customModelController = TextEditingController();
    _calendarIdController = TextEditingController();
    _loadCalendarId();
  }

  Future<void> _loadCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('calendarId') ?? '';
    if (mounted) {
      _calendarIdController.text = stored;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _customInstructionsController.dispose();
    _customModelController.dispose();
    _calendarIdController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(supabaseAuthServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final gmailStatusAsync = ref.watch(gmailStatusProvider);
    final lowCostAsync = ref.watch(lowCostSettingsProvider);
    final theme = Theme.of(context);


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.warmOrange.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (settings) {
              _syncController(_urlController, settings.backendUrl);
              _syncController(_customInstructionsController, settings.customInstructions);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.warmOrange, AppColors.accentPink],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmOrange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                      ),
                      const Gap(16),
                      Text(
                        'Settings',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(28),
                  
                  // Account Section
                  _buildSectionHeader('Account', Icons.account_circle_outlined),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                             final userAsync = ref.watch(supabaseUserProvider);
                             return userAsync.when(
                               data: (user) => Column(
                                 children: [
                                   CircleAvatar(
                                     radius: 30,
                                     backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                                     child: Text(
                                       user?.email?.substring(0, 1).toUpperCase() ?? "U",
                                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                                     ),
                                   ),
                                   const Gap(12),
                                   Text(
                                     user?.email ?? "User",
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                   ),
                                   const Gap(4),
                                   Text("Logged in via Supabase", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                 ],
                               ),
                               loading: () => const CircularProgressIndicator(),
                               error: (_,__) => const Text("Error loading profile"),
                             );
                          },
                        ),
                        const Gap(24),
                        Row(
                          children: [
                            Text('Gmail Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            gmailStatusAsync.when(
                              data: (connected) => _statusChip(connected ? 'Connected' : 'Not connected', connected),
                              loading: () => _statusChip('Checking', false),
                              error: (_, __) => _statusChip('Unknown', false),
                            )
                          ],
                        ),
                        const Gap(12),
                        // Gmail Connect
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                               try {
                                 final apiClient = ref.read(apiClientProvider); // Ensure you have this provider accessible or import it
                                 // We need to import apiClientProvider if not already available in scope or use ref.read
                                 // Assuming apiClientProvider is available from settings_screen imports (it is usually in api_client.dart)
                                 // Wait, I need to check imports.
                                 final res = await apiClient.get('/google/start');
                                 if (res['auth_url'] != null) {
                                   final uri = Uri.parse(res['auth_url']);
                                   if (await canLaunchUrl(uri)) {
                                     await launchUrl(uri, mode: LaunchMode.externalApplication);
                                   }
                                 }
                               } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error connecting Gmail: $e")));
                               }
                            },
                            icon: const Icon(Icons.mail),
                            label: const Text('Connect Gmail'),
                          ),
                        ),
                        const Gap(10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await ref.read(apiClientProvider).post('/google/logout');
                                ref.invalidate(gmailStatusProvider);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error disconnecting Gmail: $e")));
                              }
                            },
                            icon: const Icon(Icons.link_off, color: Colors.grey),
                            label: const Text('Disconnect Gmail', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const Gap(12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: AppColors.errorRed),
                            label: const Text('Logout', style: TextStyle(color: AppColors.errorRed)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.errorRed.withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Model Selection
                  _buildSectionHeader('AI Model', Icons.auto_awesome),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: settings.geminiModel,
                          items: [
                            ..._groqModels.map((model) => DropdownMenuItem(
                                  value: model.id,
                                  child: Text('${model.name} (Groq)'),
                                )),
                            if (!_groqModels.any((model) => model.id == settings.geminiModel))
                              DropdownMenuItem(
                                value: settings.geminiModel,
                                child: Text('${settings.geminiModel} (Custom)'),
                              ),
                          ],
                          onChanged: (val) {
                            if (val != null) ref.read(settingsProvider.notifier).setModel(val);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select Model',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const Gap(12),
                        _modelInfoCard(settings.geminiModel),
                        const Gap(12),
                        TextField(
                          controller: _customModelController,
                          decoration: InputDecoration(
                            labelText: 'Custom model ID',
                            helperText: 'Paste any Groq model ID supported by your account',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () {
                                final value = _customModelController.text.trim();
                                if (value.isNotEmpty) {
                                  ref.read(settingsProvider.notifier).setModel(value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Custom model applied')),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Personal AI Instructions
                  _buildSectionHeader('Personal AI', Icons.smart_toy),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Custom Instructions",
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Text(
                          "Tell Vyana about yourself, your preferences, or how you'd like responses.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const Gap(16),
                        TextField(
                          controller: _customInstructionsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "E.g., 'I'm a software developer. Keep responses concise and technical.'",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                ref.read(settingsProvider.notifier).setCustomInstructions(
                                  _customInstructionsController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Instructions saved')),
                                );
                              },
                            ),
                          ),
                          onChanged: (_) {},
                        ),
                        const Gap(16),
                        Text('Response Style', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChoiceChip(
                              label: 'Concise',
                              selected: settings.responseStyle == 'Concise',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseStyle('Concise'),
                            ),
                            _buildChoiceChip(
                              label: 'Balanced',
                              selected: settings.responseStyle == 'Balanced',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseStyle('Balanced'),
                            ),
                            _buildChoiceChip(
                              label: 'Detailed',
                              selected: settings.responseStyle == 'Detailed',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseStyle('Detailed'),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Text('Response Tone', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChoiceChip(
                              label: 'Friendly',
                              selected: settings.responseTone == 'Friendly',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseTone('Friendly'),
                            ),
                            _buildChoiceChip(
                              label: 'Professional',
                              selected: settings.responseTone == 'Professional',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseTone('Professional'),
                            ),
                            _buildChoiceChip(
                              label: 'Direct',
                              selected: settings.responseTone == 'Direct',
                              onSelected: () => ref.read(settingsProvider.notifier).setResponseTone('Direct'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  
                  // Assistant Config
                  _buildSectionHeader('Assistant', Icons.psychology),
                  const Gap(12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Enable Tools"),
                          subtitle: const Text("Allow access to Calendar, Mail, Tasks"),
                          value: settings.toolsEnabled,
                          onChanged: (val) => ref.read(settingsProvider.notifier).toggleTools(val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text("Enable MCP Tools"),
                          subtitle: const Text("Allow access to external MCP tools"),
                          value: settings.mcpEnabled,
                          onChanged: (val) => ref.read(settingsProvider.notifier).toggleMcp(val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text("Enable Memory"),
                          subtitle: const Text("Remember context across sessions"),
                          value: settings.memoryEnabled,
                          onChanged: (val) => ref.read(settingsProvider.notifier).toggleMemory(val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text("Tamil Mode"),
                          subtitle: const Text("Responses in Tanglish"),
                          value: settings.tamilMode,
                          onChanged: (val) => ref.read(settingsProvider.notifier).toggleTamilMode(val),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Cost Control
                  _buildSectionHeader('Cost Control', Icons.savings_outlined),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: lowCostAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                      data: (lowCost) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Low-cost mode'),
                              subtitle: const Text('Limit input size and auto-fallback to a lighter model'),
                              value: lowCost.enabled,
                              onChanged: (val) => ref.read(lowCostSettingsProvider.notifier).setEnabled(val),
                            ),
                            const Gap(12),
                            Text('Max input length', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Slider(
                              value: lowCost.maxInputChars.toDouble(),
                              min: 200,
                              max: 4000,
                              divisions: 19,
                              label: '${lowCost.maxInputChars} chars',
                              onChanged: lowCost.enabled
                                  ? (val) => ref.read(lowCostSettingsProvider.notifier).setMaxInputChars(val.round())
                                  : null,
                            ),
                            const Gap(12),
                            Text('Max output tokens', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Slider(
                              value: settings.maxOutputTokens.toDouble(),
                              min: 64,
                              max: 2000,
                              divisions: 97,
                              label: '${settings.maxOutputTokens} tokens',
                              onChanged: (val) => ref.read(settingsProvider.notifier).setMaxOutputTokens(val.round()),
                            ),
                            const Gap(12),
                            Text('Fallback model', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const Gap(8),
                            DropdownButtonFormField<String>(
                              value: lowCost.fallbackModel,
                              items: _groqModels
                                  .map((model) => DropdownMenuItem(
                                        value: model.id,
                                        child: Text('${model.name} (Groq)'),
                                      ))
                                  .toList(),
                              onChanged: lowCost.enabled
                                  ? (val) {
                                      if (val != null) {
                                        ref.read(lowCostSettingsProvider.notifier).setFallbackModel(val);
                                      }
                                    }
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Fallback model',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Gap(24),

                  // MCP Connections
                  _buildSectionHeader('MCP Connections', Icons.extension),
                  const Gap(12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: AppColors.primaryPurple),
                      ),
                      title: const Text('Manage MCP Services'),
                      subtitle: const Text('Connect Zerodha, and more'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _MCPScreenWrapper(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(24),
                  
                  // Appearance
                  _buildSectionHeader('Appearance', Icons.palette),
                  const Gap(12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      title: const Text("Dark Theme"),
                      secondary: Icon(settings.isDarkTheme ? Icons.dark_mode : Icons.light_mode),
                      value: settings.isDarkTheme,
                      onChanged: (val) => ref.read(settingsProvider.notifier).toggleTheme(val),
                    ),
                  ),
                  const Gap(24),
                  
                  // Backend URL
                  _buildSectionHeader('Backend', Icons.dns),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: "Backend URL",
                        helperText: "e.g., http://localhost:8000",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () {
                            ref.read(settingsProvider.notifier).setBackendUrl(_urlController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Backend URL saved")),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _calendarIdController,
                      decoration: InputDecoration(
                        labelText: "Google Calendar ID",
                        helperText: "e.g., 1b7...@group.calendar.google.com",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('calendarId', _calendarIdController.text.trim());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Calendar ID saved")),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const Gap(32),

                  // App Info
                  _buildSectionHeader('About', Icons.info_outline),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text("Vyana", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Gap(4),
                        const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
                        const Gap(16),
                        const Divider(),
                        const Gap(16),
                        const Text("Backend Technology", style: TextStyle(fontWeight: FontWeight.w600)),
                        const Text("FastAPI + Groq (Llama 3)", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Gap(32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const Gap(8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryPurple.withOpacity(0.18),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryPurple : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
    );
  }

  Widget _statusChip(String text, bool active) {
    final color = active ? AppColors.successGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _modelInfoCard(String modelId) {
    final theme = Theme.of(context);
    final match = _groqModels.where((model) => model.id == modelId).toList();
    final model = match.isNotEmpty ? match.first : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model?.name ?? modelId,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Text(
                  model?.description ?? 'Custom model ID selected.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (model != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                model.badge,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wrapper to provide ProviderScope for MCPScreen when navigating from settings
class _MCPScreenWrapper extends StatelessWidget {
  const _MCPScreenWrapper();

  @override
  Widget build(BuildContext context) {
    return const MCPScreen();
  }
}
