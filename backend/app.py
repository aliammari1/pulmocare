from flask import Flask, request, make_response, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from routes.ordonnance_routes import ordonnance_bp
import os

load_dotenv()

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": ["*"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "Accept"],
        "supports_credentials": True,
        "max_age": 3600
    }
})

@app.before_request
def handle_preflight():
    if request.method == "OPTIONS":
        response = make_response()
        response.headers.update({
            "Access-Control-Allow-Origin": request.headers.get("Origin", "*"),
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin",
            "Access-Control-Max-Age": "3600",
            "Access-Control-Allow-Credentials": "true"
        })
        return response

@app.after_request
def after_request(response):
    origin = request.headers.get('Origin', '')
    if origin:
        response.headers.add('Access-Control-Allow-Origin', origin)
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,Accept,Origin')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    response.headers.add('Access-Control-Allow-Credentials', 'true')
    return response

# Mise à jour de l'enregistrement du blueprint
app.register_blueprint(ordonnance_bp, url_prefix='/ordonnances')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
