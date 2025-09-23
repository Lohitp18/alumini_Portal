const express = require('express');
const { createPost, getFriendsFeed, uploadOptionalImage } = require('../controllers/postController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/', authMiddleware, uploadOptionalImage, createPost);
router.get('/feed', authMiddleware, getFriendsFeed);

module.exports = router;


