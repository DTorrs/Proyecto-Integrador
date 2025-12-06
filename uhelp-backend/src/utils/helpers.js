// src/utils/helpers.js
const fs = require('fs');
const path = require('path');

/**
 * Generate a response object with standard format
 * @param {boolean} success - Whether the operation was successful
 * @param {string} message - Message to be displayed to the user
 * @param {object} data - Data to be returned (optional)
 * @param {object} error - Error details (only in development, optional)
 * @returns {object} Standardized response object
 */
const createResponse = (success, message, data = null, error = null) => {
  const response = {
    success,
    message
  };

  if (data !== null) {
    response.data = data;
  }

  // Include error details only in development environment
  if (error !== null && process.env.NODE_ENV === 'development') {
    response.error = error;
  }

  return response;
};

/**
 * Delete a file from the uploads directory
 * @param {string} filePath - Path to the file relative to the uploads directory
 * @returns {Promise<boolean>} - True if file was deleted or didn't exist, false if error
 */
const deleteFile = async (filePath) => {
  try {
    if (!filePath) return true;

    const fullPath = path.join(process.env.UPLOAD_PATH, filePath);
    
    // Check if file exists before attempting to delete
    if (fs.existsSync(fullPath)) {
      await fs.promises.unlink(fullPath);
      console.log(`File deleted: ${fullPath}`);
    }
    
    return true;
  } catch (error) {
    console.error(`Error deleting file: ${error.message}`);
    return false;
  }
};

/**
 * Generate paginated results
 * @param {Array} data - The array of data to paginate
 * @param {number} page - Current page number (1-based)
 * @param {number} pageSize - Number of items per page
 * @returns {object} Paginated data object
 */
const paginateResults = (data, page = 1, pageSize = 10) => {
  const startIndex = (page - 1) * pageSize;
  const endIndex = page * pageSize;
  
  const paginatedData = {
    page: parseInt(page),
    pageSize: parseInt(pageSize),
    total: data.length,
    totalPages: Math.ceil(data.length / pageSize),
    data: data.slice(startIndex, endIndex)
  };

  if (endIndex < data.length) {
    paginatedData.hasNextPage = true;
  }

  if (startIndex > 0) {
    paginatedData.hasPreviousPage = true;
  }

  return paginatedData;
};

/**
 * Parse query parameters for pagination
 * @param {object} query - Express request query object
 * @returns {object} Parsed pagination parameters
 */
const getPaginationParams = (query) => {
  return {
    page: parseInt(query.page || 1),
    pageSize: parseInt(query.pageSize || 10)
  };
};

/**
 * Generate a slug from a string
 * @param {string} text - The text to convert to a slug
 * @returns {string} URL-friendly slug
 */
const generateSlug = (text) => {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')       // Replace spaces with -
    .replace(/[^\w\-]+/g, '')   // Remove all non-word chars
    .replace(/\-\-+/g, '-')     // Replace multiple - with single -
    .replace(/^-+/, '')         // Trim - from start of text
    .replace(/-+$/, '');        // Trim - from end of text
};

module.exports = {
  createResponse,
  deleteFile,
  paginateResults,
  getPaginationParams,
  generateSlug
};