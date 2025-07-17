import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import LiveTrackingPage from './pages/LiveTrackingPage';
import Login from './components/Login';
import { initializeOpenTelemetry, getTracingService } from './tracing';

// Initialize OpenTelemetry on app startup
console.log('🚀 Starting Surveyor Tracking Dashboard with OpenTelemetry...');
const tracer = initializeOpenTelemetry();
const tracingService = getTracingService();

// Trace app initialization
const appInitSpan = tracingService.traceUserInteraction('app-init', 'app-root', {
  'app.name': 'surveyor-tracking-dashboard',
  'app.version': '1.0.0'
});

// Create a theme instance
const theme = createTheme({
  palette: {
    primary: {
      main: '#6366f1', // Indigo from your current color scheme
    },
    secondary: {
      main: '#60a5fa', // Light blue from your gradient
    },
    background: {
      default: '#f8fafc',
    },
  },
});

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Trace app mount
    const mountSpan = tracingService.traceUserInteraction('app-mount', 'app-component');
    
    // Check if user is already logged in from localStorage
    const loggedInUser = localStorage.getItem('loggedInUser');
    if (loggedInUser) {
      try {
        const userData = JSON.parse(loggedInUser);
        setUser(userData);
        mountSpan.end({ 'auth.restored': true, 'user.id': userData.id });
      } catch (error) {
        console.error('Failed to parse stored user data', error);
        localStorage.removeItem('loggedInUser');
        mountSpan.end({ 'auth.restored': false, 'auth.error': 'parse_error' });
      }
    } else {
      mountSpan.end({ 'auth.restored': false, 'auth.status': 'no_stored_user' });
    }
    
    setLoading(false);
    appInitSpan.end({ 'app.loaded': true });
  }, []);

  const handleLogin = (userData) => {
    const loginSpan = tracingService.traceUserInteraction('login', 'auth-component', {
      'user.id': userData.id,
      'user.type': userData.type
    });
    
    setUser(userData);
    localStorage.setItem('loggedInUser', JSON.stringify(userData));
    
    loginSpan.end({ 'login.success': true });
  };

  const handleLogout = () => {
    const logoutSpan = tracingService.traceUserInteraction('logout', 'auth-component', {
      'user.id': user?.id
    });
    
    setUser(null);
    localStorage.removeItem('loggedInUser');
    
    logoutSpan.end({ 'logout.success': true });
  };

  // Protected route wrapper
  const ProtectedRoute = ({ children }) => {
    if (loading) return <div>Loading...</div>;
    if (!user) return <Navigate to="/login" />;
    return children;
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <div className="App">
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={
              user ? <Navigate to="/" /> : <Login onLogin={handleLogin} />
            } />
            <Route path="/" element={
              <ProtectedRoute>
                <LiveTrackingPage user={user} onLogout={handleLogout} />
              </ProtectedRoute>
            } />
          </Routes>
        </BrowserRouter>
      </div>
    </ThemeProvider>
  );
}

export default App;
