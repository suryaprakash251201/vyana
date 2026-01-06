import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';
import 'package:vyana_flutter/features/auth/supabase_auth_service.dart';
import 'package:vyana_flutter/core/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(supabaseAuthServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
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
              if (_urlController.text.isEmpty) {
                _urlController.text = settings.backendUrl;
              }

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
                                 final res = await ref.read(apiClientProvider).get('/auth/start');
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
                    child: DropdownButtonFormField<String>(
                      value: (settings.geminiModel.contains('llama') || settings.geminiModel.contains('mixtral')) ? settings.geminiModel : 'llama-3.1-8b-instant',
                      items: const [
                        DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B (Groq)')),
                        DropdownMenuItem(value: 'llama-3.1-70b-versatile', child: Text('Llama 3.1 70B (Groq)')),
                        DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B (Groq)')),
                        DropdownMenuItem(value: 'mixtral-8x7b-32768', child: Text('Mixtral 8x7b (Groq)')),
                      ],
                      onChanged: (val) {
                        if (val != null) ref.read(settingsProvider.notifier).setModel(val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Model',
                        border: OutlineInputBorder(),
                      ),
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
                          controller: TextEditingController(text: settings.customInstructions),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "E.g., 'I'm a software developer. Keep responses concise and technical.'",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                // Need to get the text from the controller
                              },
                            ),
                          ),
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).setCustomInstructions(value);
                          },
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
}
