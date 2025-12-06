// src/modules/problem/controllers/problemController.js
const { validationResult } = require('express-validator');
const problemModel = require('../models/problemModel');
const notificationModel = require('../../notification/models/notificationModel');
const { createResponse, deleteFile, getPaginationParams, paginateResults } = require('../../../utils/helpers');

class ProblemController {
  /**
   * Create a new problem report
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async createProblem(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }

      const { title, description, locationId, specificLocation, categoryId } = req.body;
      const userId = req.user.id;
      
      // Prepare problem data
      const problemData = {
        title,
        description,
        userId,
        locationId,
        specificLocation,
        categoryId,
        imageUrl: req.file ? req.file.filename : null
      };
      
      // Create the problem
      const problem = await problemModel.createProblem(problemData);
      
      res.status(201).json(createResponse(true, 'Problem report created successfully', { problem }));
    } catch (error) {
      console.error('Create problem error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`problems/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get a problem by ID
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getProblem(req, res) {
    try {
      const problemId = req.params.id;
      
      // Get the problem
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Check if user has voted (if authenticated)
      if (req.user) {
        problem.userVoted = await problemModel.hasUserVoted(problemId, req.user.id);
      }
      
      res.status(200).json(createResponse(true, 'Problem report retrieved', { problem }));
    } catch (error) {
      console.error('Get problem error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all problems with filtering and pagination
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getProblems(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter parameters
      const filters = {
        categoryId: req.query.categoryId,
        statusId: req.query.statusId,
        locationId: req.query.locationId,
        userId: req.query.userId,
        sortBy: req.query.sortBy
      };
      
      // Get problems
      const problems = await problemModel.getProblems(filters);
      
      // Add user voted status if user is authenticated
      if (req.user) {
        for (const problem of problems) {
          problem.userVoted = await problemModel.hasUserVoted(problem.id, req.user.id);
        }
      }
      
      // Paginate results
      const paginatedProblems = paginateResults(problems, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Problems retrieved', paginatedProblems));
    } catch (error) {
      console.error('Get problems error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update a problem
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateProblem(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const problemId = req.params.id;
      const userId = req.user.id;
      
      // Check if problem exists
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Check if user is authorized to update this problem
      if (problem.user_id !== userId && req.user.role_id !== 3) { // Not owner and not admin
        return res.status(403).json(createResponse(false, 'Not authorized to update this problem'));
      }
      
      // Extract update data
      const { title, description, locationId, specificLocation, categoryId } = req.body;
      
      const updateData = {
        title,
        description,
        locationId,
        specificLocation,
        categoryId
      };
      
      // Handle image update
      if (req.file) {
        updateData.imageUrl = req.file.filename;
        
        // Delete old image if exists
        if (problem.image_url) {
          await deleteFile(`problems/${problem.image_url}`);
        }
      }
      
      // Update the problem
      const updatedProblem = await problemModel.updateProblem(problemId, updateData);
      
      res.status(200).json(createResponse(true, 'Problem report updated successfully', { problem: updatedProblem }));
    } catch (error) {
      console.error('Update problem error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`problems/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Delete a problem
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async deleteProblem(req, res) {
    try {
      const problemId = req.params.id;
      const userId = req.user.id;
      
      // Check if problem exists
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Check if user is authorized to delete this problem
      if (problem.user_id !== userId && req.user.role_id !== 3) { // Not owner and not admin
        return res.status(403).json(createResponse(false, 'No autorizado para eliminar este problema'));
      }
      
      // Delete the problem
      await problemModel.deleteProblem(problemId);
      
      // Delete image if exists
      if (problem.image_url) {
        await deleteFile(`problems/${problem.image_url}`);
      }
      
      res.status(200).json(createResponse(true, 'Problem report deleted successfully'));
    } catch (error) {
      console.error('Delete problem error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update problem status
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateStatus(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const problemId = req.params.id;
      const { statusId } = req.body;
      
      // Check if problem exists
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Update the status
      const updatedProblem = await problemModel.updateStatus(problemId, statusId);
      
      // Create notification for problem owner
      const statusNames = {
        1: 'Pendiente',
        2: 'En Progreso',
        3: 'Resuelto'
      };
      
      await notificationModel.createNotification({
        userId: problem.user_id,
        title: 'Estado problema actualizado',
        message: `Tu reporte de problema "${problem.title}" ha sido actualizado a ${statusNames[statusId]}.`,
        relatedType: 'problem',
        relatedId: problemId
      });
      
      // Send real-time notification if socket is available
      const io = req.app.get('io');
      if (io) {
        io.to(`user-${problem.user_id}`).emit('notification', {
          type: 'problem_status',
          message: `Tu reporte "${problem.title}" ha sido actualizado a ${statusNames[statusId]}.`,
          problemId
        });
      }
      
      res.status(200).json(createResponse(true, 'Problem status updated successfully', { problem: updatedProblem }));
    } catch (error) {
      console.error('Update status error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Vote on a problem
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async voteProblem(req, res) {
    try {
      const problemId = req.params.id;
      const userId = req.user.id;
      
      // Check if problem exists
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Toggle vote
      const voteResult = await problemModel.addVote(problemId, userId);
      
      res.status(200).json(createResponse(true, 
        voteResult.userVoted ? 'Vote added' : 'Vote removed', 
        { voteCount: voteResult.voteCount, userVoted: voteResult.userVoted }
      ));
    } catch (error) {
      console.error('Vote problem error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Add a comment to a problem
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async addComment(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const problemId = req.params.id;
      const userId = req.user.id;
      const { comment } = req.body;
      
      // Check if problem exists
      const problem = await problemModel.getProblemById(problemId);
      
      if (!problem) {
        return res.status(404).json(createResponse(false, 'Problem report not found'));
      }
      
      // Add the comment
      const newComment = await problemModel.addComment(problemId, userId, comment);
      
      // Create notification for problem owner (if comment is not by the owner)
      if (problem.user_id !== userId) {
        await notificationModel.createNotification({
          userId: problem.user_id,
          title: 'New Comment',
          message: `Someone commented on your problem report "${problem.title}".`,
          relatedType: 'problem',
          relatedId: problemId
        });
        
        // Send real-time notification if socket is available
        const io = req.app.get('io');
        if (io) {
          io.to(`user-${problem.user_id}`).emit('notification', {
            type: 'new_comment',
            message: `Someone commented on your problem report "${problem.title}".`,
            problemId
          });
        }
      }
      
      res.status(201).json(createResponse(true, 'Comment added successfully', { comment: newComment }));
    } catch (error) {
      console.error('Add comment error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Delete a comment
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async deleteComment(req, res) {
    try {
      const commentId = req.params.commentId;
      const userId = req.user.id;
      
      // Delete the comment
      const result = await problemModel.deleteComment(commentId, userId);
      
      if (!result) {
        return res.status(404).json(createResponse(false, 'Comment not found or not authorized'));
      }
      
      res.status(200).json(createResponse(true, 'Comment deleted successfully'));
    } catch (error) {
      console.error('Delete comment error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all categories
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getCategories(req, res) {
    try {
      const categories = await problemModel.getCategories();
      
      res.status(200).json(createResponse(true, 'Categories retrieved', { categories }));
    } catch (error) {
      console.error('Get categories error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all statuses
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getStatuses(req, res) {
    try {
      const statuses = await problemModel.getStatuses();
      
      res.status(200).json(createResponse(true, 'Statuses retrieved', { statuses }));
    } catch (error) {
      console.error('Get statuses error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new ProblemController();