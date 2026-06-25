import { FormEvent, useEffect, useState } from 'react';
import { api, Track } from '../api';

export default function Content() {
  const [tracks, setTracks] = useState<Track[]>([]);
  const [message, setMessage] = useState('');

  useEffect(() => {
    api.getTracks().then(setTracks).catch(() => {});
  }, []);

  async function handleCreate(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    try {
      await api.createLesson({
        topicId: fd.get('topicId'),
        title: fd.get('title'),
        gameType: fd.get('gameType'),
        difficulty: fd.get('difficulty'),
        content: fd.get('content'),
        points: Number(fd.get('points')),
        configJson: JSON.parse((fd.get('configJson') as string) || '{}'),
      });
      setMessage('Lesson created successfully');
      e.currentTarget.reset();
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Failed to create lesson');
    }
  }

  const topics = tracks.flatMap((t) =>
    (t.topics ?? []).map((topic) => ({
      ...topic,
      trackTitle: t.title,
    }))
  );

  return (
    <div>
      <h2>Content Management</h2>
      <p className="muted">{tracks.length} tracks loaded. Fetch track details to list topics when creating lessons.</p>
      {message && <p className="info">{message}</p>}
      <form className="card form-card" onSubmit={handleCreate}>
        <h3>Create Lesson</h3>
        <label>Topic ID<input name="topicId" required placeholder="UUID from database" /></label>
        <label>Title<input name="title" required /></label>
        <label>Game Type
          <select name="gameType" defaultValue="MICRO_LESSON">
            <option>MICRO_LESSON</option>
            <option>PUZZLE_DRAG_DROP</option>
            <option>PUZZLE_REORDER</option>
            <option>CODE_COMPLETION</option>
            <option>TIMED_CHALLENGE</option>
            <option>SCENARIO_SIMULATION</option>
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
        <label>Content<textarea name="content" rows={3} required /></label>
        <label>Config JSON<textarea name="configJson" rows={5} defaultValue='{"expectedAnswer":"Yes"}' /></label>
        <button type="submit">Create Lesson</button>
      </form>
      {topics.length > 0 && (
        <div className="card" style={{ marginTop: 24 }}>
          <h3>Available Topics</h3>
          <ul>{topics.map((t) => <li key={t.id}>{t.trackTitle} → {t.title} <code>{t.id}</code></li>)}</ul>
        </div>
      )}
    </div>
  );
}
