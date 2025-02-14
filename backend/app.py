from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from models import Doctor
import os
from bson import ObjectId
from dotenv import load_dotenv
import random
import smtplib
from email.mime.text import MIMEText
import jwt
from functools import wraps
from datetime import datetime, timedelta
import re
import base64
import io
from PIL import Image
import pytesseract

load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/api/*": {'origins': '*', 'methods': ['GET', 'POST', 'OPTIONS']}})

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017/'))
db = client.medicare
doctors_collection = db.doctors

JWT_SECRET = os.getenv('JWT_SECRET', 'replace-with-strong-secret')

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'Token missing'}), 401
        token = auth_header.split()[1]
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            user_id = payload['user_id']
        except:
            return jsonify({'error': 'Invalid token'}), 401
        return f(user_id, *args, **kwargs)
    return decorated

def send_otp_email(to_email, otp):
    sender_email = os.getenv('EMAIL_ADDRESS', 'aladinhabibii@gmail.com')
    sender_password = os.getenv('EMAIL_PASSWORD', 'wdgbjclkscvpsjay')
    msg = MIMEText(f'Your OTP code is: {otp}')
    msg['Subject'] = 'Password Reset OTP'
    msg['From'] = sender_email
    msg['To'] = to_email

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
        smtp.login(sender_email, sender_password)
        smtp.send_message(msg)

@app.route('/api/signup', methods=['POST'])
def signup():
    data = request.get_json()
    
    # Check if email already exists
    if doctors_collection.find_one({'email': data['email']}):
        return jsonify({'error': 'Email already registered'}), 400

    doctor = Doctor(
        name=data['name'],
        email=data['email'],
        specialty=data['specialty'],
        phone_number=data['phoneNumber'],
        address=data['address'],
        password=data['password']
    )

    # Insert the doctor document
    result = doctors_collection.insert_one({
        '_id': doctor._id,
        'name': doctor.name,
        'email': doctor.email,
        'password_hash': doctor.password_hash,
        'specialty': doctor.specialty,
        'phone_number': doctor.phone_number,
        'address': doctor.address
    })

    return jsonify(doctor.to_dict()), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # Find doctor by email
    doctor_data = doctors_collection.find_one({'email': data['email']})
    if not doctor_data:
        return jsonify({'error': 'Invalid credentials'}), 401

    # Create Doctor instance and verify password
    doctor = Doctor.from_dict(doctor_data)
    doctor.password_hash = doctor_data['password_hash']

    if doctor.check_password(data['password']):
        token = jwt.encode({'user_id': str(doctor._id), 'exp': datetime.utcnow() + timedelta(days=1)}, JWT_SECRET)
        return jsonify({'token': token, **doctor.to_dict()}), 200
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')
    doctor_data = doctors_collection.find_one({'email': email})
    if not doctor_data:
        return jsonify({'error': 'Email not found'}), 404

    otp = str(random.randint(100000, 999999))
    doctors_collection.update_one(
        {'email': email},
        {'$set': {'reset_otp': otp, 'otp_expiry': datetime.utcnow() + timedelta(minutes=15)}}
    )
    try:
        send_otp_email(email, otp)
        return jsonify({'message': 'OTP sent'}), 200
    except:
        return jsonify({'error': 'Failed to send OTP'}), 500

@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    result = doctors_collection.find_one({
        'email': email,
        'reset_otp': otp,
        'otp_expiry': {'$gt': datetime.utcnow()}
    })
    if not result:
        return jsonify({'error': 'Invalid or expired OTP'}), 400
    return jsonify({'message': 'OTP verified'}), 200

@app.route('/api/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    new_password = data.get('newPassword')
    doctor_data = doctors_collection.find_one({
        'email': email,
        'reset_otp': otp,
        'otp_expiry': {'$gt': datetime.utcnow()}
    })
    if not doctor_data:
        return jsonify({'error': 'Invalid or expired OTP'}), 400

    doctor_obj = Doctor.from_dict(doctor_data)
    doctor_obj.set_password(new_password)
    doctors_collection.update_one(
        {'email': email},
        {
            '$set': {'password_hash': doctor_obj.password_hash},
            '$unset': {'reset_otp': '', 'otp_expiry': ''}
        }
    )
    return jsonify({'message': 'Password reset successful'}), 200

@app.route('/api/profile', methods=['GET'])
@token_required
def get_profile(user_id):
    doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not doctor_data:
        return jsonify({'error': 'Doctor not found'}), 404
    return jsonify(Doctor.from_dict(doctor_data).to_dict()), 200

@app.route('/api/change-password', methods=['POST'])
@token_required
def change_password(user_id):
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not doctor_data:
        return jsonify({'error': 'Doctor not found'}), 404

    doctor = Doctor.from_dict(doctor_data)
    doctor.password_hash = doctor_data['password_hash']

    if not doctor.check_password(current_password):
        return jsonify({'error': 'Current password is incorrect'}), 400

    doctor.set_password(new_password)
    doctors_collection.update_one(
        {'_id': ObjectId(user_id)},
        {'$set': {'password_hash': doctor.password_hash}}
    )

    return jsonify({'message': 'Password updated successfully'}), 200

@app.route('/api/update-profile', methods=['PUT'])
@token_required
def update_profile(user_id):
    data = request.get_json()
    name = data.get('name')
    specialty = data.get('specialty')
    phone_number = data.get('phone_number')
    address = data.get('address')
    base64_image = data.get('base64Image', None)

    doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not doctor_data:
        return jsonify({'error': 'Doctor not found'}), 404

    update_fields = {
        'name': name,
        'specialty': specialty,
        'phone_number': phone_number,
        'address': address,
    }
    # If you choose to store the image in the database
    if base64_image:
        update_fields['profile_image'] = base64_image

    doctors_collection.update_one({'_id': ObjectId(user_id)}, {'$set': update_fields})
    updated_doctor = doctors_collection.find_one({'_id': ObjectId(user_id)})

    return jsonify(Doctor.from_dict(updated_doctor).to_dict()), 200

@app.route('/api/logout', methods=['POST'])
@token_required
def logout(user_id):
    # Optionally blacklist or track tokens here if desired
    return jsonify({'message': 'Logged out successfully'}), 200

@app.route('/api/scan-visit-card', methods=['POST'])
def scan_visit_card():
    data = request.get_json()
    image_data = data.get('image')

    if not image_data:
        return jsonify({'error': 'No image provided'}), 400

    try:
        # Decode base64 image
        image = Image.open(io.BytesIO(base64.b64decode(image_data)))

        # Perform OCR using pytesseract
        text = pytesseract.image_to_string(image)

        # Extract relevant information (this will need to be refined based on visit card format)
        name = extract_name(text)
        email = extract_email(text)
        specialty = extract_specialty(text)
        phone = extract_phone_number(text)  # New helper function

        return jsonify({
            'name': name,
            'email': email,
            'specialty': specialty,
            'phone_number': phone  # Return extracted phone
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def extract_name(text):
    # Implement logic to extract name from text
    # This is a placeholder and needs to be implemented based on the visit card format
    # Example: Use regular expressions to find a name pattern
    name_match = re.search(r'([A-Z][a-z]+ [A-Z][a-z]+)', text)
    if name_match:
        return name_match.group(1)
    return "Extracted Name"

def extract_email(text):
    # Implement logic to extract email from text
    # This is a placeholder and needs to be implemented based on the visit card format
    email_match = re.search(r'[\w\.-]+@[\w\.-]+', text)
    if email_match:
        return email_match.group(0)
    return "Extracted Email"

def extract_specialty(text):
    lines = text.split('\n')
    lines = [l.strip() for l in lines if l.strip()]
    name_pattern = re.compile(r'([A-Z][a-z]+ [A-Z][a-z]+)')
    for i, line in enumerate(lines):
        if name_pattern.search(line):
            if i + 1 < len(lines):
                return lines[i + 1]
    return "Extracted Specialty"

def extract_phone_number(text):
    # Basic pattern to match phone formats, can be refined
    phone_match = re.search(r'(\+?\d[\d\s\-]{7,}\d)', text)
    if phone_match:
        return phone_match.group(0).strip()
    return "Extracted Phone"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000, debug=True)
