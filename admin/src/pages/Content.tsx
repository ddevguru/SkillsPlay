import { FormEvent, useEffect, useState } from 'react';
import { api, Track, Lesson, Topic } from '../api';

const GAME_TYPES = [
  'MICRO_LESSON',
  'PUZZLE_DRAG_DROP',
  'PUZZLE_REORDER',
  'CODE_COMPLETION',
  'TIMED_CHALLENGE',
  'SCENARIO_SIMULATION',
];

const GAME_LABELS: Record<string, string> = {
  MICRO_LESSON: 'Quiz Lesson',
  PUZZLE_DRAG_DROP: 'Drag & Drop',
  PUZZLE_REORDER: 'Reorder Puzzle',
  CODE_COMPLETION: 'Code Challenge',
  TIMED_CHALLENGE: 'Timed Code',
  SCENARIO_SIMULATION: 'Scenario',
};

const DEFAULT_CONFIGS: Record<string, object> = {
  MICRO_LESSON: {
    slides: [{ title: 'Intro', body: 'Learn the concept.' }],
    quiz: { question: 'Got it?', options: ['Yes'], expectedAnswer: 'Yes' },
    expectedAnswer: 'Yes',
  },
  PUZZLE_REORDER: { items: ['Step 1', 'Step 2', 'Step 3'], correctOrder: [0, 1, 2], expectedAnswer: [0, 1, 2] },
  PUZZLE_DRAG_DROP: {
    items: [{ id: 'a', label: 'Concept A' }, { id: 'b', label: 'Concept B' }],
    zones: [{ id: 'z1', label: 'Category 1' }],
    correctMapping: { a: 'z1', b: 'z1' },
    expectedAnswer: { a: 'z1', b: 'z1' },
  },
  CODE_COMPLETION: {
    language: 'python',
    starterCode: 'def solve(nums):\n    return sum(nums)\n',
    expectedAnswer: 'pass',
  },
  TIMED_CHALLENGE: {
    language: 'python',
    starterCode: 'def solve(nums):\n    return sum(nums)\n',
    timeLimitSeconds: 120,
    expectedAnswer: 'pass',
  },
  SCENARIO_SIMULATION: {
    steps: [{ prompt: 'What do you do?', options: ['A', 'B'], correct: 'A' }],
    expectedAnswer: ['A'],
  },
};

export default function Content() {
  const [tracks, setTracks] = useState<Track[]>([]);
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [selectedTrackId, setSelectedTrackId] = useState('');
  const [selectedTopicId, setSelectedTopicId] = useState('');
  const [message, setMessage] = useState('');
  const [tab, setTab] = useState<'browse' | 'track' | 'topic' | 'lesson'>('browse');

  const selectedTrack = tracks.find((t) => t.id === selectedTrackId);
  const topics: Topic[] = selectedTrack?.topics ?? [];

  async function refresh() {
    const [t, l] = await Promise.all([api.getTracks(), api.getLessons()]);
    setTracks(t);
    setLessons(l);
  }

  useEffect(() => {
    refresh().catch(() => {});
  }, []);

  function notify(msg: string) {
    setMessage(msg);
    setTimeout(() => setMessage(''), 4000);
  }

  async function handleCreateTrack(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    try {
      await api.createTrack({
        slug: fd.get('slug'),
        title: fd.get('title'),
        description: fd.get('description'),
      });
      notify('Track created');
      e.currentTarget.reset();
      await refresh();
    } catch (err) {
      notify(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function handleCreateTopic(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    try {
      await api.createTopic({
        trackId: fd.get('trackId'),
        title: fd.get('title'),
        description: fd.get('description'),
        difficulty: fd.get('difficulty'),
      });
      notify('Topic created with review text');
      e.currentTarget.reset();
      await refresh();
    } catch (err) {
      notify(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function handleCreateLesson(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    const gameType = fd.get('gameType') as string;
    try {
      await api.createLesson({
        topicId: fd.get('topicId'),
        title: fd.get('title'),
        gameType,
        difficulty: fd.get('difficulty'),
        content: fd.get('content'),
        points: Number(fd.get('points')),
        configJson: JSON.parse((fd.get('configJson') as string) || JSON.stringify(DEFAULT_CONFIGS[gameType])),
      });
      notify('Game/lesson created');
      e.currentTarget.reset();
      await refresh();
    } catch (err) {
      notify(err instanceof Error ? err.message : 'Failed');
    }
  }

  async function handleDeleteLesson(id: string) {
    if (!confirm('Delete this game?')) return;
    try {
      await api.deleteLesson(id);
      notify('Game deleted');
      await refresh();
    } catch (err) {
      notify(err instanceof Error ? err.message : 'Failed');
    }
  }

  return (
    <div>
      <h2>Content Management</h2>
      <p className="muted">Add tracks, topics (with review), and games. Users see games when they open a topic in the app.</p>
      {message && <p className="info">{message}</p>}

      <div className="tabs" style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {(['browse', 'track', 'topic', 'lesson'] as const).map((t) => (
          <button key={t} type="button" className={tab === t ? 'active' : ''} onClick={() => setTab(t)}>
            {t === 'browse' ? 'Browse' : `Add ${t}`}
          </button>
        ))}
      </div>

      {tab === 'browse' && (
        <div className="card">
          <h3>All Content ({tracks.length} tracks, {lessons.length} games)</h3>
          {tracks.map((track) => (
            <div key={track.id} style={{ marginBottom: 20 }}>
              <strong>{track.title}</strong>
              <p className="muted">{track.description}</p>
              {(track.topics ?? []).map((topic) => (
                <div key={topic.id} style={{ marginLeft: 16, marginTop: 8 }}>
                  <div>📚 {topic.title} {topic.description && <span className="muted">— {topic.description}</span>}</div>
                  <ul>
                    {lessons
                      .filter((l) => l.topicId === topic.id)
                      .map((l) => (
                        <li key={l.id}>
                          🎮 {l.title} <code>{GAME_LABELS[l.gameType] ?? l.gameType}</code> ({l.points} pts)
                          <button type="button" style={{ marginLeft: 8 }} onClick={() => handleDeleteLesson(l.id)}>Delete</button>
                        </li>
                      ))}
                  </ul>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}

      {tab === 'track' && (
        <form className="card form-card" onSubmit={handleCreateTrack}>
          <h3>Add Track</h3>
          <label>Slug<input name="slug" required placeholder="react-basics" /></label>
          <label>Title<input name="title" required placeholder="React Basics" /></label>
          <label>Description<textarea name="description" rows={2} /></label>
          <button type="submit">Create Track</button>
        </form>
      )}

      {tab === 'topic' && (
        <form className="card form-card" onSubmit={handleCreateTopic}>
          <h3>Add Topic + Review</h3>
          <label>Track
            <select name="trackId" required value={selectedTrackId} onChange={(e) => setSelectedTrackId(e.target.value)}>
              <option value="">Select track</option>
              {tracks.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
          </label>
          <label>Topic Title<input name="title" required placeholder="Hooks & State" /></label>
          <label>Topic Review (shown in app)<textarea name="description" rows={3} placeholder="What students will learn..." required /></label>
          <label>Difficulty
            <select name="difficulty" defaultValue="BASICS">
              <option>BASICS</option>
              <option>INTERMEDIATE</option>
              <option>ADVANCED</option>
            </select>
          </label>
          <button type="submit">Create Topic</button>
        </form>
      )}

      {tab === 'lesson' && (
        <form className="card form-card" onSubmit={handleCreateLesson}>
          <h3>Add Game (Lesson)</h3>
          <label>Track
            <select value={selectedTrackId} onChange={(e) => { setSelectedTrackId(e.target.value); setSelectedTopicId(''); }}>
              <option value="">Select track</option>
              {tracks.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
          </label>
          <label>Topic
            <select name="topicId" required value={selectedTopicId} onChange={(e) => setSelectedTopicId(e.target.value)}>
              <option value="">Select topic</option>
              {topics.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
          </label>
          <label>Game Title<input name="title" required placeholder="Arrays Quiz — Level 1" /></label>
          <label>Game Type
            <select name="gameType" defaultValue="MICRO_LESSON">
              {GAME_TYPES.map((g) => <option key={g} value={g}>{GAME_LABELS[g]}</option>)}
            </select>
          </label>
          <label>Difficulty
            <select name="difficulty" defaultValue="BASICS">
              <option>BASICS</option>
              <option>INTERMEDIATE</option>
              <option>ADVANCED</option>
            </select>
          </label>
          <label>Points<input name="points" type="number" defaultValue={10} /></label>
          <label>Instructions<textarea name="content" rows={3} required placeholder="Solve this challenge..." /></label>
          <label>Config JSON<textarea name="configJson" rows={6} defaultValue={JSON.stringify(DEFAULT_CONFIGS.MICRO_LESSON, null, 2)} /></label>
          <button type="submit">Create Game</button>
        </form>
      )}
    </div>
  );
}
