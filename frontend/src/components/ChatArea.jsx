import React, { useState, useEffect, useRef } from 'react';
import { FiSend, FiPaperclip, FiMoreVertical, FiArrowLeft, FiEdit2, FiTrash2, FiSmile } from 'react-icons/fi';
import { useAuth } from '../contexts/AuthContext';
import { useSocket } from '../contexts/SocketContext';
import { format, formatDistanceToNow } from 'date-fns';
import axios from 'axios';
import { toast } from 'react-toastify';
import './ChatArea.css';

const ChatArea = ({ conversation, onBack }) => {
  const { user } = useAuth();
  const { socket, joinConversation, leaveConversation, startTyping, stopTyping, markMessagesAsSeen } = useSocket();
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [typingUsers, setTypingUsers] = useState(new Set());
  const [editingMessage, setEditingMessage] = useState(null);
  const messagesEndRef = useRef(null);
  const messageListRef = useRef(null);
  const typingTimeoutRef = useRef(null);

  useEffect(() => {
    if (conversation) {
      joinConversation(conversation._id);
      loadMessages();
      
      return () => {
        leaveConversation(conversation._id);
      };
    }
  }, [conversation]);

  useEffect(() => {
    if (!socket) return;

    socket.on('message:new', ({ message, conversation: conv }) => {
      if (conv.id === conversation._id) {
        setMessages(prev => [...prev, message]);
        scrollToBottom();
        
        // Mark as seen if message is not from current user
        if (message.senderId._id !== user.id) {
          markMessagesAsSeen(conversation._id, [message._id]);
        }
      }
    });

    socket.on('typing:start', ({ conversationId, userId, displayName }) => {
      if (conversationId === conversation._id && userId !== user.id) {
        setTypingUsers(prev => new Set([...prev, displayName]));
      }
    });

    socket.on('typing:stop', ({ conversationId, userId }) => {
      if (conversationId === conversation._id) {
        setTypingUsers(prev => {
          const updated = new Set(prev);
          // Remove by userId (we'll need to track userId -> displayName mapping)
          return updated;
        });
      }
    });

    socket.on('message:seen', ({ conversationId, userId, messageIds }) => {
      if (conversationId === conversation._id) {
        setMessages(prev => prev.map(msg => {
          if (!messageIds || messageIds.includes(msg._id)) {
            const seenBy = msg.seenBy || [];
            if (!seenBy.find(s => s.user._id === userId)) {
              return {
                ...msg,
                seenBy: [...seenBy, { user: { _id: userId }, seenAt: new Date() }]
              };
            }
          }
          return msg;
        }));
      }
    });

    socket.on('message:reaction', ({ messageId, userId, emoji, reactions }) => {
      setMessages(prev => prev.map(msg =>
        msg._id === messageId ? { ...msg, reactions } : msg
      ));
    });

    socket.on('message:edited', ({ messageId, content, isEdited }) => {
      setMessages(prev => prev.map(msg =>
        msg._id === messageId ? { ...msg, content, isEdited } : msg
      ));
    });

    socket.on('message:deleted', ({ messageId }) => {
      setMessages(prev => prev.map(msg =>
        msg._id === messageId ? { ...msg, isDeleted: true, content: 'This message has been deleted' } : msg
      ));
    });

    return () => {
      socket.off('message:new');
      socket.off('typing:start');
      socket.off('typing:stop');
      socket.off('message:seen');
      socket.off('message:reaction');
      socket.off('message:edited');
      socket.off('message:deleted');
    };
  }, [socket, conversation, user]);

  const loadMessages = async () => {
    try {
      const response = await axios.get(`/api/conversations/${conversation._id}/messages?page=${page}&limit=50`);
      setMessages(response.data.messages);
      setHasMore(response.data.pagination.page < response.data.pagination.pages);
      
      // Mark messages as seen
      setTimeout(() => {
        markMessagesAsSeen(conversation._id);
      }, 500);
      
      scrollToBottom();
    } catch (error) {
      console.error('Load messages error:', error);
      toast.error('Failed to load messages');
    } finally {
      setLoading(false);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleTyping = () => {
    startTyping(conversation._id);
    
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }
    
    typingTimeoutRef.current = setTimeout(() => {
      stopTyping(conversation._id);
    }, 2000);
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    
    if (!newMessage.trim() && !editingMessage) return;

    if (editingMessage) {
      // Edit message
      try {
        await axios.put(`/api/messages/${editingMessage._id}`, {
          content: newMessage.trim()
        });
        setEditingMessage(null);
        setNewMessage('');
      } catch (error) {
        console.error('Edit message error:', error);
        toast.error('Failed to edit message');
      }
      return;
    }

    setSending(true);
    try {
      await axios.post(`/api/conversations/${conversation._id}/messages`, {
        content: newMessage.trim()
      });
      setNewMessage('');
      stopTyping(conversation._id);
    } catch (error) {
      console.error('Send message error:', error);
      toast.error('Failed to send message');
    } finally {
      setSending(false);
    }
  };

  const handleDeleteMessage = async (messageId) => {
    if (!window.confirm('Delete this message?')) return;

    try {
      await axios.delete(`/api/messages/${messageId}`);
    } catch (error) {
      console.error('Delete message error:', error);
      toast.error('Failed to delete message');
    }
  };

  const handleReaction = async (messageId, emoji) => {
    try {
      await axios.post(`/api/messages/${messageId}/reactions`, { emoji });
    } catch (error) {
      console.error('Add reaction error:', error);
      toast.error('Failed to add reaction');
    }
  };

  const getConversationName = () => {
    if (conversation.isGroup) {
      return conversation.groupName;
    }
    const otherUser = conversation.participants.find(p => p.id !== user.id);
    return otherUser?.displayName || 'Unknown';
  };

  const isMyMessage = (msg) => {
    return msg.senderId._id === user.id || msg.senderId === user.id;
  };

  return (
    <div className="chat-area">
      <div className="chat-header">
        <button className="icon-btn mobile-back" onClick={onBack}>
          <FiArrowLeft />
        </button>
        <div className="chat-header-info">
          <h3>{getConversationName()}</h3>
          {!conversation.isGroup && (
            <p>{conversation.participants.find(p => p.id !== user.id)?.isOnline ? 'Online' : 'Offline'}</p>
          )}
        </div>
        <button className="icon-btn">
          <FiMoreVertical />
        </button>
      </div>

      <div className="messages-container" ref={messageListRef}>
        {loading ? (
          <div className="messages-loading">
            <div className="spinner"></div>
          </div>
        ) : messages.length === 0 ? (
          <div className="no-messages">
            <p>No messages yet. Start the conversation!</p>
          </div>
        ) : (
          <div className="messages-list">
            {messages.map((msg, index) => {
              const showDate = index === 0 || 
                format(new Date(messages[index - 1].createdAt), 'yyyy-MM-dd') !== 
                format(new Date(msg.createdAt), 'yyyy-MM-dd');

              return (
                <React.Fragment key={msg._id}>
                  {showDate && (
                    <div className="date-divider">
                      <span>{format(new Date(msg.createdAt), 'MMMM d, yyyy')}</span>
                    </div>
                  )}
                  
                  <div className={`message ${isMyMessage(msg) ? 'my-message' : 'other-message'}`}>
                    {!isMyMessage(msg) && conversation.isGroup && (
                      <div className="message-sender">{msg.senderId.displayName}</div>
                    )}
                    
                    <div className="message-content">
                      <p>{msg.content}</p>
                      {msg.isEdited && <span className="edited-label">(edited)</span>}
                      
                      {msg.reactions && msg.reactions.length > 0 && (
                        <div className="message-reactions">
                          {msg.reactions.map((reaction, i) => (
                            <span key={i} className="reaction">
                              {reaction.emoji}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                    
                    <div className="message-footer">
                      <span className="message-time">
                        {format(new Date(msg.createdAt), 'h:mm a')}
                      </span>
                      
                      {isMyMessage(msg) && !msg.isDeleted && (
                        <div className="message-actions">
                          <button
                            className="message-action-btn"
                            onClick={() => handleReaction(msg._id, '❤️')}
                            title="React with heart"
                          >
                            <FiSmile />
                          </button>
                          <button
                            className="message-action-btn"
                            onClick={() => {
                              setEditingMessage(msg);
                              setNewMessage(msg.content);
                            }}
                            title="Edit"
                          >
                            <FiEdit2 />
                          </button>
                          <button
                            className="message-action-btn"
                            onClick={() => handleDeleteMessage(msg._id)}
                            title="Delete"
                          >
                            <FiTrash2 />
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </React.Fragment>
              );
            })}
            <div ref={messagesEndRef} />
          </div>
        )}

        {typingUsers.size > 0 && (
          <div className="typing-indicator">
            <span>{Array.from(typingUsers).join(', ')} {typingUsers.size === 1 ? 'is' : 'are'} typing...</span>
          </div>
        )}
      </div>

      <form className="message-input-container" onSubmit={handleSendMessage}>
        {editingMessage && (
          <div className="editing-banner">
            <span>Editing message</span>
            <button
              type="button"
              onClick={() => {
                setEditingMessage(null);
                setNewMessage('');
              }}
            >
              Cancel
            </button>
          </div>
        )}
        
        <div className="message-input-wrapper">
          <button type="button" className="icon-btn" title="Attach file">
            <FiPaperclip />
          </button>
          
          <input
            type="text"
            placeholder="Type a message..."
            value={newMessage}
            onChange={(e) => {
              setNewMessage(e.target.value);
              handleTyping();
            }}
            className="message-input"
          />
          
          <button
            type="submit"
            className="btn btn-primary send-btn"
            disabled={sending || (!newMessage.trim() && !editingMessage)}
          >
            {sending ? <div className="spinner spinner-sm"></div> : <FiSend />}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ChatArea;
