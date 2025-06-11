
// lib/models/role_model.dart
enum Role {
  federationAdmin, // Special role for 'idcloned'
  clanLeader,
  clanSubLeader,
  clanMember,
  guest // Default or unassigned
}

// Helper function to convert string from backend/DB to enum
Role roleFromString(String? roleString) {
  switch (roleString?.toLowerCase()) {
    case 'federationadmin':
    case 'federation_admin':
      return Role.federationAdmin;
    case 'clanleader':
    case 'clan_leader':
      return Role.clanLeader;
    case 'clansubleader':
    case 'clan_sub_leader':
      return Role.clanSubLeader;
    case 'clanmember':
    case 'clan_member':
      return Role.clanMember;
    default:
      return Role.guest;
  }
}

// Helper function to convert enum to string for backend/DB
String roleToString(Role role) {
  switch (role) {
    case Role.federationAdmin:
      return 'federation_admin';
    case Role.clanLeader:
      return 'clan_leader';
    case Role.clanSubLeader:
      return 'clan_sub_leader';
    case Role.clanMember:
      return 'clan_member';
    case Role.guest: return 'guest';
  }
}

