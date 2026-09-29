const BASE_URL = '/api/v1';

export function getAuthToken(): string | null {
  return localStorage.getItem('techgolf_admin_token');
}

export function setAuthToken(token: string) {
  localStorage.setItem('techgolf_admin_token', token);
}

export function clearAuthToken() {
  localStorage.removeItem('techgolf_admin_token');
}

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    throw new Error(errorBody.message || `Request failed with status ${response.status}`);
  }

  return response.json();
}

export const api = {
  // Auth
  async login(email: string, password: string) {
    const res = await request<{ user: any; accessToken: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    setAuthToken(res.accessToken);
    return res;
  },

  async getMe() {
    return request<any>('/auth/me');
  },

  // Courses
  async getCourses(search?: string) {
    const q = search ? `?search=${encodeURIComponent(search)}` : '';
    return request<any[]>(`/courses${q}`);
  },

  async getCourse(id: string) {
    return request<any>(`/courses/${id}`);
  },

  async createCourse(data: any) {
    return request<any>('/courses', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updateCourse(id: string, data: any) {
    return request<any>(`/courses/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  async deleteCourse(id: string) {
    return request<{ success: boolean; message: string }>(`/courses/${id}`, {
      method: 'DELETE',
    });
  },

  // Holes
  async getHoles(courseId: string) {
    return request<any[]>(`/courses/${courseId}/holes`);
  },

  async getHole(id: string) {
    return request<any>(`/holes/${id}`);
  },

  async createHole(courseId: string, data: any) {
    return request<any>(`/courses/${courseId}/holes`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updateHole(id: string, data: any) {
    return request<any>(`/holes/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  async deleteHole(id: string) {
    return request<any>(`/holes/${id}`, {
      method: 'DELETE',
    });
  },

  async getHoleMap(holeId: string) {
    return request<{ type: string; features: any[] }>(`/holes/${holeId}/map`);
  },

  // Polygons
  async createPolygon(holeId: string, data: { polygon_type: string; coordinates: number[][][]; metadata?: any }) {
    return request<any>(`/holes/${holeId}/polygons`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async deletePolygon(id: string) {
    return request<any>(`/polygons/${id}`, {
      method: 'DELETE',
    });
  },

  // Tees
  async getCourseTees(courseId: string) {
    return request<any[]>(`/courses/${courseId}/tees`);
  },

  async createCourseTee(courseId: string, data: any) {
    return request<any>(`/courses/${courseId}/tees`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async setHoleTee(holeId: string, data: { course_tee_id: string; tee_position: [number, number]; distance_meters?: number }) {
    return request<any>(`/holes/${holeId}/tees`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async deleteHoleTee(id: string) {
    return request<any>(`/hole-tees/${id}`, {
      method: 'DELETE',
    });
  },
};
