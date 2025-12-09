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
  // Tier 1 (50 Points)
  'profile': 50,
  'profile (2)': 50,
  'man (2)': 50,
  'man (12)': 50,
  'man (3)': 50,
  'man (5)': 50,
  'human': 50,
  'woman (4)': 50,
  'dog (1)': 50,
  'cat': 50,
  // Tier 2 (150 Points)
  'woman (1)': 150,
  'woman (3)': 150,
  'man (8)': 150,
  'man (9)': 150,
  'man (11)': 150,
  'dog': 150,
  'chicken': 150,
  'koala': 150,
  'lion': 150,
  // Tier 3 (300 Points)
  'user (1)': 300,
  'astronaut (2)': 300,
  'man (4)': 300,
  'woman (6)': 300,
  'puffer-fish': 300,
  'bear': 300,
  'meerkat': 300,
  'panda': 300,
  'polar-bear': 300,
  'sloth': 300,
  // Tier 4 (500 Points)
  'man (1)': 500,
  'man (6)': 500,
  'woman (5)': 500,
  'dog (2)': 500,
  'cat (2)': 500,
  'eagle': 500,
  'gorilla': 500,
  'hen': 500,
  'hippopotamus': 500,
  // Tier 5 (1000 Points)
  'astronaut': 1000,
  'man (10)': 1000,
  'dragon': 1000,
  'gamer': 1000,
  'robot': 1000,
  'shark': 1000,
  'owl': 1000,
  'fox': 1000,
  'cow': 1000,
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