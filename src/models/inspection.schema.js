const mongoose = require("mongoose");

const inspectionSchema = new mongoose.Schema(
    {
        officer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        productName: {
            type: String,
            required: true
        },

        status: {
            type: String,
            enum: ["created", "processing", "completed", "failed"],
            default: "created"
        },

        complianceStatus: {
            type: String,
            enum: ["compliant", "non-compliant", "needs-review", "pending"],
            default: "pending"
        },

        images: [
            {
                type: String
            }
        ],

        extractedData: {
            type: Object,
            default: {}
        },

        violations: [
            {
                type: Object
            }
        ]
    },
    {
        timestamps: true
    }
);
const inspectionModel = mongoose.model("Inspection", inspectionSchema);

module.exports = inspectionModel;