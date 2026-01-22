import { useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './context/ThemeContext';
import { Sidebar } from './components/Sidebar';
import { ChatModal } from './components/ChatModal';
import { TasksModal, CalendarModal } from './components/FeatureModals';
import { Dashboard } from './pages/Dashboard';
import { Monitor } from './pages/Monitor';
import { Analytics } from './pages/Analytics';
import { Settings } from './pages/Settings';
import './index.css';

const queryClient = new QueryClient();

function AppContent() {
  const [activeModal, setActiveModal] = useState(null);

  const handleFeatureClick = (featureId) => {
    setActiveModal(featureId);
  };

  const closeModal = () => {
    setActiveModal(null);
  };

  return (
    <div className="flex min-h-screen" style={{ backgroundColor: 'var(--bg-primary)' }}>
      <Sidebar onFeatureClick={handleFeatureClick} />
      {/* Main content area needs margin-left to account for fixed sidebar */}
      <main className="flex-1 w-full min-h-screen relative ml-64">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/monitor" element={<Monitor />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/settings" element={<Settings />} />
          {/* Placeholders for other routes */}
          <Route path="/projects" element={<div className="p-10 pl-72">Projects (Coming Soon)</div>} />
          <Route path="/inbox" element={<div className="p-10 pl-72">Inbox (Coming Soon)</div>} />
          <Route path="/calendar" element={<div className="p-10 pl-72">Calendar (Coming Soon)</div>} />
        </Routes>
      </main>

      {/* Feature Modals */}
      <ChatModal isOpen={activeModal === 'chat'} onClose={closeModal} />
      <TasksModal isOpen={activeModal === 'tasks'} onClose={closeModal} />
      <CalendarModal isOpen={activeModal === 'calendar'} onClose={closeModal} />
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <ThemeProvider>
          <AppContent />
        </ThemeProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
