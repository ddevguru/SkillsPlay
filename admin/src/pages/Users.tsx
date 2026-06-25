import { useEffect, useState } from 'react';
import { api, User } from '../api';

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState('');

  async function load() {
    try {
      const res = await api.getUsers();
      setUsers(res.users);
      setTotal(res.total);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    }
  }

  useEffect(() => { load(); }, []);

  async function toggleBan(user: User) {
    await api.banUser(user.id, !user.isBanned);
    load();
  }

  return (
    <div>
      <h2>Users ({total})</h2>
      {error && <p className="error">{error}</p>}
      <table>
        <thead>
          <tr><th>Name</th><th>Email</th><th>Role</th><th>Plan</th><th>XP</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          {users.map((u) => (
            <tr key={u.id}>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>{u.role}</td>
              <td>{u.subscriptionStatus}</td>
              <td>{u.xp}</td>
              <td>{u.isBanned ? 'Banned' : 'Active'}</td>
              <td>
                <button className="btn-sm" onClick={() => toggleBan(u)}>
                  {u.isBanned ? 'Unban' : 'Ban'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
