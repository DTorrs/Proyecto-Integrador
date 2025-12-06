// src/modules/auth/controllers/authController.js
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const authModel = require('../models/authModel');
const { createResponse } = require('../../../utils/helpers');
require('dotenv').config();

class AuthController {
  /**
   * Register a new user
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async register(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }

      const { username, email, password, fullName } = req.body;

      // Check if email already exists
      const existingEmail = await authModel.findUserByEmail(email);
      if (existingEmail) {
        return res.status(400).json(createResponse(false, 'Email already in use'));
      }

      // Check if username already exists
      const existingUsername = await authModel.findUserByUsername(username);
      if (existingUsername) {
        return res.status(400).json(createResponse(false, 'Username already in use'));
      }

      // Create new user (default role is student)
      const newUser = await authModel.createUser({
        username,
        email,
        password,
        fullName,
        roleId: 1 // 1 = student
      });

      // Generate JWT token
      const token = jwt.sign(
        { userId: newUser.id },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN }
      );

      res.status(201).json(createResponse(true, 'User registered successfully', {
        user: newUser,
        token
      }));
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }

  /**
   * Login a user
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async login(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }

      const { email, password } = req.body;

      // Validate credentials
      const user = await authModel.validateCredentials(email, password);
      if (!user) {
        return res.status(401).json(createResponse(false, 'Invalid credentials'));
      }

      // Get user role
      const userWithRole = await authModel.getUserById(user.id);

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN }
      );

      res.status(200).json(createResponse(true, 'Login successful', {
        user: userWithRole,
        token
      }));
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }

  /**
   * Get the currently authenticated user
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getMe(req, res) {
    try {
      const userId = req.user.id;
      
      // Get user profile
      const user = await authModel.getUserById(userId);
      if (!user) {
        return res.status(404).json(createResponse(false, 'User not found'));
      }

      res.status(200).json(createResponse(true, 'User profile retrieved', { user }));
    } catch (error) {
      console.error('Get me error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new AuthController();