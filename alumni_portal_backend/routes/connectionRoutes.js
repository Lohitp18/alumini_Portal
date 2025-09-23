const express = require('express');
const { connectUser, listMyConnections, updateConnection } = require('../controllers/connectionController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/:userId', authMiddleware, connectUser);
router.get('/', authMiddleware, listMyConnections);
router.put('/:id', authMiddleware, updateConnection);

module.exports = router;


