// src/modules/announcement/controllers/announcementController.js
const { validationResult } = require('express-validator');
const announcementModel = require('../models/announcementModel');
const notificationModel = require('../../notification/models/notificationModel');
const { createResponse, getPaginationParams, paginateResults, deleteFile } = require('../../../utils/helpers');

class AnnouncementController {
  /**
   * Create a new announcement
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async createAnnouncement(req, res) {
    try {
      console.log('Create announcement request body:', req.body);
      console.log('Create announcement file:', req.file);
      
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Validation errors:', errors.array());
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }

      const { title, content, isActive, startDate, endDate } = req.body;
      const userId = req.user.id;
      
      // Get image file if uploaded
      const imageUrl = req.file ? req.file.filename : null;
      
      // Prepare announcement data
      const announcementData = {
        title,
        content,
        userId,
        isActive: isActive === 'true' || isActive === true,
        startDate: startDate || new Date(),
        endDate: endDate || null,
        imageUrl
      };
      
      console.log('Processed announcement data:', announcementData);
      
      // Create the announcement
      const announcement = await announcementModel.createAnnouncement(announcementData);
      
      // Broadcast to all connected clients via Socket.IO if active
      if (announcement.is_active) {
        const io = req.app.get('io');
        if (io) {
          io.emit('announcement', {
            type: 'new_announcement',
            message: `New announcement: ${announcement.title}`,
            announcementId: announcement.id
          });
        }
      }
      
      res.status(201).json(createResponse(true, 'Announcement created successfully', { announcement }));
    } catch (error) {
      console.error('Create announcement error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`announcements/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get an announcement by ID
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getAnnouncement(req, res) {
    try {
      const announcementId = req.params.id;
      
      // Get the announcement
      const announcement = await announcementModel.getAnnouncementById(announcementId);
      
      if (!announcement) {
        return res.status(404).json(createResponse(false, 'Announcement not found'));
      }
      
      res.status(200).json(createResponse(true, 'Announcement retrieved', { announcement }));
    } catch (error) {
      console.error('Get announcement error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get all announcements with filtering and pagination
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getAnnouncements(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Extract filter parameters
      const filters = {
        activeOnly: req.query.activeOnly === 'true',
        userId: req.query.userId,
        search: req.query.search
      };
      
      // Get announcements
      const announcements = await announcementModel.getAnnouncements(filters);
      
      // Paginate results
      const paginatedAnnouncements = paginateResults(announcements, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Announcements retrieved', paginatedAnnouncements));
    } catch (error) {
      console.error('Get announcements error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update an announcement
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateAnnouncement(req, res) {
    try {
      console.log('Update announcement request body:', req.body);
      console.log('Update announcement file:', req.file);
      
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Validation errors:', errors.array());
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const announcementId = req.params.id;
      const userId = req.user.id;
      
      // Check if announcement exists
      const announcement = await announcementModel.getAnnouncementById(announcementId);
      
      if (!announcement) {
        return res.status(404).json(createResponse(false, 'Announcement not found'));
      }
      
      // Only staff/admin can update announcements
      // If user is not an admin and not the creator, deny access
      if (req.user.role_id !== 2 && req.user.role_id !== 3 && announcement.user_id !== userId) {
        return res.status(403).json(createResponse(false, 'Not authorized to update this announcement'));
      }
      
      // Extract update data
      const { title, content, isActive, startDate, endDate } = req.body;
      
      const updateData = {};
      
      if (title !== undefined) updateData.title = title;
      if (content !== undefined) updateData.content = content;
      if (isActive !== undefined) updateData.isActive = isActive === 'true' || isActive === true;
      if (startDate !== undefined) updateData.startDate = startDate;
      if (endDate !== undefined) updateData.endDate = endDate;
      
      // Handle image upload
      if (req.file) {
        updateData.imageUrl = req.file.filename;
        
        // Delete old image if exists
        if (announcement.image_url) {
          await deleteFile(`announcements/${announcement.image_url}`);
        }
      }
      
      console.log('Processed update data:', updateData);
      
      // Update the announcement
      const updatedAnnouncement = await announcementModel.updateAnnouncement(announcementId, updateData);
      
      // Broadcast to all connected clients via Socket.IO if made active
      if (!announcement.is_active && updatedAnnouncement.is_active) {
        const io = req.app.get('io');
        if (io) {
          io.emit('announcement', {
            type: 'new_announcement',
            message: `New announcement: ${updatedAnnouncement.title}`,
            announcementId: updatedAnnouncement.id
          });
        }
      }
      
      res.status(200).json(createResponse(true, 'Announcement updated successfully', { announcement: updatedAnnouncement }));
    } catch (error) {
      console.error('Update announcement error:', error);
      
      // Delete uploaded file if there was an error
      if (req.file) {
        await deleteFile(`announcements/${req.file.filename}`);
      }
      
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Delete an announcement
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async deleteAnnouncement(req, res) {
    try {
      const announcementId = req.params.id;
      const userId = req.user.id;
      
      // Check if announcement exists
      const announcement = await announcementModel.getAnnouncementById(announcementId);
      
      if (!announcement) {
        return res.status(404).json(createResponse(false, 'Announcement not found'));
      }
      
      // Only staff/admin can delete announcements
      // If user is not an admin and not the creator, deny access
      if (req.user.role_id !== 2 && req.user.role_id !== 3 && announcement.user_id !== userId) {
        return res.status(403).json(createResponse(false, 'Not authorized to delete this announcement'));
      }
      
      // Delete the image if exists
      if (announcement.image_url) {
        await deleteFile(`announcements/${announcement.image_url}`);
      }
      
      // Delete the announcement
      await announcementModel.deleteAnnouncement(announcementId);
      
      res.status(200).json(createResponse(true, 'Announcement deleted successfully'));
    } catch (error) {
      console.error('Delete announcement error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get active announcements
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getActiveAnnouncements(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Get active announcements
      const announcements = await announcementModel.getActiveAnnouncements();
      
      // Paginate results
      const paginatedAnnouncements = paginateResults(announcements, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Active announcements retrieved', paginatedAnnouncements));
    } catch (error) {
      console.error('Get active announcements error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new AnnouncementController();