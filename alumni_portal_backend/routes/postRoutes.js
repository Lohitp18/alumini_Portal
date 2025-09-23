const express = require('express');
const { createPost, getFriendsFeed, uploadOptionalImage, toggleLike, reportPost } = require('../controllers/postController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/', authMiddleware, uploadOptionalImage, createPost);
router.get('/feed', authMiddleware, getFriendsFeed);
router.patch('/:postId/like', authMiddleware, toggleLike);
router.post('/:postId/report', authMiddleware, reportPost);

module.exports = router;


