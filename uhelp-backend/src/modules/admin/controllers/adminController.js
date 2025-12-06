// src/modules/admin/controllers/adminController.js
const { validationResult } = require('express-validator');
const adminModel = require('../models/adminModel');
const { createResponse, getPaginationParams, paginateResults } = require('../../../utils/helpers');

class AdminController {
  /**
   * Get admin dashboard statistics
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getDashboardStats(req, res) {
    try {
      const stats = await adminModel.getDashboardStats();
      
      res.status(200).json(createResponse(true, 'Dashboard statistics retrieved', { stats }));
    } catch (error) {
      console.error('Get dashboard stats error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all users with search and pagination
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getUsers(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract search parameters
      const options = {
        search: req.query.search,
        roleId: req.query.roleId
      };
      
      // Get users
      const users = await adminModel.getUsers(options);
      
      // Paginate results
      const paginatedUsers = paginateResults(users, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Users retrieved', paginatedUsers));
    } catch (error) {
      console.error('Get users error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get problem reports for admin management
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getProblems(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter options
      const options = {
        statusId: req.query.statusId,
        categoryId: req.query.categoryId,
        locationId: req.query.locationId,
        search: req.query.search,
        sortBy: req.query.sortBy
      };
      
      // Get problems
      const problems = await adminModel.getProblems(options);
      
      // Paginate results
      const paginatedProblems = paginateResults(problems, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Problems retrieved', paginatedProblems));
    } catch (error) {
      console.error('Get problems error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get lost items for admin management
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLostItems(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter options
      const options = {
        statusId: req.query.statusId,
        isFound: req.query.isFound === 'true',
        locationId: req.query.locationId,
        search: req.query.search
      };
      
      // If isFound parameter is not provided, remove it from options
      if (req.query.isFound === undefined) {
        delete options.isFound;
      }
      
      // Get lost items
      const lostItems = await adminModel.getLostItems(options);
      
      // Paginate results
      const paginatedItems = paginateResults(lostItems, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Lost items retrieved', paginatedItems));
    } catch (error) {
      console.error('Get lost items error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Log an admin activity
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async logActivity(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const { action, entityType, entityId, details } = req.body;
      const userId = req.user.id;
      
      // Create activity log
      const activity = await adminModel.logActivity({
        userId,
        action,
        entityType,
        entityId,
        details
      });
      
      res.status(201).json(createResponse(true, 'Activity logged successfully', { activity }));
    } catch (error) {
      console.error('Log activity error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update a user's role
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateUserRole(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const userId = req.params.id;
      const { roleId } = req.body;
      const adminId = req.user.id;
      
      // Don't allow changing own role
      if (parseInt(userId) === adminId) {
        return res.status(400).json(createResponse(false, 'Cannot change your own role'));
      }
      
      // Update user role
      const success = await adminModel.updateUserRole(userId, roleId);
      
      if (!success) {
        return res.status(404).json(createResponse(false, 'User not found'));
      }
      
      // Log the activity
      await adminModel.logActivity({
        userId: adminId,
        action: 'update_user_role',
        entityType: 'user',
        entityId: userId,
        details: `Changed user role to ID ${roleId}`
      });
      
      res.status(200).json(createResponse(true, 'User role updated successfully'));
    } catch (error) {
      console.error('Update user role error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all roles
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getRoles(req, res) {
    try {
      const roles = await adminModel.getRoles();
      
      res.status(200).json(createResponse(true, 'Roles retrieved', { roles }));
    } catch (error) {
      console.error('Get roles error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get activity logs
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getActivityLogs(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter options
      const options = {
        userId: req.query.userId,
        entityType: req.query.entityType,
        startDate: req.query.startDate,
        endDate: req.query.endDate
      };
      
      // Get activity logs
      const activityLogs = await adminModel.getActivityLogs(options);
      
      // Paginate results
      const paginatedLogs = paginateResults(activityLogs, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Activity logs retrieved', paginatedLogs));
    } catch (error) {
      console.error('Get activity logs error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new AdminController();