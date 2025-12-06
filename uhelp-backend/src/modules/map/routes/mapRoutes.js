// src/modules/map/routes/mapRoutes.js
const express = require('express');
const { body } = require('express-validator');
const mapController = require('../controllers/mapController');
const { authenticateToken } = require('../../../middleware/auth');

const router = express.Router();

// Get all locations
router.get('/locations', mapController.getLocations);

// Get a location by ID
router.get('/locations/:id', mapController.getLocation);

// Get problems by location
router.get('/locations/:id/problems', mapController.getProblemsByLocation);

// Get lost items by location
router.get('/locations/:id/lost-items', mapController.getLostItemsByLocation);

// Get map overview data
router.get('/overview', mapController.getMapOverview);

// Check if similar problems exist at a location
router.post(
  '/check-similar-problems',
  authenticateToken,
  [
    body('locationId')
      .notEmpty()
      .withMessage('Location ID is required')
      .isInt()
      .withMessage('Location ID must be an integer'),
    
    body('title')
      .notEmpty()
      .withMessage('Title is required'),
    
    body('description')
      .notEmpty()
      .withMessage('Description is required')
  ],
  mapController.checkSimilarProblems
);

module.exports = router;