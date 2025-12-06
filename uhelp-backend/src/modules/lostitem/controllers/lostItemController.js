const { validationResult } = require('express-validator');
const lostItemModel = require('../models/lostItemModel');
const notificationModel = require('../../notification/models/notificationModel');
const { createResponse, deleteFile, getPaginationParams, paginateResults } = require('../../../utils/helpers');

class LostItemController {
  /**
   * Create a new lost item entry
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async createLostItem(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }

      const { title, description, locationId, specificLocation, isFound, contactInfo } = req.body;
      const userId = req.user.id;
      
      // Prepare item data
      const itemData = {
        title,
        description,
        userId,
        locationId,
        specificLocation,
        isFound: isFound === 'true' || isFound === true,
        contactInfo,
        imageUrl: req.file ? req.file.filename : null
      };
      
      // Create the lost item
      const lostItem = await lostItemModel.createLostItem(itemData);
      
      res.status(201).json(createResponse(true, 'Lost item created successfully', { lostItem }));
    } catch (error) {
      console.error('Create lost item error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`lostitems/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get a lost item by ID
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLostItem(req, res) {
    try {
      const itemId = req.params.id;
      
      // Get the item
      const lostItem = await lostItemModel.getLostItemById(itemId);
      
      if (!lostItem) {
        return res.status(404).json(createResponse(false, 'Lost item not found'));
      }
      
      res.status(200).json(createResponse(true, 'Lost item retrieved', { lostItem }));
    } catch (error) {
      console.error('Get lost item error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all lost items with filtering and pagination
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getLostItems(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter parameters
      const filters = {
        isFound: req.query.isFound === 'true' || req.query.isFound === true,
        statusId: req.query.statusId,
        locationId: req.query.locationId,
        userId: req.query.userId,
        search: req.query.search
      };
      
      // If isFound parameter is not provided, remove it from filters
      if (req.query.isFound === undefined) {
        delete filters.isFound;
      }
      
      // Get lost items
      const lostItems = await lostItemModel.getLostItems(filters);
      
      // Paginate results
      const paginatedItems = paginateResults(lostItems, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Lost items retrieved', paginatedItems));
    } catch (error) {
      console.error('Get lost items error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update a lost item
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateLostItem(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const itemId = req.params.id;
      const userId = req.user.id;
      
      // Check if item exists
      const lostItem = await lostItemModel.getLostItemById(itemId);
      
      if (!lostItem) {
        return res.status(404).json(createResponse(false, 'Lost item not found'));
      }
      
      // Check if user is authorized to update this item
      if (lostItem.user_id !== userId && req.user.role_id !== 3) { // Not owner and not admin
        return res.status(403).json(createResponse(false, 'Not authorized to update this item'));
      }
      
      // Extract update data
      const { title, description, locationId, specificLocation, isFound, contactInfo } = req.body;
      
      const updateData = {
        title,
        description,
        locationId,
        specificLocation,
        contactInfo
      };
      
      // Process isFound if provided
      if (isFound !== undefined) {
        updateData.isFound = isFound === 'true' || isFound === true;
      }
      
      // Handle image update
      if (req.file) {
        updateData.imageUrl = req.file.filename;
        
        // Delete old image if exists
        if (lostItem.image_url) {
          await deleteFile(`lostitems/${lostItem.image_url}`);
        }
      }
      
      // Update the item
      const updatedItem = await lostItemModel.updateLostItem(itemId, updateData);
      
      res.status(200).json(createResponse(true, 'Lost item updated successfully', { lostItem: updatedItem }));
    } catch (error) {
      console.error('Update lost item error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`lostitems/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Delete a lost item
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async deleteLostItem(req, res) {
    try {
      const itemId = req.params.id;
      const userId = req.user.id;
      
      // Check if item exists
      const lostItem = await lostItemModel.getLostItemById(itemId);
      
      if (!lostItem) {
        return res.status(404).json(createResponse(false, 'Lost item not found'));
      }
      
      // Check if user is authorized to delete this item
      if (lostItem.user_id !== userId && req.user.role_id !== 3) { // Not owner and not admin
        return res.status(403).json(createResponse(false, 'Not authorized to delete this item'));
      }
      
      // Delete the item
      await lostItemModel.deleteLostItem(itemId);
      
      // Delete image if exists
      if (lostItem.image_url) {
        await deleteFile(`lostitems/${lostItem.image_url}`);
      }
      
      // Delete claim photos if they exist
      if (lostItem.id_photo_url) {
        await deleteFile(`lostitems/${lostItem.id_photo_url}`);
      }
      
      if (lostItem.claim_photo_url) {
        await deleteFile(`lostitems/${lostItem.claim_photo_url}`);
      }
      
      res.status(200).json(createResponse(true, 'Lost item deleted successfully'));
    } catch (error) {
      console.error('Delete lost item error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update lost item status (for staff/admin)
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateStatus(req, res) {
    try {
      console.log("==== CONTROLADOR: UPDATE STATUS ====");
      
      // Usar el statusId ya procesado en el middleware
      const statusId = req.statusId;
      console.log(`statusId: ${statusId}`);
      
      const itemId = req.params.id;
      console.log(`itemId: ${itemId}`);
      
      // Check if item exists
      const lostItem = await lostItemModel.getLostItemById(itemId);
      
      if (!lostItem) {
        return res.status(404).json(createResponse(false, 'Lost item not found'));
      }
      
      // Preparar objeto para actualización
      const updateData = {
        statusId: statusId
      };
      
      // Si el estado es "claimed" (3), procesar fotos
      if (statusId === 3) {
        console.log("Procesando fotos para reclamo:");
        
        if (req.files) {
          console.log("Files presentes:", Object.keys(req.files));
          
          if (req.files.idPhoto && req.files.idPhoto.length > 0) {
            updateData.idPhotoUrl = req.files.idPhoto[0].filename;
            console.log(`Foto ID: ${updateData.idPhotoUrl}`);
          }
          
          if (req.files.claimPhoto && req.files.claimPhoto.length > 0) {
            updateData.claimPhotoUrl = req.files.claimPhoto[0].filename;
            console.log(`Foto entrega: ${updateData.claimPhotoUrl}`);
          }
          
          // Borrar fotos antiguas si existen
          if (lostItem.id_photo_url) {
            await deleteFile(`lostitems/${lostItem.id_photo_url}`);
          }
          
          if (lostItem.claim_photo_url) {
            await deleteFile(`lostitems/${lostItem.claim_photo_url}`);
          }
        }
      }
      
      console.log("Datos de actualización:", updateData);
      
      // Update the status
      const updatedItem = await lostItemModel.updateStatus(itemId, updateData);
      
      // Create notification for item owner
      const statusNames = {
        1: 'reported',
        2: 'in D300 room',
        3: 'claimed',
        4: 'archived'
      };
      
      await notificationModel.createNotification({
        userId: lostItem.user_id,
        title: 'Estado Objeto Actualizado',
        message: `Tu ${lostItem.is_found ? 'encontrado' : 'perdido'}"${lostItem.title}" ha sido actualizado a ${statusNames[statusId]}.`,
        relatedType: 'lost_item',
        relatedId: itemId
      });
      
      // Send real-time notification if socket is available
      const io = req.app.get('io');
      if (io) {
        io.to(`user-${lostItem.user_id}`).emit('notification', {
          type: 'lost_item_status',
          message: `Tu ${lostItem.is_found ? 'perdido' : 'encontrado'}"${lostItem.title}" ha sido actualizado a ${statusNames[statusId]}.`,
          itemId
        });
      }
      
      console.log("Status updated successfully");
      res.status(200).json(createResponse(true, 'Lost item status updated successfully', { lostItem: updatedItem }));
    } catch (error) {
      console.error('Update lost item status error:', error);
      
      // Eliminar archivos subidos en caso de error
      if (req.files) {
        try {
          if (req.files.idPhoto && req.files.idPhoto.length > 0) {
            await deleteFile(`lostitems/${req.files.idPhoto[0].filename}`);
          }
          if (req.files.claimPhoto && req.files.claimPhoto.length > 0) {
            await deleteFile(`lostitems/${req.files.claimPhoto[0].filename}`);
          }
        } catch (deleteError) {
          console.error('Error cleaning up files after error:', deleteError);
        }
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all lost item statuses
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getStatuses(req, res) {
    try {
      const statuses = await lostItemModel.getStatuses();
      
      res.status(200).json(createResponse(true, 'Lost item statuses retrieved', { statuses }));
    } catch (error) {
      console.error('Get lost item statuses error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new LostItemController();