// In: lib/gamification_data.dart
import 'package:flutter/material.dart';

// --- 1. BADGE MODEL ---
class BadgeData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredPoints; // Logic: Total Points needed
  final int requiredStreak; // Logic: Streak needed

  const BadgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.requiredPoints = 0,
    this.requiredStreak = 0,
  });
}

// --- 2. BADGE LIST ---
// Define all your badges here
final List<BadgeData> allBadges = [
  // --- Points Badges ---
  const BadgeData(
    id: 'points_100',
    name: 'Rising Star',
    description: 'Earn 100 total points.',
    icon: Icons.star,
    color: Color(0xFFFFCA28), // Gold
    requiredPoints: 100,
  ),
  const BadgeData(
    id: 'points_500',
    name: 'Master Mind',
    description: 'Earn 500 total points.',
    icon: Icons.psychology,
    color: Color(0xFF9C27B0), // Purple
    requiredPoints: 500,
  ),
  const BadgeData(
    id: 'points_1000',
    name: 'Guru',
    description: 'Earn 1000 total points.',
    icon: Icons.diamond,
    color: Color(0xFF00BCD4), // Cyan
    requiredPoints: 1000,
  ),
  const BadgeData( // NEW
    id: 'points_2500',
    name: 'Legend',
    description: 'Earn 2500 total points.',
    icon: Icons.workspace_premium,
    color: Color(0xFFFF5722), // Deep Orange
    requiredPoints: 2500,
  ),
  const BadgeData( // NEW
    id: 'points_5000',
    name: 'Mythic',
    description: 'Earn 5000 total points.',
    icon: Icons.auto_awesome,
    color: Color(0xFFE040FB), // Deep Purple Accent
    requiredPoints: 5000,
  ),

  // --- Streak Badges ---
  const BadgeData(
    id: 'streak_3',
    name: 'Committed',
    description: 'Achieve a 3-day streak.',
    icon: Icons.local_fire_department,
    color: Color(0xFFEF5350), // Red
    requiredStreak: 3,
  ),
  const BadgeData(
    id: 'streak_7',
    name: 'Unstoppable',
    description: 'Achieve a 7-day streak.',
    icon: Icons.bolt,
    color: Color(0xFF42A5F5), // Blue
    requiredStreak: 7,
  ),
  const BadgeData( // NEW
    id: 'streak_14',
    name: 'Resilient',
    description: 'Achieve a 14-day streak.',
    icon: Icons.shield,
    color: Color(0xFF66BB6A), // Green
    requiredStreak: 14,
  ),
  const BadgeData( // NEW
    id: 'streak_30',
    name: 'Iron Will',
    description: 'Achieve a 30-day streak.',
    icon: Icons.fitness_center,
    color: Color(0xFF78909C), // Blue Grey
    requiredStreak: 30,
  ),
];

// --- 3. AVATAR UNLOCK RULES ---
// Map of Avatar ID -> Points required to unlock
final Map<String, int> avatarUnlockThresholds = {
  'default': 0,
  'user (2)': 0,
  'man (13)': 0,
  'man': 0,
  'man (7)': 0,
  'woman (2)': 0,
  'woman': 0,
  'boy': 0,
  'rabbit': 0,
  // Tier 1 (300 Points)
  'profile': 300,
  'profile (2)': 300,
  'man (2)': 300,
  'man (12)': 300,
  'man (3)': 300,
  'man (5)': 300,
  'human': 300,
  'woman (4)': 300,
  'dog (1)': 300,
  'cat': 300,
  // Tier 2 (600 Points)
  'woman (1)': 600,
  'woman (3)': 600,
  'man (8)': 600,
  'man (9)': 600,
  'man (11)': 600,
  'dog': 600,
  'chicken': 600,
  'koala': 600,
  'lion': 600,
  // Tier 3 (1000 Points)
  'user (1)': 1000,
  'astronaut (2)': 1000,
  'man (4)': 1000,
  'woman (6)': 1000,
  'puffer-fish': 1000,
  'bear': 1000,
  'meerkat': 1000,
  'panda': 1000,
  'polar-bear': 1000,
  'sloth': 1000,
  // Tier 4 (2000 Points)
  'man (1)': 2000,
  'man (6)': 2000,
  'woman (5)': 2000,
  'dog (2)': 2000,
  'cat (2)': 2000,
  'eagle': 2000,
  'gorilla': 2000,
  'hen': 2000,
  'hippopotamus': 2000,
  // Tier 5 (5000 Points)
  'astronaut': 5000,
  'man (10)': 5000,
  'dragon': 5000,
  'gamer': 5000,
  'robot': 5000,
  'shark': 5000,
  'owl': 5000,
  'fox': 5000,
  'cow': 5000,
};

// --- 4. CENTRALIZED ASSET MAP ---
// Copied from your Dashboard so we can use it everywhere
final Map<String, String> masterAvatarAssets = {
  'default': 'assets/avatars/user.png',
  'astronaut (2)': 'assets/avatars/astronaut (2).png',
  'astronaut': 'assets/avatars/astronaut.png',
  'bear': 'assets/avatars/bear.png',
  'boy': 'assets/avatars/boy.png',
  'cat (2)': 'assets/avatars/cat (2).png',
  'cat': 'assets/avatars/cat.png',
  'chicken': 'assets/avatars/chicken.png',
  'cow': 'assets/avatars/cow.png',
  'dog (1)': 'assets/avatars/dog (1).png',
  'dog (2)': 'assets/avatars/dog (2).png',
  'dog': 'assets/avatars/dog.png',
  'dragon': 'assets/avatars/dragon.png',
  'eagle': 'assets/avatars/eagle.png',
  'fox': 'assets/avatars/fox.png',
  'gamer': 'assets/avatars/gamer.png',
  'gorilla': 'assets/avatars/gorilla.png',
  'hen': 'assets/avatars/hen.png',
  'hippopotamus': 'assets/avatars/hippopotamus.png',
  'human': 'assets/avatars/human.png',
  'koala': 'assets/avatars/koala.png',
  'lion': 'assets/avatars/lion.png',
  'man (1)': 'assets/avatars/man (1).png',
  'man (2)': 'assets/avatars/man (2).png',
  'man (3)': 'assets/avatars/man (3).png',
  'man (4)': 'assets/avatars/man (4).png',
  'man (5)': 'assets/avatars/man (5).png',
  'man (6)': 'assets/avatars/man (6).png',
  'man (7)': 'assets/avatars/man (7).png',
  'man (8)': 'assets/avatars/man (8).png',
  'man (9)': 'assets/avatars/man (9).png',
  'man (10)': 'assets/avatars/man (10).png',
  'man (11)': 'assets/avatars/man (11).png',
  'man (12)': 'assets/avatars/man (12).png',
  'man (13)': 'assets/avatars/man (13).png',
  'man': 'assets/avatars/man.png',
  'meerkat': 'assets/avatars/meerkat.png',
  'owl': 'assets/avatars/owl.png',
  'panda': 'assets/avatars/panda.png',
  'polar-bear': 'assets/avatars/polar-bear.png',
  'profile (2)': 'assets/avatars/profile (2).png',
  'profile': 'assets/avatars/profile.png',
  'puffer-fish': 'assets/avatars/puffer-fish.png',
  'rabbit': 'assets/avatars/rabbit.png',
  'robot': 'assets/avatars/robot.png',
  'shark': 'assets/avatars/shark.png',
  'sloth': 'assets/avatars/sloth.png',
  'user (1)': 'assets/avatars/user (1).png',
  'user (2)': 'assets/avatars/user (2).png',
  'woman (1)': 'assets/avatars/woman (1).png',
  'woman (2)': 'assets/avatars/woman (2).png',
  'woman (3)': 'assets/avatars/woman (3).png',
  'woman (4)': 'assets/avatars/woman (4).png',
  'woman (5)': 'assets/avatars/woman (5).png',
  'woman (6)': 'assets/avatars/woman (6).png',
  'woman': 'assets/avatars/woman.png',
};

class UserLevel {
  final int level;
  final String title;
  final int minPoints;
  final int maxPoints;

  const UserLevel({
    required this.level,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
  });
}

// Define the Levels
final List<UserLevel> gameLevels = [
  const UserLevel(level: 1, title: "Novice", minPoints: 0, maxPoints: 100),
  const UserLevel(level: 2, title: "Beginner", minPoints: 101, maxPoints: 300),
  const UserLevel(level: 3, title: "Seeker", minPoints: 301, maxPoints: 600),
  const UserLevel(level: 4, title: "Explorer", minPoints: 601, maxPoints: 1000),
  const UserLevel(level: 5, title: "Master", minPoints: 1001, maxPoints: 2000),
  const UserLevel(level: 6, title: "Grandmaster", minPoints: 2001, maxPoints: 5000),
  const UserLevel(level: 7, title: "Guru", minPoints: 5001, maxPoints: 100000), // Max level cap
];

// Helper to find current level based on points
UserLevel getUserLevel(int points) {
  return gameLevels.lastWhere(
    (lvl) => points >= lvl.minPoints,
    orElse: () => gameLevels[0],
  );
}