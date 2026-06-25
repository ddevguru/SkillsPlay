import { useEffect, useState } from 'react';
import { api, AuditEntry } from '../api';

export default function AuditLog() {
  const [logs, setLogs] = useState<AuditEntry[]>([]);

  useEffect(() => {
    api.getAuditLog().then(setLogs).catch(() => {});
  }, []);

  return (
    <div>
      <h2>Audit Log</h2>
      <table>
        <thead>
          <tr><th>Time</th><th>Admin</th><th>Action</th><th>Target</th></tr>
        </thead>
        <tbody>
          {logs.map((l) => (
            <tr key={l.id}>
              <td>{new Date(l.timestamp).toLocaleString()}</td>
              <td>{l.admin.name}</td>
              <td>{l.action}</td>
              <td><code>{l.target}</code></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
