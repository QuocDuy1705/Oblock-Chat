import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useSocket } from '../contexts/SocketContext';
import Sidebar from '../components/Sidebar';
import ChatArea from '../components/ChatArea';
import FriendsPanel from '../components/FriendsPanel';
import axios from 'axios';
import { toast } from 'react-toastify';
import './Dashboard.css';

const Dashboard = () => {
  const { user } = useAuth();
  const { socket } = useSocket();
  const [conversations, setConversations] = useState([]);
  const [selectedConversation, setSelectedConversation] = useState(null);
  const [showFriendsPanel, setShowFriendsPanel] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadConversations();
  }, []);

  // Listen for new messages
  useEffect(() => {
    if (!socket) return;

    socket.on('message:new', ({ message, conversation }) => {
      // Update conversation in list
      setConversations(prev => {
        const updated = prev.map(conv => 
          conv._id === conversation.id
            ? { ...conv, lastMessage: conversation.lastMessage, updatedAt: new Date() }
            : conv
        );
        // Sort by updatedAt
        return updated.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
      });

      // If it's the selected conversation, we'll handle it in ChatArea
    });

    socket.on('conversation:unread', ({ conversationId, unreadCount }) => {
      setConversations(prev =>
        prev.map(conv =>
          conv._id === conversationId
            ? { ...conv, unreadCount }
            : conv
        )
      );
    });

    return () => {
      socket.off('message:new');
      socket.off('conversation:unread');
    };
  }, [socket]);

  const loadConversations = async () => {
    try {
      const response = await axios.get('/api/conversations');
      setConversations(response.data.conversations);
    } catch (error) {
      console.error('Load conversations error:', error);
      toast.error('Failed to load conversations');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectConversation = (conversation) => {
    setSelectedConversation(conversation);
    setShowFriendsPanel(false);
  };

  const handleCreateConversation = async (userId) => {
    try {
      const response = await axios.post(`/api/conversations/direct/${userId}`);
      const conversation = response.data.conversation;
      
      // Add to conversations if not already there
      setConversations(prev => {
        const exists = prev.find(c => c._id === conversation._id);
        if (exists) {
          return prev;
        }
        return [conversation, ...prev];
      });

      setSelectedConversation(conversation);
      setShowFriendsPanel(false);
    } catch (error) {
      console.error('Create conversation error:', error);
      toast.error('Failed to create conversation');
    }
  };

  const handleCreateGroup = async (participantIds, groupName) => {
    try {
      const response = await axios.post('/api/conversations/group', {
        participantIds,
        groupName
      });
      const conversation = response.data.conversation;
      
      setConversations(prev => [conversation, ...prev]);
      setSelectedConversation(conversation);
      toast.success('Group created successfully');
    } catch (error) {
      console.error('Create group error:', error);
      toast.error('Failed to create group');
    }
  };

  return (
    <div className="dashboard">
      <Sidebar
        conversations={conversations}
        selectedConversation={selectedConversation}
        onSelectConversation={handleSelectConversation}
        onShowFriends={() => setShowFriendsPanel(true)}
        loading={loading}
      />

      {selectedConversation ? (
        <ChatArea
          conversation={selectedConversation}
          onBack={() => setSelectedConversation(null)}
        />
      ) : (
        <div className="no-conversation-selected">
          <div className="empty-state">
            <h2>Welcome to Oblock Chat</h2>
            <p>Select a conversation to start messaging</p>
            <button
              className="btn btn-primary"
              onClick={() => setShowFriendsPanel(true)}
            >
              Start a New Chat
            </button>
          </div>
        </div>
      )}

      {showFriendsPanel && (
        <FriendsPanel
          onClose={() => setShowFriendsPanel(false)}
          onStartConversation={handleCreateConversation}
          onCreateGroup={handleCreateGroup}
        />
      )}
    </div>
  );
};

export default Dashboard;
