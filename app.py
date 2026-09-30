from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(
        {
            "application": "hello-policy-app",
            "message": "CI/CD deployment is working",
            "environment": os.getenv("APP_ENV", "development")
        }
    )

@app.get("/health")
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)

