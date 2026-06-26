import { PrismaClient, UserRole, Difficulty } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { buildLesson } from './lesson-content';

const prisma = new PrismaClient();

const TRACKS = [
  { slug: 'dsa', title: 'Data Structures & Algorithms', description: 'Master DSA from arrays to graphs', icon: '🧩' },
  { slug: 'python', title: 'Python', description: 'Learn Python from basics to advanced', icon: '🐍' },
  { slug: 'javascript', title: 'JavaScript', description: 'Modern JS for web development', icon: '⚡' },
  { slug: 'mern', title: 'MERN Stack', description: 'MongoDB, Express, React, Node.js', icon: '🌐' },
  { slug: 'java', title: 'Java', description: 'Object-oriented programming with Java', icon: '☕' },
  { slug: 'cpp', title: 'C/C++', description: 'Systems programming fundamentals', icon: '⚙️' },
  { slug: 'html-css', title: 'HTML/CSS', description: 'Web markup and styling', icon: '🎨' },
  { slug: 'php', title: 'PHP', description: 'Server-side web development', icon: '🐘' },
  { slug: 'aws', title: 'AWS Cloud', description: 'Cloud architecture and services', icon: '☁️' },
];

const TOPICS_BY_TRACK: Record<string, string[]> = {
  dsa: ['Arrays', 'Linked Lists', 'Stacks & Queues', 'Trees', 'Graphs', 'Sorting', 'Searching', 'Dynamic Programming', 'Greedy', 'Backtracking'],
  python: ['Variables & Types', 'Control Flow', 'Functions', 'Lists & Dicts', 'OOP', 'File I/O', 'Decorators', 'Async', 'Testing', 'Packages'],
  javascript: ['Variables', 'Functions', 'Arrays', 'Objects', 'DOM', 'Promises', 'Async/Await', 'Modules', 'ES6+', 'Node Basics'],
};

async function main() {
  console.log('Seeding SkillPlay database...');

  const adminHash = await bcrypt.hash('Admin123!', 12);
  const demoHash = await bcrypt.hash('Demo1234!', 12);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@skillplay.dev' },
    update: {},
    create: {
      name: 'Admin',
      email: 'admin@skillplay.dev',
      hashedPassword: adminHash,
      role: UserRole.ADMIN,
      subscriptionStatus: 'PRO',
    },
  });

  const demo = await prisma.user.upsert({
    where: { email: 'demo@skillplay.dev' },
    update: { subscriptionStatus: 'BASIC' },
    create: {
      name: 'Demo Player',
      email: 'demo@skillplay.dev',
      hashedPassword: demoHash,
      xp: 150,
      subscriptionStatus: 'BASIC',
    },
  });

  for (let i = 0; i < TRACKS.length; i++) {
    const t = TRACKS[i];
    const track = await prisma.track.upsert({
      where: { slug: t.slug },
      update: {},
      create: { ...t, order: i, isPremium: ['aws', 'mern'].includes(t.slug) },
    });

    const topicNames = TOPICS_BY_TRACK[t.slug] || ['Basics', 'Intermediate', 'Advanced'];
    for (let j = 0; j < topicNames.length; j++) {
      const difficulty = j < 3 ? Difficulty.BASICS : j < 7 ? Difficulty.INTERMEDIATE : Difficulty.ADVANCED;
      const topic = await prisma.topic.upsert({
        where: { trackId_slug: { trackId: track.id, slug: topicNames[j].toLowerCase().replace(/\s+/g, '-') } },
        update: {
          description: `🎮 ${topicNames[j]} — 6 fun games: quizzes, puzzles, scenarios & code challenges!`,
        },
        create: {
          trackId: track.id,
          title: topicNames[j],
          slug: topicNames[j].toLowerCase().replace(/\s+/g, '-'),
          description: `🎮 ${topicNames[j]} — 6 fun games: quizzes, puzzles, scenarios & code challenges!`,
          difficulty,
          order: j,
        },
      });

      for (let k = 0; k < 6; k++) {
        const lc = buildLesson(t.slug, topicNames[j], k, difficulty);
        const existing = await prisma.lesson.findFirst({
          where: { topicId: topic.id, order: k },
        });

        const lessonData = {
          title: lc.title,
          gameType: lc.gameType,
          difficulty,
          configJson: lc.configJson,
          content: lc.content,
          points: 15 + k * 10,
        };

        let lessonId: string;
        if (existing) {
          const updated = await prisma.lesson.update({
            where: { id: existing.id },
            data: lessonData,
          });
          lessonId = updated.id;
          await prisma.testcase.deleteMany({ where: { lessonId } });
        } else {
          const created = await prisma.lesson.create({
            data: { ...lessonData, topicId: topic.id, order: k },
          });
          lessonId = created.id;
        }

        for (let tc = 0; tc < lc.testcases.length; tc++) {
          await prisma.testcase.create({
            data: {
              lessonId,
              input: lc.testcases[tc].input,
              expectedOutput: lc.testcases[tc].expectedOutput,
              order: tc,
            },
          });
        }
      }
    }
  }

  const pythonTrack = await prisma.track.findUnique({ where: { slug: 'python' } });
  if (pythonTrack) {
    await prisma.userTrack.upsert({
      where: { userId_trackId: { userId: demo.id, trackId: pythonTrack.id } },
      update: {},
      create: { userId: demo.id, trackId: pythonTrack.id },
    });
    await prisma.freePlayCredit.upsert({
      where: { userId_trackId: { userId: demo.id, trackId: pythonTrack.id } },
      update: {},
      create: { userId: demo.id, trackId: pythonTrack.id, remaining: 10 },
    });
  }

  const badges = [
    { slug: 'first-win', title: 'First Victory', description: 'Complete your first lesson' },
    { slug: 'streak-7', title: 'Week Warrior', description: '7-day streak' },
    { slug: 'dsa-master', title: 'DSA Master', description: 'Complete DSA basics' },
  ];
  for (const b of badges) {
    await prisma.badge.upsert({ where: { slug: b.slug }, update: {}, create: b });
  }

  console.log('Seed complete.');
  console.log('Admin: admin@skillplay.dev / Admin123!');
  console.log('Demo:  demo@skillplay.dev / Demo1234!');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
