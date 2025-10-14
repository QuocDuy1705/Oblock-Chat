import React, { createContext, useContext, useEffect, useState } from 'react';
import io from 'socket.io-client';
import { useAuth } from './AuthContext';

const SocketContext = createContext();

export const useSocket = () => {
  const context = useContext(SocketContext);
  if (!context) {
    throw new Error('useSocket must be used within a SocketProvider');
  }
  return context;
};

export const SocketProvider = ({ children }) => {
  const [socket, setSocket] = useState(null);
  const [connected, setConnected] = useState(false);
  const [onlineUsers, setOnlineUsers] = useState(new Set());
  const { accessToken, user } = useAuth();

  useEffect(() => {
    if (accessToken && user) {
      // Initialize socket connection
      const newSocket = io('http://localhost:5000', {
        auth: {
          token: accessToken
        }
      });

      newSocket.on('connect', () => {
        console.log('Socket connected');
        setConnected(true);
      });

      newSocket.on('disconnect', () => {
        console.log('Socket disconnected');
        setConnected(false);
      });

      // Handle user online/offline status
      newSocket.on('user:online', ({ userId, isOnline }) => {
        setOnlineUsers(prev => {
          const updated = new Set(prev);
          if (isOnline) {
            updated.add(userId);
          } else {
            updated.delete(userId);
          }
          return updated;
        });
      });

      newSocket.on('error', (error) => {
        console.error('Socket error:', error);
      });

      setSocket(newSocket);

      return () => {
        newSocket.close();
      };
    } else {
      if (socket) {
        socket.close();
        setSocket(null);
        setConnected(false);
      }
    }
  }, [accessToken, user]);

  const joinConversation = (conversationId) => {
    if (socket) {
      socket.emit('conversation:join', conversationId);
    }
  };

  const leaveConversation = (conversationId) => {
    if (socket) {
      socket.emit('conversation:leave', conversationId);
    }
  };

  const sendMessage = (conversationId, content, imgUrl = '') => {
    if (socket) {
      socket.emit('message:send', { conversationId, content, imgUrl });
    }
  };

  const startTyping = (conversationId) => {
    if (socket) {
      socket.emit('typing:start', conversationId);
    }
  };

  const stopTyping = (conversationId) => {
    if (socket) {
      socket.emit('typing:stop', conversationId);
    }
  };

  const markMessagesAsSeen = (conversationId, messageIds = null) => {
    if (socket) {
      socket.emit('message:seen', { conversationId, messageIds });
    }
  };

  const reactToMessage = (messageId, emoji) => {
    if (socket) {
      socket.emit('message:react', { messageId, emoji });
    }
  };

  const editMessage = (messageId, content) => {
    if (socket) {
      socket.emit('message:edit', { messageId, content });
    }
  };

  const deleteMessage = (messageId) => {
    if (socket) {
      socket.emit('message:delete', { messageId });
    }
  };

  const value = {
    socket,
    connected,
    onlineUsers,
    joinConversation,
    leaveConversation,
    sendMessage,
    startTyping,
    stopTyping,
    markMessagesAsSeen,
    reactToMessage,
    editMessage,
    deleteMessage
  };

  return <SocketContext.Provider value={value}>{children}</SocketContext.Provider>;
};
