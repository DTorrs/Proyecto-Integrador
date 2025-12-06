// src/modules/map/controllers/mapController.js
const { validationResult } = require('express-validator');
const mapModel = require('../models/mapModel');
const { createResponse } = require('../../../utils/helpers');

class MapController {
  /**
   * Get all locations
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLocations(req, res) {
    try {
      const locations = await mapModel.getLocations();
      
      res.status(200).json(createResponse(true, 'Locations retrieved', { locations }));
    } catch (error) {
      console.error('Get locations error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get a location by ID
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLocation(req, res) {
    try {
      const locationId = req.params.id;
      
      // Get the location
      const location = await mapModel.getLocationById(locationId);
      
      if (!location) {
        return res.status(404).json(createResponse(false, 'Location not found'));
      }
      
      res.status(200).json(createResponse(true, 'Location retrieved', { location }));
    } catch (error) {
      console.error('Get location error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get problems by location
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getProblemsByLocation(req, res) {
    try {
      const locationId = req.params.id;
      
      // Verify location exists
      const location = await mapModel.getLocationById(locationId);
      
      if (!location) {
        return res.status(404).json(createResponse(false, 'Location not found'));
      }
      
      // Get problems at this location
      const problems = await mapModel.getProblemsByLocation(locationId);
      
      res.status(200).json(createResponse(true, 'Problems retrieved', { 
        location,
        problems 
      }));
    } catch (error) {
      console.error('Get problems by location error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get lost items by location
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLostItemsByLocation(req, res) {
    try {
      const locationId = req.params.id;
      
      // Verify location exists
      const location = await mapModel.getLocationById(locationId);
      
      if (!location) {
        return res.status(404).json(createResponse(false, 'Location not found'));
      }
      
      // Get lost items at this location
      const lostItems = await mapModel.getLostItemsByLocation(locationId);
      
      res.status(200).json(createResponse(true, 'Lost items retrieved', { 
        location,
        lostItems 
      }));
    } catch (error) {
      console.error('Get lost items by location error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get map overview data
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getMapOverview(req, res) {
    try {
      const mapData = await mapModel.getMapOverview();
      
      res.status(200).json(createResponse(true, 'Map overview retrieved', { mapData }));
    } catch (error) {
      console.error('Get map overview error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Check if similar problems exist at a location
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async checkSimilarProblems(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const { locationId, title, description } = req.body;
      
      // Check for similar problems
      const similarProblems = await mapModel.checkSimilarProblems(locationId, title, description);
      
      res.status(200).json(createResponse(true, 'Similar problems checked', { 
        hasSimilarProblems: similarProblems.length > 0,
        similarProblems 
      }));
    } catch (error) {
      console.error('Check similar problems error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new MapController();