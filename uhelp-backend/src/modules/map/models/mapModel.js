// src/modules/map/models/mapModel.js
const { query } = require('../../../database/connection');

class MapModel {
  /**
   * Get all locations
   * @returns {Promise<Array>} Array of locations
   */
  async getLocations() {
    try {
      return await query('SELECT * FROM locations ORDER BY code');
    } catch (error) {
      console.error('Error getting locations:', error);
      throw error;
    }
  }

  /**
   * Get a location by ID
   * @param {number} locationId - Location ID
   * @returns {Promise<object|null>} Location or null if not found
   */
  async getLocationById(locationId) {
    try {
      const sql = 'SELECT * FROM locations WHERE id = ?';
      const results = await query(sql, [locationId]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error getting location by ID:', error);
      throw error;
    }
  }

  /**
   * Get problems by location
   * @param {number} locationId - Location ID
   * @returns {Promise<Array>} Array of problems at the location
   */
  async getProblemsByLocation(locationId) {
    try {
      const sql = `
        SELECT pr.id, pr.title, pr.status_id, s.name as status_name,
               pr.created_at, pr.image_url, u.username,
               (SELECT COUNT(*) FROM report_votes WHERE report_id = pr.id) as vote_count
        FROM problem_reports pr
        JOIN users u ON pr.user_id = u.id
        JOIN statuses s ON pr.status_id = s.id
        WHERE pr.location_id = ?
        ORDER BY pr.created_at DESC
      `;
      
      return await query(sql, [locationId]);
    } catch (error) {
      console.error('Error getting problems by location:', error);
      throw error;
    }
  }

  /**
   * Get lost items by location
   * @param {number} locationId - Location ID
   * @returns {Promise<Array>} Array of lost items at the location
   */
  async getLostItemsByLocation(locationId) {
    try {
      const sql = `
        SELECT li.id, li.title, li.is_found, li.status_id, 
               lis.name as status_name, li.created_at, 
               li.image_url, u.username
        FROM lost_items li
        JOIN users u ON li.user_id = u.id
        JOIN lost_item_statuses lis ON li.status_id = lis.id
        WHERE li.location_id = ?
        ORDER BY li.created_at DESC
      `;
      
      return await query(sql, [locationId]);
    } catch (error) {
      console.error('Error getting lost items by location:', error);
      throw error;
    }
  }

  /**
   * Get map overview data (counts for each location)
   * @returns {Promise<Array>} Array of location data with counts
   */
  async getMapOverview() {
    try {
      const sql = `
        SELECT 
          l.id, 
          l.code, 
          l.name,
          (
            SELECT COUNT(*) 
            FROM problem_reports 
            WHERE location_id = l.id AND status_id <> 3
          ) as active_problems,
          (
            SELECT COUNT(*) 
            FROM lost_items 
            WHERE location_id = l.id AND status_id <> 3 AND status_id <> 4
          ) as active_items
        FROM 
          locations l
        WHERE 
          l.code <> 'OTHER'
        ORDER BY 
          l.code
      `;
      
      return await query(sql);
    } catch (error) {
      console.error('Error getting map overview:', error);
      throw error;
    }
  }

  /**
   * Check if a similar problem already exists at a location
   * @param {number} locationId - Location ID
   * @param {string} title - Problem title
   * @param {string} description - Problem description
   * @returns {Promise<Array>} Array of similar problems
   */
  async checkSimilarProblems(locationId, title, description) {
    try {
      // We'll use fulltext search if available, otherwise pattern matching
      const sql = `
        SELECT pr.id, pr.title, pr.description, pr.status_id, 
               s.name as status_name, pr.created_at, 
               u.username, l.name as location_name
        FROM problem_reports pr
        JOIN users u ON pr.user_id = u.id
        JOIN locations l ON pr.location_id = l.id
        JOIN statuses s ON pr.status_id = s.id
        WHERE pr.location_id = ?
          AND (
            pr.title LIKE ? 
            OR pr.description LIKE ?
          )
          AND pr.status_id <> 3
        ORDER BY pr.created_at DESC
        LIMIT 5
      `;
      
      const searchTerms = [
        `%${title}%`,
        `%${description}%`
      ];
      
      return await query(sql, [locationId, ...searchTerms]);
    } catch (error) {
      console.error('Error checking similar problems:', error);
      throw error;
    }
  }
}

module.exports = new MapModel();