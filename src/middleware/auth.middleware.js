const jwt = require("jsonwebtoken");

function authMiddleware(req, res, next) {

    try {

        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: "Authentication required"
            });
        }


        // Expected:
        // Authorization: Bearer TOKEN

        const parts = authHeader.split(" ");

        if (
            parts.length !== 2 ||
            parts[0] !== "Bearer"
        ) {
            return res.status(401).json({
                success: false,
                message: "Invalid authorization format"
            });
        }


        const token = parts[1];


        // Verify JWT

        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );


        // Make user information available
        // to the next controller

        req.user = decoded;

        next();

    } catch (error) {

        console.error("AUTH MIDDLEWARE ERROR:", error.message);

        return res.status(401).json({
            success: false,
            message: "Invalid or expired token"
        });
    }
}


module.exports = authMiddleware;