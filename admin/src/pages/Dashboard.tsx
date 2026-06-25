import { useEffect, useState } from 'react';
import { api } from '../api';

export default function Dashboard() {
  const [data, setData] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api.getAnalytics().then(setData).catch((e) => setError(e.message));
  }, []);

  if (error) return <p className="error">{error}</p>;
  if (!data) return <p>Loading analytics...</p>;

  const revenue = ((data.revenueCents as number) ?? 0) / 100;

  return (
    <div>
      <h2>Analytics Dashboard</h2>
      <div className="grid">
        <div className="stat-card"><span>Total Users</span><strong>{data.totalUsers as number}</strong></div>
        <div className="stat-card"><span>DAU</span><strong>{data.dau as number}</strong></div>
        <div className="stat-card"><span>MAU</span><strong>{data.mau as number}</strong></div>
        <div className="stat-card"><span>Attempts</span><strong>{data.totalAttempts as number}</strong></div>
        <div className="stat-card"><span>Subscriptions</span><strong>{data.activeSubscriptions as number}</strong></div>
        <div className="stat-card"><span>Revenue</span><strong>${revenue.toFixed(2)}</strong></div>
      </div>
    </div>
  );
}
