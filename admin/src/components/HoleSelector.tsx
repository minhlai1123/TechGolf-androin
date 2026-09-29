import React, { useState } from 'react';
import { api } from '../api';
import { Plus } from 'lucide-react';

interface HoleSelectorProps {
  courseId: string;
  holes: any[];
  selectedHole: any;
  onSelectHole: (hole: any) => void;
  onHolesChanged: () => void;
}

export const HoleSelector: React.FC<HoleSelectorProps> = ({
  courseId,
  holes,
  selectedHole,
  onSelectHole,
  onHolesChanged,
}) => {
  const [showAddModal, setShowAddModal] = useState(false);
  const [newHoleNum, setNewHoleNum] = useState<number>(holes.length + 1);
  const [newPar, setNewPar] = useState<number>(4);
  const [newHcp, setNewHcp] = useState<number>(holes.length + 1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCreateHole = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const created = await api.createHole(courseId, {
        hole_number: Number(newHoleNum),
        par: Number(newPar),
        handicap_index: Number(newHcp),
      });
      setShowAddModal(false);
      onHolesChanged();
      onSelectHole(created);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        height: '48px',
        backgroundColor: '#1e293b',
        borderBottom: '1px solid #334155',
        display: 'flex',
        alignItems: 'center',
        padding: '0 16px',
        gap: '8px',
        overflowX: 'auto',
      }}
    >
      <span style={{ fontSize: '13px', fontWeight: 'bold', color: '#94a3b8', whiteSpace: 'nowrap' }}>
        HOLES:
      </span>

      {holes.map((hole) => {
        const isSelected = selectedHole?.id === hole.id;
        return (
          <button
            key={hole.id}
            onClick={() => onSelectHole(hole)}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: isSelected ? '1px solid #10b981' : '1px solid #334155',
              backgroundColor: isSelected ? '#064e3b' : '#0f172a',
              color: isSelected ? '#34d399' : '#cbd5e1',
              cursor: 'pointer',
              fontSize: '12px',
              fontWeight: isSelected ? 'bold' : 'normal',
              whiteSpace: 'nowrap',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span>Hole {hole.hole_number}</span>
            <span style={{ fontSize: '10px', color: isSelected ? '#a7f3d0' : '#64748b' }}>
              P{hole.par}
            </span>
          </button>
        );
      })}

      <button
        onClick={() => {
          setNewHoleNum(holes.length + 1);
          setNewHcp(holes.length + 1);
          setShowAddModal(true);
        }}
        style={{
          padding: '6px 10px',
          borderRadius: '6px',
          border: '1px dashed #475569',
          backgroundColor: 'transparent',
          color: '#38bdf8',
          cursor: 'pointer',
          fontSize: '12px',
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          whiteSpace: 'nowrap',
        }}
      >
        <Plus size={14} /> Add Hole
      </button>

      {/* Add Hole Modal */}
      {showAddModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.7)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
          }}
        >
          <div
            style={{
              backgroundColor: '#1e293b',
              padding: '24px',
              borderRadius: '8px',
              width: '320px',
              border: '1px solid #334155',
            }}
          >
            <h3 style={{ marginBottom: '16px', fontSize: '16px' }}>Add Hole to Course</h3>
            {error && (
              <p style={{ color: '#f87171', fontSize: '12px', marginBottom: '12px' }}>{error}</p>
            )}
            <form onSubmit={handleCreateHole}>
              <div style={{ marginBottom: '12px' }}>
                <label style={{ fontSize: '12px', color: '#94a3b8' }}>Hole Number:</label>
                <input
                  type="number"
                  min="1"
                  max="72"
                  value={newHoleNum}
                  onChange={(e) => setNewHoleNum(Number(e.target.value))}
                  style={{ width: '100%', padding: '8px', borderRadius: '4px', backgroundColor: '#0f172a', color: '#fff', border: '1px solid #334155' }}
                  required
                />
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label style={{ fontSize: '12px', color: '#94a3b8' }}>Par Value:</label>
                <select
                  value={newPar}
                  onChange={(e) => setNewPar(Number(e.target.value))}
                  style={{ width: '100%', padding: '8px', borderRadius: '4px', backgroundColor: '#0f172a', color: '#fff', border: '1px solid #334155' }}
                >
                  <option value={3}>Par 3</option>
                  <option value={4}>Par 4</option>
                  <option value={5}>Par 5</option>
                  <option value={6}>Par 6</option>
                </select>
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ fontSize: '12px', color: '#94a3b8' }}>Stroke Index (Handicap):</label>
                <input
                  type="number"
                  min="1"
                  max="72"
                  value={newHcp}
                  onChange={(e) => setNewHcp(Number(e.target.value))}
                  style={{ width: '100%', padding: '8px', borderRadius: '4px', backgroundColor: '#0f172a', color: '#fff', border: '1px solid #334155' }}
                  required
                />
              </div>
              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  style={{ padding: '8px 14px', borderRadius: '6px', border: 'none', backgroundColor: '#334155', color: '#fff', cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  style={{ padding: '8px 14px', borderRadius: '6px', border: 'none', backgroundColor: '#10b981', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}
                >
                  {loading ? 'Adding...' : 'Add Hole'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
