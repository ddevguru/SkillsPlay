class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final int xp;
  final String subscriptionStatus;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'USER',
    this.xp = 0,
    this.subscriptionStatus = 'FREE',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'USER',
        xp: json['xp'] as int? ?? 0,
        subscriptionStatus: json['subscriptionStatus'] as String? ?? 'FREE',
      );

  bool get hasSubscription => subscriptionStatus == 'BASIC' || subscriptionStatus == 'PRO';
}

class Track {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? icon;
  final bool isPremium;
  final int topicCount;

  Track({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.icon,
    this.isPremium = false,
    this.topicCount = 0,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String?,
        isPremium: json['isPremium'] as bool? ?? false,
        topicCount: json['_count']?['topics'] as int? ?? 0,
      );
}

class Topic {
  final String id;
  final String title;
  final String slug;
  final String difficulty;
  final int lessonCount;

  Topic({
    required this.id,
    required this.title,
    required this.slug,
    required this.difficulty,
    this.lessonCount = 0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        difficulty: json['difficulty'] as String,
        lessonCount: json['_count']?['lessons'] as int? ?? 0,
      );
}

class Lesson {
  final String id;
  final String title;
  final String gameType;
  final String difficulty;
  final Map<String, dynamic> configJson;
  final String content;
  final int points;

  Lesson({
    required this.id,
    required this.title,
    required this.gameType,
    required this.difficulty,
    required this.configJson,
    required this.content,
    required this.points,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        gameType: json['gameType'] as String,
        difficulty: json['difficulty'] as String,
        configJson: Map<String, dynamic>.from(json['configJson'] as Map),
        content: json['content'] as String,
        points: json['points'] as int,
      );
}

class PlayResult {
  final bool passed;
  final int score;
  final int xpEarned;
  final String status;

  PlayResult({
    required this.passed,
    required this.score,
    required this.xpEarned,
    required this.status,
  });

  factory PlayResult.fromJson(Map<String, dynamic> json) => PlayResult(
        passed: json['passed'] as bool,
        score: json['score'] as int,
        xpEarned: json['xpEarned'] as int,
        status: json['status'] as String,
      );
}

class LeaderboardEntry {
  final int rank;
  final int score;
  final String userId;
  final String name;
  final int xp;

  LeaderboardEntry({
    required this.rank,
    required this.score,
    required this.userId,
    required this.name,
    required this.xp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) => LeaderboardEntry(
        rank: json['rank'] as int? ?? rank,
        score: json['score'] as int,
        userId: json['user']?['id'] as String? ?? json['userId'] as String,
        name: json['user']?['name'] as String? ?? 'Player',
        xp: json['user']?['xp'] as int? ?? 0,
      );
}

class SubscriptionPlan {
  final String id;
  final String name;
  final int amount;
  final String priceDisplay;
  final String interval;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.amount,
    required this.priceDisplay,
    required this.interval,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: json['amount'] as int,
        priceDisplay: json['priceDisplay'] as String,
        interval: json['interval'] as String,
      );
}
