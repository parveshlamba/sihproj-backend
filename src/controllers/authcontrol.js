const userModel = require("../models/user.schema");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");


// ======================================================
// LOGIN
// ======================================================

async function loginUser(req, res) {

    try {

        const { email, password, role } = req.body;

        // -----------------------------------------------
        // Validate request
        // -----------------------------------------------

        if (!email || !password || !role) {
            return res.status(400).json({
                success: false,
                message: "Email, password and role are required"
            });
        }


        // -----------------------------------------------
        // Validate role
        // -----------------------------------------------

        const allowedRoles = [
            "inspector",
            "controller",
            "admin"
        ];

        if (!allowedRoles.includes(role)) {
            return res.status(400).json({
                success: false,
                message: "Invalid role"
            });
        }


        // -----------------------------------------------
        // Find user
        // -----------------------------------------------

        const user = await userModel.findOne({
            email: email.toLowerCase().trim()
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            });
        }


        // -----------------------------------------------
        // Check role
        // -----------------------------------------------

        if (user.role !== role) {
            return res.status(401).json({
                success: false,
                message: "Invalid role for this account"
            });
        }


        // -----------------------------------------------
        // Check password
        // -----------------------------------------------

        const isPasswordValid = await bcrypt.compare(
            password,
            user.password
        );

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            });
        }


        // -----------------------------------------------
        // Generate JWT
        // -----------------------------------------------

        const token = jwt.sign(
            {
                id: user._id.toString(),
                role: user.role
            },
            process.env.JWT_SECRET,
            {
                expiresIn: "7d"
            }
        );


        // -----------------------------------------------
        // Send response
        // -----------------------------------------------

        return res.status(200).json({

            success: true,

            message: "Login successful",

            token: token,

            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }

        });

    } catch (error) {

        console.error("LOGIN ERROR:", error);

        return res.status(500).json({
            success: false,
            message: "Internal server error"
        });
    }
}


module.exports = {
    loginUser
};