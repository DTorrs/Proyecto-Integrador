const { query } = require('../../../database/connection');

class LostItemModel {
  /**
   * Create a new lost item entry
   * @param {object} itemData - Lost item data
   * @returns {Promise<object>} Newly created lost item
   */
  async createLostItem(itemData) {
    try {
      const sql = `
        INSERT INTO lost_items 
        (title, description, user_id, location_id, specific_location, is_found, contact_info, image_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        itemData.title,
        itemData.description,
        itemData.userId,
        itemData.locationId,
        itemData.specificLocation,
        itemData.isFound,
        itemData.contactInfo,
        itemData.imageUrl || null
      ];
      
      const result = await query(sql, params);
      
      // Return the newly created item
      return await this.getLostItemById(result.insertId);
    } catch (error) {
      console.error('Error creating lost item:', error);
      throw error;
    }
  }
  
  /**
   * Get a lost item by ID
   * @param {number} itemId - Lost item ID
   * @returns {Promise<object|null>} Lost item or null if not found
   */
  async getLostItemById(itemId) {
    try {
      const sql = `
        SELECT li.*, 
               u.username, u.full_name as reporter_name,
               l.code as location_code, l.name as location_name,
               lis.name as status_name
        FROM lost_items li
        JOIN users u ON li.user_id = u.id
        JOIN locations l ON li.location_id = l.id
        JOIN lost_item_statuses lis ON li.status_id = lis.id
        WHERE li.id = ?
      `;
      
      const results = await query(sql, [itemId]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error getting lost item by ID:', error);
      throw error;
    }
  }
  
  /**
   * Get all lost items with filtering options
   * @param {object} filters - Filter options
   * @returns {Promise<Array>} Array of lost items
   */
  async getLostItems(filters = {}) {
    try {
      let sql = `
        SELECT li.*, 
               u.username, u.full_name as reporter_name,
               l.code as location_code, l.name as location_name,
               lis.name as status_name
        FROM lost_items li
        JOIN users u ON li.user_id = u.id
        JOIN locations l ON li.location_id = l.id
        JOIN lost_item_statuses lis ON li.status_id = lis.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Apply filters
      if (filters.isFound !== undefined) {
        sql += ' AND li.is_found = ?';
        params.push(filters.isFound);
      }
      
      if (filters.statusId) {
        sql += ' AND li.status_id = ?';
        params.push(filters.statusId);
      }
      
      if (filters.locationId) {
        sql += ' AND li.location_id = ?';
        params.push(filters.locationId);
      }
      
      if (filters.userId) {
        sql += ' AND li.user_id = ?';
        params.push(filters.userId);
      }
      
      // Search by title or description
      if (filters.search) {
        sql += ' AND (li.title LIKE ? OR li.description LIKE ?)';
        params.push(`%${filters.search}%`, `%${filters.search}%`);
      }
      
      // Order by date
      sql += ' ORDER BY li.created_at DESC';
      
      // Add limit and offset if needed
      if (filters.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(filters.limit));
        
        if (filters.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(filters.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting lost items:', error);
      throw error;
    }
  }
  
  /**
   * Update a lost item
   * @param {number} itemId - Lost item ID
   * @param {object} updateData - Data to update
   * @returns {Promise<object>} Updated lost item
   */
  async updateLostItem(itemId, updateData) {
    try {
      // Build the SQL query dynamically based on provided fields
      let sql = 'UPDATE lost_items SET ';
      const params = [];
      const fields = [];
      
      if (updateData.title) {
        fields.push('title = ?');
        params.push(updateData.title);
      }
      
      if (updateData.description) {
        fields.push('description = ?');
        params.push(updateData.description);
      }
      
      if (updateData.locationId) {
        fields.push('location_id = ?');
        params.push(updateData.locationId);
      }
      
      if (updateData.specificLocation) {
        fields.push('specific_location = ?');
        params.push(updateData.specificLocation);
      }
      
      if (updateData.contactInfo) {
        fields.push('contact_info = ?');
        params.push(updateData.contactInfo);
      }
      
      if (updateData.isFound !== undefined) {
        fields.push('is_found = ?');
        params.push(updateData.isFound);
      }
      
      if (updateData.statusId) {
        fields.push('status_id = ?');
        params.push(updateData.statusId);
      }
      
      if (updateData.imageUrl) {
        fields.push('image_url = ?');
        params.push(updateData.imageUrl);
      }
      
      // If no fields to update, return current item
      if (fields.length === 0) {
        return await this.getLostItemById(itemId);
      }
      
      // Complete the SQL query
      sql += fields.join(', ');
      sql += ' WHERE id = ?';
      params.push(itemId);
      
      // Execute the update query
      await query(sql, params);
      
      // Return the updated item
      return await this.getLostItemById(itemId);
    } catch (error) {
      console.error('Error updating lost item:', error);
      throw error;
    }
  }
  
  /**
   * Delete a lost item
   * @param {number} itemId - Lost item ID
   * @returns {Promise<boolean>} Success status
   */
  async deleteLostItem(itemId) {
    try {
      const sql = 'DELETE FROM lost_items WHERE id = ?';
      const result = await query(sql, [itemId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting lost item:', error);
      throw error;
    }
  }
  
  /**
   * Update lost item status
   * @param {number} itemId - Lost item ID
   * @param {object} updateData - Update data including status and photos
   * @returns {Promise<object>} Updated lost item
   */
  async updateStatus(itemId, updateData) {
    try {
      let sql = 'UPDATE lost_items SET ';
      const params = [];
      const fields = [];
      
      // Siempre actualizamos el estado
      fields.push('status_id = ?');
      params.push(updateData.statusId);
      
      // Agregar fotos si están presentes (para claimed status)
      if (updateData.idPhotoUrl) {
        fields.push('id_photo_url = ?');
        params.push(updateData.idPhotoUrl);
      }
      
      if (updateData.claimPhotoUrl) {
        fields.push('claim_photo_url = ?');
        params.push(updateData.claimPhotoUrl);
      }
      
      sql += fields.join(', ');
      sql += ' WHERE id = ?';
      params.push(itemId);
      
      await query(sql, params);
      
      return await this.getLostItemById(itemId);
    } catch (error) {
      console.error('Error updating lost item status:', error);
      throw error;
    }
  }
  
  /**
   * Get all lost item statuses
   * @returns {Promise<Array>} Array of statuses
   */
  async getStatuses() {
    try {
      return await query('SELECT * FROM lost_item_statuses ORDER BY id');
    } catch (error) {
      console.error('Error getting lost item statuses:', error);
      throw error;
    }
  }
}

module.exports = new LostItemModel();