import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { clearToken } from '../api';

export default function Layout() {
  const navigate = useNavigate();

  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>SkillPlay</h1>
        <p className="muted">Admin Control Center</p>
        <nav>
          <NavLink to="/" end>Dashboard</NavLink>
          <NavLink to="/users">Users</NavLink>
          <NavLink to="/content">Content</NavLink>
          <NavLink to="/audit">Audit Log</NavLink>
        </nav>
        <button className="btn-ghost" onClick={() => { clearToken(); navigate('/login'); }}>
          Sign out
        </button>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
