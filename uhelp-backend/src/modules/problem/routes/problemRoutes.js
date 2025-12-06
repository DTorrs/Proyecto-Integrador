// src/modules/problem/routes/problemRoutes.js
const express = require('express');
const { body } = require('express-validator');
const problemController = require('../controllers/problemController');
const { authenticateToken, isStaffOrAdmin } = require('../../../middleware/auth');
const { problemsUpload } = require('../../../middleware/upload');

const router = express.Router();

// Get all problems (with optional filters)
router.get('/', problemController.getProblems);

// Get problem by ID
router.get('/:id', problemController.getProblem);

// Create a new problem
router.post(
  '/',
  authenticateToken,
  problemsUpload('image'),
  [
    body('title')
      .notEmpty()
      .withMessage('Title is required')
      .isLength({ min: 5, max: 255 })
      .withMessage('Title must be between 5 and 255 characters'),
    
    body('description')
      .notEmpty()
      .withMessage('Description is required')
      .isLength({ min: 10 })
      .withMessage('Description must be at least 10 characters'),
    
    body('locationId')
      .notEmpty()
      .withMessage('Location is required')
      .isInt()
      .withMessage('Location ID must be an integer'),
    
    body('specificLocation')
      .notEmpty()
      .withMessage('Specific location is required')
      .isLength({ min: 3, max: 255 })
      .withMessage('Specific location must be between 3 and 255 characters'),
    
    body('categoryId')
      .notEmpty()
      .withMessage('Category is required')
      .isInt()
      .withMessage('Category ID must be an integer')
  ],
  problemController.createProblem
);

// Update a problem
router.put(
  '/:id',
  authenticateToken,
  problemsUpload('image'),
  [
    body('title')
      .optional()
      .isLength({ min: 5, max: 255 })
      .withMessage('Title must be between 5 and 255 characters'),
    
    body('description')
      .optional()
      .isLength({ min: 10 })
      .withMessage('Description must be at least 10 characters'),
    
    body('locationId')
      .optional()
      .isInt()
      .withMessage('Location ID must be an integer'),
    
    body('specificLocation')
      .optional()
      .isLength({ min: 3, max: 255 })
      .withMessage('Specific location must be between 3 and 255 characters'),
    
    body('categoryId')
      .optional()
      .isInt()
      .withMessage('Category ID must be an integer')
  ],
  problemController.updateProblem
);

// Delete a problem
router.delete('/:id', authenticateToken, problemController.deleteProblem);

// Update problem status (staff/admin only)
router.put(
  '/:id/status',
  authenticateToken,
  isStaffOrAdmin,
  [
    body('statusId')
      .notEmpty()
      .withMessage('Status ID is required')
      .isInt({ min: 1, max: 3 })
      .withMessage('Status ID must be a valid status (1-3)')
  ],
  problemController.updateStatus
);

// Vote on a problem
router.post('/:id/vote', authenticateToken, problemController.voteProblem);

// Add a comment to a problem
router.post(
  '/:id/comments',
  authenticateToken,
  [
    body('comment')
      .notEmpty()
      .withMessage('Comment is required')
      .isLength({ min: 2, max: 1000 })
      .withMessage('Comment must be between 2 and 1000 characters')
  ],
  problemController.addComment
);

// Delete a comment
router.delete('/:id/comments/:commentId', authenticateToken, problemController.deleteComment);

// Get all categories
router.get('/categories/all', problemController.getCategories);

// Get all statuses
router.get('/statuses/all', problemController.getStatuses);

module.exports = router;