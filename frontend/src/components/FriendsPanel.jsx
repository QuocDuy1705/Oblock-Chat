import React, { useState, useEffect } from 'react';
import { FiX, FiUserPlus, FiSearch, FiCheck, FiXCircle, FiUsers } from 'react-icons/fi';
import { useAuth } from '../contexts/AuthContext';
import { useSocket } from '../contexts/SocketContext';
import axios from 'axios';
import { toast } from 'react-toastify';
import './FriendsPanel.css';

const FriendsPanel = ({ onClose, onStartConversation, onCreateGroup }) => {
  const { user } = useAuth();
  const { onlineUsers } = useSocket();
  const [activeTab, setActiveTab] = useState('friends'); // friends, requests, search, create-group
  const [friends, setFriends] = useState([]);
  const [friendRequests, setFriendRequests] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedForGroup, setSelectedForGroup] = useState([]);
  const [groupName, setGroupName] = useState('');

  useEffect(() => {
    loadFriends();
    loadFriendRequests();
  }, []);

  const loadFriends = async () => {
    try {
      const response = await axios.get('/api/friends');
      setFriends(response.data.friends);
    } catch (error) {
      console.error('Load friends error:', error);
    }
  };

  const loadFriendRequests = async () => {
    try {
      const response = await axios.get('/api/friends/requests');
      setFriendRequests(response.data.requests);
    } catch (error) {
      console.error('Load friend requests error:', error);
    }
  };

  const handleSearch = async () => {
    if (searchQuery.length < 2) {
      toast.error('Search query must be at least 2 characters');
      return;
    }

    setLoading(true);
    try {
      const response = await axios.get(`/api/users/search?q=${searchQuery}`);
      setSearchResults(response.data.users);
    } catch (error) {
      console.error('Search error:', error);
      toast.error('Search failed');
    } finally {
      setLoading(false);
    }
  };

  const handleSendFriendRequest = async (userId) => {
    try {
      await axios.post(`/api/friends/request/${userId}`);
      toast.success('Friend request sent!');
      setSearchResults(prev => prev.filter(u => u.id !== userId));
    } catch (error) {
      console.error('Send friend request error:', error);
      toast.error(error.response?.data?.message || 'Failed to send friend request');
    }
  };

  const handleAcceptRequest = async (requestId) => {
    try {
      await axios.put(`/api/friends/request/${requestId}/accept`);
      toast.success('Friend request accepted!');
      loadFriends();
      loadFriendRequests();
    } catch (error) {
      console.error('Accept request error:', error);
      toast.error('Failed to accept request');
    }
  };

  const handleDeclineRequest = async (requestId) => {
    try {
      await axios.put(`/api/friends/request/${requestId}/decline`);
      toast.success('Friend request declined');
      loadFriendRequests();
    } catch (error) {
      console.error('Decline request error:', error);
      toast.error('Failed to decline request');
    }
  };

  const handleToggleGroupMember = (friendId) => {
    setSelectedForGroup(prev =>
      prev.includes(friendId)
        ? prev.filter(id => id !== friendId)
        : [...prev, friendId]
    );
  };

  const handleCreateGroup = () => {
    if (selectedForGroup.length < 2) {
      toast.error('Select at least 2 friends for a group');
      return;
    }
    if (!groupName.trim()) {
      toast.error('Please enter a group name');
      return;
    }

    onCreateGroup(selectedForGroup, groupName);
    onClose();
  };

  return (
    <div className="friends-panel-overlay" onClick={onClose}>
      <div className="friends-panel" onClick={(e) => e.stopPropagation()}>
        <div className="panel-header">
          <h2>Friends & Contacts</h2>
          <button className="icon-btn" onClick={onClose}>
            <FiX />
          </button>
        </div>

        <div className="panel-tabs">
          <button
            className={`tab ${activeTab === 'friends' ? 'active' : ''}`}
            onClick={() => setActiveTab('friends')}
          >
            Friends ({friends.length})
          </button>
          <button
            className={`tab ${activeTab === 'requests' ? 'active' : ''}`}
            onClick={() => setActiveTab('requests')}
          >
            Requests ({friendRequests.length})
          </button>
          <button
            className={`tab ${activeTab === 'search' ? 'active' : ''}`}
            onClick={() => setActiveTab('search')}
          >
            Add Friends
          </button>
          <button
            className={`tab ${activeTab === 'create-group' ? 'active' : ''}`}
            onClick={() => setActiveTab('create-group')}
          >
            New Group
          </button>
        </div>

        <div className="panel-content">
          {activeTab === 'friends' && (
            <div className="friends-list">
              {friends.length === 0 ? (
                <div className="empty-state">
                  <p>No friends yet</p>
                  <button
                    className="btn btn-primary"
                    onClick={() => setActiveTab('search')}
                  >
                    Add Friends
                  </button>
                </div>
              ) : (
                friends.map(friend => (
                  <div key={friend.id} className="friend-item">
                    <div className="friend-avatar-wrapper">
                      {friend.avatarUrl ? (
                        <img src={friend.avatarUrl} alt={friend.displayName} className="avatar" />
                      ) : (
                        <div className="avatar avatar-placeholder">
                          {friend.displayName[0]?.toUpperCase()}
                        </div>
                      )}
                      {onlineUsers.has(friend.id) && <div className="online-indicator"></div>}
                      {!onlineUsers.has(friend.id) && <div className="online-indicator offline-indicator"></div>}
                    </div>
                    <div className="friend-info">
                      <h4>{friend.displayName}</h4>
                      <p>@{friend.username}</p>
                    </div>
                    <button
                      className="btn btn-primary btn-sm"
                      onClick={() => onStartConversation(friend.id)}
                    >
                      Message
                    </button>
                  </div>
                ))
              )}
            </div>
          )}

          {activeTab === 'requests' && (
            <div className="requests-list">
              {friendRequests.length === 0 ? (
                <div className="empty-state">
                  <p>No friend requests</p>
                </div>
              ) : (
                friendRequests.map(request => (
                  <div key={request._id} className="request-item">
                    <div className="friend-avatar-wrapper">
                      {request.from.avatarUrl ? (
                        <img src={request.from.avatarUrl} alt={request.from.displayName} className="avatar" />
                      ) : (
                        <div className="avatar avatar-placeholder">
                          {request.from.displayName[0]?.toUpperCase()}
                        </div>
                      )}
                    </div>
                    <div className="friend-info">
                      <h4>{request.from.displayName}</h4>
                      <p>@{request.from.username}</p>
                      {request.message && <p className="request-message">{request.message}</p>}
                    </div>
                    <div className="request-actions">
                      <button
                        className="btn btn-success btn-sm"
                        onClick={() => handleAcceptRequest(request._id)}
                      >
                        <FiCheck /> Accept
                      </button>
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => handleDeclineRequest(request._id)}
                      >
                        <FiXCircle /> Decline
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}

          {activeTab === 'search' && (
            <div className="search-section">
              <div className="search-box">
                <input
                  type="text"
                  placeholder="Search by username or name..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                  className="input"
                />
                <button
                  className="btn btn-primary"
                  onClick={handleSearch}
                  disabled={loading}
                >
                  {loading ? <div className="spinner spinner-sm"></div> : <FiSearch />}
                  Search
                </button>
              </div>

              <div className="search-results">
                {searchResults.map(result => (
                  <div key={result.id} className="friend-item">
                    <div className="friend-avatar-wrapper">
                      {result.avatarUrl ? (
                        <img src={result.avatarUrl} alt={result.displayName} className="avatar" />
                      ) : (
                        <div className="avatar avatar-placeholder">
                          {result.displayName[0]?.toUpperCase()}
                        </div>
                      )}
                    </div>
                    <div className="friend-info">
                      <h4>{result.displayName}</h4>
                      <p>@{result.username}</p>
                    </div>
                    <button
                      className="btn btn-primary btn-sm"
                      onClick={() => handleSendFriendRequest(result.id)}
                    >
                      <FiUserPlus /> Add Friend
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'create-group' && (
            <div className="create-group-section">
              <div className="form-group">
                <label>Group Name</label>
                <input
                  type="text"
                  placeholder="Enter group name..."
                  value={groupName}
                  onChange={(e) => setGroupName(e.target.value)}
                  className="input"
                />
              </div>

              <div className="form-group">
                <label>Select Members (minimum 2)</label>
                <div className="group-members-list">
                  {friends.map(friend => (
                    <div
                      key={friend.id}
                      className={`selectable-friend ${selectedForGroup.includes(friend.id) ? 'selected' : ''}`}
                      onClick={() => handleToggleGroupMember(friend.id)}
                    >
                      <div className="friend-avatar-wrapper">
                        {friend.avatarUrl ? (
                          <img src={friend.avatarUrl} alt={friend.displayName} className="avatar avatar-sm" />
                        ) : (
                          <div className="avatar avatar-sm avatar-placeholder">
                            {friend.displayName[0]?.toUpperCase()}
                          </div>
                        )}
                      </div>
                      <div className="friend-info">
                        <h4>{friend.displayName}</h4>
                      </div>
                      {selectedForGroup.includes(friend.id) && (
                        <FiCheck className="check-icon" />
                      )}
                    </div>
                  ))}
                </div>
              </div>

              <button
                className="btn btn-primary btn-block"
                onClick={handleCreateGroup}
                disabled={selectedForGroup.length < 2 || !groupName.trim()}
              >
                <FiUsers /> Create Group ({selectedForGroup.length} members)
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default FriendsPanel;
