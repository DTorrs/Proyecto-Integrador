// src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { query } = require('../database/connection');
require('dotenv').config();

// Middleware to authenticate user JWT token
const authenticateToken = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN format

    if (!token) {
      return res.status(401).json({ success: false, message: 'Access denied. No token provided.' });
    }

    // Verify the token
    jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
      if (err) {
        return res.status(403).json({ success: false, message: 'Invalid or expired token.' });
      }

      // Check if user exists in database
      const sql = 'SELECT id, username, email, role_id FROM users WHERE id = ?';
      const users = await query(sql, [decoded.userId]);

      if (users.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found.' });
      }

      // Add user info to request object
      req.user = users[0];
      next();
    });
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// Check if user has admin role
const isAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Not authenticated.' });
    }

    // Check if user has admin role (role_id 3 is admin as per our database schema)
    if (req.user.role_id !== 3) {
      return res.status(403).json({ success: false, message: 'Access denied. Admin privileges required.' });
    }

    next();
  } catch (error) {
    console.error('Admin check error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// Check if user has staff role or is an admin
const isStaffOrAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Not authenticated.' });
    }

    // Check if user has staff role (role_id 2) or admin role (role_id 3)
    if (req.user.role_id !== 2 && req.user.role_id !== 3) {
      return res.status(403).json({ success: false, message: 'Access denied. Staff or admin privileges required.' });
    }

    next();
  } catch (error) {
    console.error('Staff/Admin check error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = {
  authenticateToken,
  isAdmin,
  isStaffOrAdmin
};