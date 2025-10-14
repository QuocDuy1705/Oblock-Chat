import React, { useState } from 'react';
import { FiSearch, FiMessageSquare, FiUsers, FiLogOut, FiSettings } from 'react-icons/fi';
import { useAuth } from '../contexts/AuthContext';
import { useSocket } from '../contexts/SocketContext';
import { formatDistanceToNow } from 'date-fns';
import './Sidebar.css';

const Sidebar = ({ conversations, selectedConversation, onSelectConversation, onShowFriends, loading }) => {
  const { user, logout } = useAuth();
  const { onlineUsers } = useSocket();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredConversations = conversations.filter(conv => {
    if (!searchQuery) return true;
    
    if (conv.isGroup) {
      return conv.groupName.toLowerCase().includes(searchQuery.toLowerCase());
    } else {
      const otherUser = conv.participants.find(p => p.id !== user.id);
      return otherUser?.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
             otherUser?.username.toLowerCase().includes(searchQuery.toLowerCase());
    }
  });

  const getConversationName = (conv) => {
    if (conv.isGroup) {
      return conv.groupName;
    }
    const otherUser = conv.participants.find(p => p.id !== user.id);
    return otherUser?.displayName || 'Unknown';
  };

  const getConversationAvatar = (conv) => {
    if (conv.isGroup) {
      return null; // Show group icon
    }
    const otherUser = conv.participants.find(p => p.id !== user.id);
    return otherUser?.avatarUrl;
  };

  const isUserOnline = (conv) => {
    if (conv.isGroup) return false;
    const otherUser = conv.participants.find(p => p.id !== user.id);
    return onlineUsers.has(otherUser?.id);
  };

  const handleLogout = async () => {
    if (window.confirm('Are you sure you want to logout?')) {
      await logout();
    }
  };

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div className="user-profile">
          <div className="avatar-wrapper">
            {user?.avatarUrl ? (
              <img src={user.avatarUrl} alt={user.displayName} className="avatar" />
            ) : (
              <div className="avatar avatar-placeholder">
                {user?.displayName?.[0]?.toUpperCase()}
              </div>
            )}
            <div className="online-indicator"></div>
          </div>
          <div className="user-info">
            <h3>{user?.displayName}</h3>
            <p>@{user?.username}</p>
          </div>
        </div>
        <div className="header-actions">
          <button className="icon-btn" onClick={onShowFriends} title="Friends">
            <FiUsers />
          </button>
          <button className="icon-btn" onClick={handleLogout} title="Logout">
            <FiLogOut />
          </button>
        </div>
      </div>

      <div className="sidebar-search">
        <FiSearch className="search-icon" />
        <input
          type="text"
          placeholder="Search conversations..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="search-input"
        />
      </div>

      <div className="conversations-list">
        {loading ? (
          <div className="loading-conversations">
            <div className="spinner"></div>
            <p>Loading conversations...</p>
          </div>
        ) : filteredConversations.length === 0 ? (
          <div className="no-conversations">
            <FiMessageSquare size={48} />
            <p>No conversations yet</p>
            <button className="btn btn-primary" onClick={onShowFriends}>
              Start Chatting
            </button>
          </div>
        ) : (
          filteredConversations.map(conv => (
            <div
              key={conv._id}
              className={`conversation-item ${selectedConversation?._id === conv._id ? 'active' : ''}`}
              onClick={() => onSelectConversation(conv)}
            >
              <div className="conversation-avatar">
                {conv.isGroup ? (
                  <div className="avatar avatar-group">
                    <FiUsers />
                  </div>
                ) : getConversationAvatar(conv) ? (
                  <div className="avatar-wrapper">
                    <img src={getConversationAvatar(conv)} alt="" className="avatar" />
                    {isUserOnline(conv) && <div className="online-indicator"></div>}
                    {!isUserOnline(conv) && <div className="online-indicator offline-indicator"></div>}
                  </div>
                ) : (
                  <div className="avatar-wrapper">
                    <div className="avatar avatar-placeholder">
                      {getConversationName(conv)[0]?.toUpperCase()}
                    </div>
                    {isUserOnline(conv) && <div className="online-indicator"></div>}
                    {!isUserOnline(conv) && <div className="online-indicator offline-indicator"></div>}
                  </div>
                )}
              </div>

              <div className="conversation-info">
                <div className="conversation-header">
                  <h4>{getConversationName(conv)}</h4>
                  {conv.lastMessage?.createdAt && (
                    <span className="conversation-time">
                      {formatDistanceToNow(new Date(conv.lastMessage.createdAt), { addSuffix: true })}
                    </span>
                  )}
                </div>
                <div className="conversation-preview">
                  <p className="last-message">
                    {conv.lastMessage?.imgUrl && '📷 '}
                    {conv.lastMessage?.content || 'No messages yet'}
                  </p>
                  {conv.unreadCount > 0 && (
                    <span className="unread-badge">{conv.unreadCount}</span>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Sidebar;
