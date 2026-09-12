const express = require("express");

const router = express.Router();

const {
    loginUser
} = require("../controllers/authcontrol");


// Login
// POST /api/auth/login

router.post("/login", loginUser);


module.exports = router;