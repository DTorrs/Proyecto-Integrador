// src/app.js
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// Create Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the public directory
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads')));

// Import routes
const authRoutes = require('./modules/auth/routes/authRoutes');
const userRoutes = require('./modules/user/routes/userRoutes');
const problemRoutes = require('./modules/problem/routes/problemRoutes');
const lostItemRoutes = require('./modules/lostitem/routes/lostItemRoutes');
const notificationRoutes = require('./modules/notification/routes/notificationRoutes');
const announcementRoutes = require('./modules/announcement/routes/announcementRoutes');
const adminRoutes = require('./modules/admin/routes/adminRoutes');
const mapRoutes = require('./modules/map/routes/mapRoutes');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/problems', problemRoutes);
app.use('/api/lost-items', lostItemRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/map', mapRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'UHelp API is running',
    version: '1.0.0'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 middleware
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

module.exports = app;