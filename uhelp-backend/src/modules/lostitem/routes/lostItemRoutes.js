const express = require('express');
const multer = require('multer');
const { body } = require('express-validator');
const lostItemController = require('../controllers/lostItemController');
const { authenticateToken, isStaffOrAdmin } = require('../../../middleware/auth');
const { lostItemsUpload, createStorage, fileFilter } = require('../../../middleware/upload');

const router = express.Router();

// Get all lost items (with optional filters)
router.get('/', lostItemController.getLostItems);

// Get all lost item statuses
router.get('/statuses/all', lostItemController.getStatuses);

// Get lost item by ID
router.get('/:id', lostItemController.getLostItem);

// Create a new lost item
router.post(
  '/',
  authenticateToken,
  lostItemsUpload('image'),
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
    
    body('isFound')
      .notEmpty()
      .withMessage('Please specify if the item is lost or found'),
    
    body('contactInfo')
      .notEmpty()
      .withMessage('Contact information is required')
      .isLength({ min: 5, max: 255 })
      .withMessage('Contact information must be between 5 and 255 characters')
  ],
  lostItemController.createLostItem
);

// Update a lost item
router.put(
  '/:id',
  authenticateToken,
  lostItemsUpload('image'),
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
    
    body('contactInfo')
      .optional()
      .isLength({ min: 5, max: 255 })
      .withMessage('Contact information must be between 5 and 255 characters')
  ],
  lostItemController.updateLostItem
);

// Delete a lost item
router.delete('/:id', authenticateToken, lostItemController.deleteLostItem);

// Update lost item status (staff/admin only) - RUTA CORREGIDA
router.put(
  '/:id/status',
  authenticateToken,
  isStaffOrAdmin,
  (req, res, next) => {
    console.log("===== PROCESANDO ACTUALIZACIÓN DE ESTADO =====");
    console.log("Params:", req.params);
    console.log("Query:", req.query);
    console.log("Body:", req.body);
    
    // Intentar obtener statusId de varias fuentes
    let statusId = null;
    
    // 1. Revisar en query params (prioridad)
    if (req.query && req.query.statusId) {
      statusId = parseInt(req.query.statusId);
      console.log(`statusId obtenido de query params: ${statusId}`);
    } 
    // 2. Revisar en body
    else if (req.body && req.body.statusId) {
      statusId = parseInt(req.body.statusId);
      console.log(`statusId obtenido de body: ${statusId}`);
    }
    
    // Validar que sea un número
    if (isNaN(statusId)) {
      console.log("statusId no es un número válido");
      return res.status(400).json({
        success: false,
        message: 'statusId debe ser un número válido'
      });
    }
    
    // Guardar en req para uso posterior
    req.statusId = statusId;
    
    // Si es estado claimed (3), aplicar middleware de carga de archivos
    if (statusId === 3) {
      console.log("Procesando estado claimed, esperando archivos...");
      return multer({
        storage: createStorage('lostitems'),
        limits: { fileSize: process.env.MAX_FILE_SIZE * 1024 * 1024 },
        fileFilter: fileFilter
      }).fields([
        { name: 'idPhoto', maxCount: 1 },
        { name: 'claimPhoto', maxCount: 1 }
      ])(req, res, (err) => {
        if (err) {
          console.error("Error en carga de archivos:", err);
          return res.status(400).json({
            success: false,
            message: `Error al subir imágenes: ${err.message}`
          });
        }
        console.log("Archivos recibidos correctamente");
        next();
      });
    }
    
    console.log("Continuando sin carga de archivos");
    next();
  },
  // Validaciones personalizadas
  (req, res, next) => {
    // Usar el statusId ya procesado
    const statusId = req.statusId;
    
    if (!statusId || statusId < 1 || statusId > 4) {
      return res.status(400).json({
        success: false,
        message: 'Status ID debe ser un valor entre 1 y 4'
      });
    }
    
    // Validar fotos para estado claimed
    if (statusId === 3) {
      if (!req.files || 
          !req.files.idPhoto || req.files.idPhoto.length === 0 || 
          !req.files.claimPhoto || req.files.claimPhoto.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Se requieren fotos de identificación y entrega para marcar como reclamado'
        });
      }
    }
    
    next();
  },
  lostItemController.updateStatus
);

module.exports = router;