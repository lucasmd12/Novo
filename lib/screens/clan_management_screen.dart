// lib/screens/clan_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clan_model.dart';
import '../services/clan_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';


class ClanManagementScreen extends StatefulWidget {
  final String clanId;

  const ClanManagementScreen({super.key, required this.clanId});

  @override
  State<ClanManagementScreen> createState() => _ClanManagementScreenState();
}

class _ClanManagementScreenState extends State<ClanManagementScreen> {
  Clan? _clan;
  bool _isLoading = true;
  bool _canManage = false; // Flag to check if user is leader or sub-leader

  @override
  void initState() {
    super.initState();
    _fetchClanDetails();
  }

  Future<void> _fetchClanDetails() async {
    setState(() {
      _isLoading = true;
      _canManage = false;
    });
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final clanDetails = await clanService.getClanDetails(widget.clanId);
      final currentUser = authService.currentUser;

      if (clanDetails != null && currentUser != null) {
        // Check permissions: Leader or SubLeader of this clan
        bool isLeader = currentUser.id == clanDetails.leaderId;
        bool isSubLeader = clanDetails.subLeaderIds.contains(currentUser.id);
        _canManage = isLeader || isSubLeader;

        setState(() {
          _clan = clanDetails;
        });
      } else {
        Logger.warning("Could not fetch clan details or user info for management screen.");
        // Handle error display if needed
      }
    } catch (e) {
      Logger.error("Error fetching clan details for management: $e");
      // Handle error display
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_clan?.name ?? 'Clan Management'),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editClanDetails, // TODO: Implement edit functionality
              tooltip: 'Edit Clan Details',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clan == null
              ? const Center(child: Text('Could not load clan details.'))
              : RefreshIndicator(
                  onRefresh: _fetchClanDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildClanHeader(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Text Channels'),
                      _buildChannelList(_clan!.textChannels),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Voice Channels'),
                      _buildChannelList(_clan!.voiceChannels),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Members'),
                      // TODO: Implement Members Panel/List view here
                      // Consider navigating to a separate members screen
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: Text('View Members (${_clan!.members.length})'),
                        onTap: _navigateToMembersScreen, // TODO: Implement navigation
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildClanHeader() {
    // TODO: Use actual banner image (PNG) when available and configured
    // final bannerUrl = _clan!.bannerImageUrl;
    // bool hasBanner = bannerUrl.isNotEmpty && Uri.tryParse(bannerUrl)?.hasAbsolutePath == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder for Banner Image
        Container(
          height: 150,
          color: Colors.grey[300],
          child: Center(
            child: Icon(Icons.shield, size: 50, color: Colors.grey[600]),
            // child: hasBanner
            //     ? Image.network(bannerUrl, fit: BoxFit.cover, width: double.infinity)
            //     : Icon(Icons.shield, size: 50, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _clan!.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_clan!.tag.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _clan!.tag,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_canManage)
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
            onPressed: () { /* TODO: Implement add channel functionality */ },
            tooltip: 'Add New Channel',
          ),
      ],
    );
  }

  Widget _buildChannelList(List<dynamic> channels) { // Use dynamic for base Channel type
    if (channels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No channels available.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the list
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        // Determine icon based on type (assuming type property exists or check runtimeType)
        IconData iconData = channel.type == 'text' ? Icons.chat_bubble_outline : Icons.volume_up_outlined;

        return ListTile(
          leading: Icon(iconData),
          title: Text(channel.name),
          // TODO: Add onTap to navigate to the channel
          onTap: () { /* Navigate to channel */ },
          trailing: _canManage
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () { /* TODO: Implement delete channel */ },
                  tooltip: 'Delete Channel',
                )
              : null,
        );
      },
    );
  }

  void _editClanDetails() {
    // TODO: Navigate to an edit screen or show a dialog
    Logger.info("Edit clan details action triggered (Not Implemented)");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality not yet implemented.')),
    );
  }

   void _navigateToMembersScreen() {
    // TODO: Implement navigation to a dedicated members screen/panel
    Logger.info("Navigate to members screen action triggered (Not Implemented)");
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Members screen navigation not yet implemented.')),
    );
  }
}
