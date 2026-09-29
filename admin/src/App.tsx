import React, { useEffect, useState } from 'react';
import { api, getAuthToken } from './api';
import { Navbar } from './components/Navbar';
import { CourseList } from './components/CourseList';
import { HoleSelector } from './components/HoleSelector';
import { MappingEditor } from './components/MappingEditor';
import { Lock } from 'lucide-react';

export const App: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [courses, setCourses] = useState<any[]>([]);
  const [selectedCourse, setSelectedCourse] = useState<any>(null);
  const [courseHoles, setCourseHoles] = useState<any[]>([]);
  const [courseTees, setCourseTees] = useState<any[]>([]);
  const [selectedHole, setSelectedHole] = useState<any>(null);

  // Login form states
  const [email, setEmail] = useState('admin@techgolf.com');
  const [password, setPassword] = useState('AdminPassword123!');
  const [loginError, setLoginError] = useState<string | null>(null);
  const [loginLoading, setLoginLoading] = useState(false);

  // Check login on mount
  useEffect(() => {
    checkCurrentUser();
    loadCourses();
  }, []);

  const checkCurrentUser = async () => {
    const token = getAuthToken();
    if (!token) return;
    try {
      const user = await api.getMe();
      setCurrentUser(user);
    } catch {
      setCurrentUser(null);
    }
  };

  const loadCourses = async () => {
    try {
      const list = await api.getCourses();
      setCourses(list || []);
    } catch (err) {
      console.error('Failed to load courses:', err);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginError(null);
    try {
      const res = await api.login(email, password);
      setCurrentUser(res.user);
      loadCourses();
    } catch (err: any) {
      setLoginError(err.message || 'Login failed');
    } finally {
      setLoginLoading(false);
    }
  };

  const handleSelectCourse = async (course: any) => {
    setSelectedCourse(course);
    try {
      const [holes, tees] = await Promise.all([
        api.getHoles(course.id),
        api.getCourseTees(course.id),
      ]);
      setCourseHoles(holes || []);
      setCourseTees(tees || []);
      if (holes && holes.length > 0) {
        setSelectedHole(holes[0]);
      } else {
        setSelectedHole(null);
      }
    } catch (err) {
      console.error('Error loading course details:', err);
    }
  };

  const refreshCurrentHoles = async () => {
    if (!selectedCourse) return;
    try {
      const [holes, tees] = await Promise.all([
        api.getHoles(selectedCourse.id),
        api.getCourseTees(selectedCourse.id),
      ]);
      setCourseHoles(holes || []);
      setCourseTees(tees || []);
      if (selectedHole) {
        const refreshed = holes.find((h: any) => h.id === selectedHole.id);
        if (refreshed) setSelectedHole(refreshed);
      }
    } catch (err) {
      console.error('Error refreshing holes:', err);
    }
  };

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Navbar
        user={currentUser}
        selectedCourse={selectedCourse}
        onBackToCourses={() => {
          setSelectedCourse(null);
          setSelectedHole(null);
          loadCourses();
        }}
        onLogout={() => setCurrentUser(null)}
      />

      {/* Main Area */}
      {!currentUser && (
        <div
          style={{
            backgroundColor: '#1e293b',
            borderBottom: '1px solid #334155',
            padding: '12px 20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            fontSize: '13px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Lock size={16} color="#f59e0b" />
            <span>You are viewing in read-only mode. Login with Admin credentials to enable GIS mapping tools:</span>
          </div>
          <form onSubmit={handleLogin} style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@techgolf.com"
              style={{ padding: '6px 10px', borderRadius: '4px', border: '1px solid #475569', backgroundColor: '#0f172a', color: '#fff', fontSize: '12px' }}
            />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password"
              style={{ padding: '6px 10px', borderRadius: '4px', border: '1px solid #475569', backgroundColor: '#0f172a', color: '#fff', fontSize: '12px' }}
            />
            <button
              type="submit"
              disabled={loginLoading}
              style={{
                padding: '6px 12px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: '#10b981',
                color: '#fff',
                fontSize: '12px',
                cursor: 'pointer',
                fontWeight: 'bold',
              }}
            >
              {loginLoading ? 'Logging in...' : 'Login as Admin'}
            </button>
            {loginError && <span style={{ color: '#f87171', fontSize: '12px' }}>{loginError}</span>}
          </form>
        </div>
      )}

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {!selectedCourse ? (
          <CourseList
            courses={courses}
            onSelectCourse={handleSelectCourse}
            onRefreshCourses={loadCourses}
          />
        ) : (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            <HoleSelector
              courseId={selectedCourse.id}
              holes={courseHoles}
              selectedHole={selectedHole}
              onSelectHole={(h) => setSelectedHole(h)}
              onHolesChanged={refreshCurrentHoles}
            />

            <div style={{ flex: 1, overflow: 'hidden' }}>
              {selectedHole ? (
                <MappingEditor
                  key={selectedHole.id}
                  hole={selectedHole}
                  courseTees={courseTees}
                  onHoleUpdated={refreshCurrentHoles}
                />
              ) : (
                <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
                  No holes defined for this course yet. Click "Add Hole" in the bar above to start mapping.
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
export default App;
