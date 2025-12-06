// src/middleware/upload.js
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
require('dotenv').config();

// Set storage engine
const createStorage = (destination) => {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadPath = path.join(process.env.UPLOAD_PATH, destination);
      
      // Create the directory if it doesn't exist
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      // Generate unique filename with original extension
      const fileExt = path.extname(file.originalname);
      const fileName = `${uuidv4()}${fileExt}`;
      cb(null, fileName);
    }
  });
};

// File filter
const fileFilter = (req, file, cb) => {
  // Allow only images (jpeg, jpg, png, gif)
  const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
  
  console.log(`File upload: ${file.originalname}, type: ${file.mimetype}`);
  
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file format. Only JPEG, JPG, PNG, and GIF are allowed.'), false);
  }
};

// Create multer upload instances
const problemsStorage = createStorage('problems');
const lostItemsStorage = createStorage('lostitems');
const profilesStorage = createStorage('profiles');
const announcementsStorage = createStorage('announcements');

// Create multer upload instances for different purposes
const problemsUpload = multer({
  storage: problemsStorage,
  limits: {
    fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024, // Convert MB to bytes
  },
  fileFilter: fileFilter
});

const lostItemsUpload = multer({
  storage: lostItemsStorage,
  limits: {
    fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024, // Convert MB to bytes
  },
  fileFilter: fileFilter
});

const profilesUpload = multer({
  storage: profilesStorage,
  limits: {
    fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024, // Convert MB to bytes
  },
  fileFilter: fileFilter
});

const announcementsUpload = multer({
  storage: announcementsStorage,
  limits: {
    fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024, // Convert MB to bytes
  },
  fileFilter: fileFilter
});

// Función para múltiples archivos
const lostItemsMultiUpload = (fields) => {
  return multer({
    storage: lostItemsStorage,
    limits: {
      fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024
    },
    fileFilter: fileFilter
  }).fields(fields);
};

// Error handling middleware for multer
const handleUploadError = (uploadFunction) => {
  return (req, res, next) => {
    uploadFunction(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        console.error("Multer error:", err);
        // A Multer error occurred when uploading
        return res.status(400).json({
          success: false,
          message: `Upload error: ${err.message}`
        });
      } else if (err) {
        console.error("Upload error:", err);
        // An unknown error occurred
        return res.status(500).json({
          success: false,
          message: err.message
        });
      }
      
      // Everything went fine
      next();
    });
  };
};

// Exportar funciones
module.exports = {
  // Funciones originales
  problemsUpload: (fieldName) => handleUploadError(problemsUpload.single(fieldName)),
  lostItemsUpload: (fieldName) => handleUploadError(lostItemsUpload.single(fieldName)),
  profilesUpload: (fieldName) => handleUploadError(profilesUpload.single(fieldName)),
  announcementsUpload: (fieldName) => handleUploadError(announcementsUpload.single(fieldName)),
  
  // Nuevas funciones para múltiples archivos
  lostItemsMultiUpload: (fields) => handleUploadError(lostItemsMultiUpload(fields)),
  
  // Exportar funciones de utilidad para casos especiales
  createStorage,
  fileFilter
};