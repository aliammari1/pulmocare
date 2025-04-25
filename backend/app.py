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
import logging
from langdetect import detect, LangDetectException
from transliterate import translit

load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/api/*": {'origins': '*', 'methods': ['GET', 'POST', 'OPTIONS']}})

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017/'))
db = client.medicare
doctors_collection = db.doctors

JWT_SECRET = os.getenv('JWT_SECRET', 'replace-with-strong-secret')

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

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
    try:
        sender_email = os.getenv('EMAIL_ADDRESS')
        sender_password = os.getenv('EMAIL_PASSWORD')
        
        logger.debug(f"Email configuration - Sender: {sender_email}, Password length: {len(sender_password) if sender_password else 0}")
        
        if not sender_email or not sender_password:
            logger.error("Email configuration missing")
            raise Exception("Email configuration missing")

        msg = MIMEText(f'''
        Hello,

        Your OTP code for password reset is: {otp}

        This code will expire in 15 minutes.
        If you did not request this code, please ignore this email.

        Best regards,
        Medicare Team
        ''')
        
        msg['Subject'] = 'Medicare - Password Reset OTP'
        msg['From'] = sender_email
        msg['To'] = to_email

        try:
            logger.debug("Attempting SMTP connection to smtp.gmail.com:465")
            smtp = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=10)
            logger.debug("SMTP connection successful")
            
            logger.debug("Attempting SMTP login")
            smtp.login(sender_email, sender_password)
            logger.debug("SMTP login successful")
            
            logger.debug("Sending email")
            smtp.send_message(msg)
            logger.debug("Email sent successfully")
            
            smtp.quit()
            return True
            
        except smtplib.SMTPAuthenticationError as auth_error:
            logger.error(f"SMTP Authentication failed - Details: {str(auth_error)}")
            raise Exception(f"Email authentication failed. Please check your credentials.")
            
        except smtplib.SMTPException as smtp_error:
            logger.error(f"SMTP error occurred: {str(smtp_error)}")
            raise Exception(f"Email sending failed: {str(smtp_error)}")
            
        except Exception as e:
            logger.error(f"Unexpected SMTP error: {str(e)}")
            raise Exception(f"Unexpected error while sending email: {str(e)}")
            
    except Exception as e:
        logger.error(f"Email sending error: {str(e)}")
        return False

@app.route('/api/signup', methods=['POST'])
def signup():
    data = request.get_json()
    
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

    # Insert the doctor document with is_verified field
    result = doctors_collection.insert_one({
        '_id': doctor._id,
        'name': doctor.name,
        'email': doctor.email,
        'password_hash': doctor.password_hash,
        'specialty': doctor.specialty,
        'phone_number': doctor.phone_number,
        'address': doctor.address,
        'is_verified': False  # Add default verification status
    })

    return jsonify(doctor.to_dict()), 201

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        logger.debug(f"Login attempt for email: {data.get('email')}")  # Add debug log
        
        if not data or 'email' not in data or 'password' not in data:
            return jsonify({'error': 'Email and password are required'}), 400

        doctor_data = doctors_collection.find_one({'email': data['email']})
        if not doctor_data:
            logger.debug("Email not found")  # Add debug log
            return jsonify({'error': 'Invalid credentials'}), 401

        doctor = Doctor.from_dict(doctor_data)
        doctor.password_hash = doctor_data['password_hash']

        if doctor.check_password(data['password']):
            token = jwt.encode(
                {
                    'user_id': str(doctor_data['_id']),
                    'exp': datetime.utcnow() + timedelta(days=1)
                },
                JWT_SECRET,
                algorithm='HS256'
            )
            
            # Include verification status and details in response
            response_data = {
                'token': token,
                'id': str(doctor_data['_id']),
                'name': doctor_data['name'],
                'email': doctor_data['email'],
                'specialty': doctor_data['specialty'],
                'phone_number': doctor_data.get('phone_number', ''),
                'address': doctor_data.get('address', ''),
                'profile_image': doctor_data.get('profile_image'),
                'is_verified': doctor_data.get('is_verified', False),
                'verification_details': doctor_data.get('verification_details', None),
                'signature': doctor_data.get('signature')  # Add this line
            }
            
            logger.debug("Login successful")  # Add debug log
            return jsonify(response_data), 200
        else:
            logger.debug("Invalid password")  # Add debug log
            return jsonify({'error': 'Invalid credentials'}), 401
            
    except Exception as e:
        logger.error(f"Login error: {str(e)}")  # Add debug log
        return jsonify({'error': 'Server error: ' + str(e)}), 500

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data.get('email')
        
        logger.debug(f"Forgot password request received for email: {email}")
        
        if not email:
            return jsonify({'error': 'Email is required'}), 400

        doctor_data = doctors_collection.find_one({'email': email})
        if not doctor_data:
            logger.debug(f"Email not found: {email}")
            return jsonify({'error': 'Email not found'}), 404

        otp = str(random.randint(100000, 999999))
        logger.debug(f"Generated OTP: {otp}")
        
        if send_otp_email(email, otp):
            doctors_collection.update_one(
                {'email': email},
                {'$set': {
                    'reset_otp': otp,
                    'otp_expiry': datetime.utcnow() + timedelta(minutes=15)
                }}
            )
            logger.debug("OTP sent and saved successfully")
            return jsonify({'message': 'OTP sent successfully'}), 200
        else:
            logger.error("Failed to send OTP email")
            return jsonify({'error': 'Failed to send OTP. Please try again later.'}), 500
    
    except Exception as e:
        logger.error(f"Unexpected error in forgot_password: {str(e)}")
        return jsonify({'error': f'An unexpected error occurred: {str(e)}'}), 500

@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    
    if not email or not otp:
        return jsonify({'error': 'Email and OTP are required'}), 400
        
    result = doctors_collection.find_one({
        'email': email,
        'reset_otp': otp,
        'otp_expiry': {'$gt': datetime.utcnow()}
    })
    
    if not result:
        return jsonify({'error': 'Invalid or expired OTP'}), 400
    
    return jsonify({'message': 'OTP verified successfully'}), 200

@app.route('/api/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    new_password = data.get('newPassword')
    
    if not all([email, otp, new_password]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    doctor_data = doctors_collection.find_one({
        'email': email,
        'reset_otp': otp,
        'otp_expiry': {'$gt': datetime.utcnow()}
    })
    
    if not doctor_data:
        return jsonify({'error': 'Invalid or expired OTP'}), 400

    # Create a Doctor instance and set the new password
    doctor = Doctor.from_dict(doctor_data)
    doctor.set_password(new_password)
    
    # Update the password hash and remove the OTP data
    result = doctors_collection.update_one(
        {'email': email},
        {
            '$set': {'password_hash': doctor.password_hash},
            '$unset': {'reset_otp': '', 'otp_expiry': ''}
        }
    )
    
    if result.modified_count == 0:
        return jsonify({'error': 'Failed to update password'}), 500
        
    return jsonify({'message': 'Password reset successful'}), 200

@app.route('/api/profile', methods=['GET'])
@token_required
def get_profile(user_id):
    doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not doctor_data:
        return jsonify({'error': 'Doctor not found'}), 404
    
    # Make sure to include verification status and signature in response
    response_data = Doctor.from_dict(doctor_data).to_dict()
    response_data.update({
        'is_verified': doctor_data.get('is_verified', False),
        'signature': doctor_data.get('signature')  # Add this line
    })
    return jsonify(response_data), 200

@app.route('/api/change-password', methods=['POST'])
@token_required
def change_password(user_id):
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not all([current_password, new_password]):
        return jsonify({'error': 'Both current and new password are required'}), 400

    doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not doctor_data:
        return jsonify({'error': 'Doctor not found'}), 404

    doctor = Doctor.from_dict(doctor_data)
    doctor.password_hash = doctor_data['password_hash']

    if not doctor.check_password(current_password):
        return jsonify({'error': 'Current password is incorrect'}), 400

    # Set and hash the new password
    doctor.set_password(new_password)
    
    # Update the password hash in the database
    result = doctors_collection.update_one(
        {'_id': ObjectId(user_id)},
        {'$set': {'password_hash': doctor.password_hash}}
    )

    if result.modified_count == 0:
        return jsonify({'error': 'Failed to update password'}), 500

    return jsonify({'message': 'Password updated successfully'}), 200

@app.route('/api/update-profile', methods=['PUT'])
@token_required
def update_profile(user_id):
    data = request.get_json()
    
    # Get current doctor data to preserve verification status
    current_doctor = doctors_collection.find_one({'_id': ObjectId(user_id)})
    if not current_doctor:
        return jsonify({'error': 'Doctor not found'}), 404

    update_fields = {
        'name': data.get('name'),
        'specialty': data.get('specialty'),
        'phone_number': data.get('phone_number'),
        'address': data.get('address'),
    }
    
    if data.get('profile_image'):
        update_fields['profile_image'] = data.get('profile_image')

    # Update while preserving verification status
    doctors_collection.update_one(
        {'_id': ObjectId(user_id)}, 
        {'$set': update_fields}
    )
    
    # Get updated doctor data
    updated_doctor = doctors_collection.find_one({'_id': ObjectId(user_id)})
    response_data = Doctor.from_dict(updated_doctor).to_dict()
    
    # Include verification status and details in response
    response_data.update({
        'is_verified': current_doctor.get('is_verified', False),
        'verification_details': current_doctor.get('verification_details'),
        'profile_image': updated_doctor.get('profile_image')
    })
    
    return jsonify(response_data), 200

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

@app.route('/api/verify-doctor', methods=['POST'])
@token_required
def verify_doctor(user_id):
    try:
        data = request.get_json()
        image_data = data.get('image')
        language_preference = data.get('language', 'auto')  # Allow specifying language or auto-detect

        if not image_data:
            return jsonify({'error': 'No image provided'}), 400

        # Get doctor's data from database
        doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
        if not doctor_data:
            return jsonify({'error': 'Doctor not found'}), 404

        # Get doctor's name from database
        doctor_name = doctor_data['name'].lower().strip()

        logger.debug(f"Checking for Name='{doctor_name}' with language '{language_preference}'")

        # Process the image
        image = Image.open(io.BytesIO(base64.b64decode(image_data)))
        
        # Enhance image quality for better OCR
        image = image.convert('L')  # Convert to grayscale
        image = image.point(lambda x: 0 if x < 128 else 255, '1')  # Enhance contrast

        # Detect language in the document first
        basic_text = pytesseract.image_to_string(image)
        detected_language = detect_document_language(basic_text)
        logger.debug(f"Detected document language: {detected_language}")
        
        # If a specific language was requested (not auto), verify it matches the detected language
        if language_preference != 'auto' and detected_language != 'unknown':
            expected_lang_code = get_language_code_for_comparison(language_preference)
            actual_lang_code = get_language_code_for_comparison(detected_language)
            
            if expected_lang_code != actual_lang_code:
                logger.warning(f"Language mismatch: Selected {language_preference}, but detected {detected_language}")
                return jsonify({
                    'verified': False,
                    'error': f"Language mismatch: You selected {language_preference.capitalize()} but the document appears to be in {detected_language.capitalize()}. Please select the correct language.",
                    'detected_language': detected_language
                }), 400

        # Language-specific OCR settings
        if language_preference == 'auto':
            # Auto-detect language logic
            # ...existing code...
            
            # Check if Russian language pack is available
            russian_available = check_tesseract_language('rus')
            logger.debug(f"Russian language pack available: {russian_available}")
            
            # Auto-detect language
            extracted_text = basic_text
            try:
                detected_lang = detect(basic_text)
            except LangDetectException:
                detected_lang = 'en'
        else:
            # Use specified language
            lang_code = get_tesseract_lang_code(language_preference)
            lang_available = check_tesseract_language(lang_code)
            logger.debug(f"Using language '{language_preference}' with code '{lang_code}', available: {lang_available}")
            
            if lang_available:
                extracted_text = pytesseract.image_to_string(image, lang=lang_code)
            else:
                # Fallback to default OCR if language pack not available
                extracted_text = pytesseract.image_to_string(image)
                logger.warning(f"Language pack for '{language_preference}' not available, using default")
            
            detected_lang = language_preference
            is_likely_russian = language_preference == 'russian'
        
        original_extracted_text = extracted_text
        extracted_text = extracted_text.lower().strip()
        
        logger.debug(f"Extracted text ({detected_lang}): {extracted_text[:100]}...")
        
        # Language-specific verification logic
        name_found = False
        
        if detected_lang == 'ru' or is_likely_russian or language_preference == 'russian':
            # Russian verification
            name_found = verify_russian_document(doctor_name, extracted_text, original_extracted_text)
            logger.debug(f"Russian verification result: {name_found}")
        elif language_preference == 'arabic':
            # Arabic verification - implement special handling if needed
            # This is a placeholder - you would need to implement Arabic-specific verification
            name_parts = doctor_name.split()
            name_found = any(part in extracted_text for part in name_parts)
            logger.debug(f"Arabic verification result: {name_found}")
        elif language_preference == 'french':
            # French verification - implement special handling if needed
            name_found = doctor_name in extracted_text
            if not name_found:
                name_parts = doctor_name.split()
                name_found = all(part in extracted_text for part in name_parts)
            logger.debug(f"French verification result: {name_found}")
        else:
            # Standard English verification
            name_found = doctor_name in extracted_text
            if not name_found:
                name_parts = doctor_name.split()
                name_found = all(part in extracted_text for part in name_parts)
            logger.debug(f"Standard verification result: {name_found}")

        logger.debug(f"Name found: {name_found}")

        # If verification succeeded, update status
        if name_found:
            # Update verification status
            result = doctors_collection.update_one(
                {'_id': ObjectId(user_id)},
                {'$set': {
                    'is_verified': True,
                    'verification_details': {
                        'verified_at': datetime.utcnow(),
                        'matched_text': extracted_text[:200],
                        'document_language': detected_lang,
                        'verification_method': language_preference
                    }
                }}
            )
            
            if result.modified_count > 0:
                response = {
                    'verified': True,
                    'message': 'Name verification successful',
                    'document_language': detected_lang,
                    'document_type': f"{language_preference.capitalize()} medical document"
                }
                
                # Add installation notice if language pack was not available
                if language_preference != 'auto' and not check_tesseract_language(get_tesseract_lang_code(language_preference)):
                    response['notice'] = f"{language_preference.capitalize()} language pack not detected. For better results, install the language pack."
                    response['installation_instructions'] = get_language_install_instructions()
                    
                return jsonify(response), 200
            else:
                return jsonify({'error': 'Failed to update verification status'}), 500
        else:
            response = {
                'verified': False,
                'error': 'Verification failed: name not found in document',
                'document_language': detected_lang,
                'debug_info': {
                    'name_found': name_found,
                    'doctor_name': doctor_name,
                    'document_language': detected_lang,
                    'text_sample': extracted_text[:100]
                }
            }
            
            return jsonify(response), 400

    except Exception as e:
        logger.error(f"Verification error: {str(e)}")
        return jsonify({'error': f'Verification failed: {str(e)}'}), 500

def get_tesseract_lang_code(language_preference):
    """Convert language name to tesseract language code"""
    language_codes = {
        'english': 'eng',
        'russian': 'rus',
        'arabic': 'ara',
        'french': 'fra',
    }
    return language_codes.get(language_preference.lower(), 'eng')

def verify_russian_document(doctor_name, extracted_text_lower, original_text):
    """
    Improved verification for Russian documents with or without OCR language support
    """
    try:
        # Try to transliterate the doctor's name to Cyrillic
        try:
            cyrillic_name = translit(doctor_name, 'ru').lower()
            logger.debug(f"Transliterated name to Cyrillic: {cyrillic_name}")
        except Exception as e:
            logger.error(f"Transliteration error: {str(e)}")
            cyrillic_name = doctor_name.lower()  # Fallback to original name
        
        # 1. Direct match of transliterated name
        if cyrillic_name in extracted_text_lower:
            logger.debug("Found exact transliterated name match")
            return True
            
        # 2. Check for name in original form (in case the document contains Latin characters)
        if doctor_name in extracted_text_lower:
            logger.debug("Found original name match")
            return True
            
        # 3. Check for name parts in Cyrillic (for documents with partial OCR success)
        name_parts = cyrillic_name.split()
        if len(name_parts) > 1:
            # For each name part, check if it appears in the text
            name_roots = [part[:min(len(part), 4)] for part in name_parts]  # First 4 chars are usually stable in Russian
            found_parts = []
            
            for root in name_roots:
                for word in extracted_text_lower.split():
                    if root in word:
                        found_parts.append(root)
                        break
                        
            name_parts_found = len(found_parts) == len(name_roots)
            if name_parts_found:
                logger.debug(f"Found all name parts in Russian text: {found_parts}")
                return True
                
        # 4. Check for name parts in original form
        original_name_parts = doctor_name.split()
        if len(original_name_parts) > 1:
            # Check if all parts are somewhere in the text
            all_parts_found = all(part.lower() in extracted_text_lower for part in original_name_parts)
            if all_parts_found:
                logger.debug("Found all original name parts in text")
                return True
                
        # 5. Check for document type indicators (medical diploma, certificate, etc.)
        document_indicators = [
            'диплом', 'врач', 'доктор', 'медицинский', 'медицина',
            'университет', 'институт', 'академия', 'сертификат',
            'специалист', 'квалификация'
        ]
        
        # Count how many medical indicators we found
        indicators_found = [ind for ind in document_indicators if ind in extracted_text_lower]
        
        logger.debug(f"Medical document indicators found: {len(indicators_found)}")
        
        # If we found strong medical document indicators and at least one name part
        if len(indicators_found) >= 3:
            # This is definitely a medical document, check if any name part appears
            any_name_part_found = any(part[:4] in extracted_text_lower for part in name_parts)
            any_original_part_found = any(part.lower() in extracted_text_lower for part in original_name_parts)
            
            if any_name_part_found or any_original_part_found:
                logger.debug("Found medical document with partial name match")
                return True
                
        return False
        
    except Exception as e:
        logger.error(f"Error in Russian document verification: {str(e)}")
        return False

# Keep the original function for backwards compatibility
def verify_russian_diploma(doctor_name, extracted_text_lower, original_text):
    """Alias for verify_russian_document"""
    return verify_russian_document(doctor_name, extracted_text_lower, original_text)

def check_tesseract_language(lang_code):
    """Check if a specific Tesseract language pack is available"""
    try:
        # Try a simple OCR with the language to check if it's available
        sample_image = Image.new('RGB', (10, 10), color='white')
        pytesseract.image_to_string(sample_image, lang=lang_code)
        return True
    except Exception as e:
        error_str = str(e).lower()
        if "failed loading language" in error_str or "couldn't load any languages" in error_str:
            return False
        # If it's another type of error, assume language is available
        return True

def get_language_install_instructions():
    """Get instructions for installing Tesseract language packs"""
    os_system = os.uname().sysname.lower() if hasattr(os, 'uname') else 'unknown'
    
    if 'darwin' in os_system:  # macOS
        return {
            "os_detected": "macOS",
            "instructions": [
                "Install Tesseract language data using Homebrew:",
                "brew install tesseract-lang",
                "Or for just Russian:",
                "brew install tesseract && sudo mkdir -p /opt/homebrew/share/tessdata && sudo wget -O /opt/homebrew/share/tessdata/rus.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata"
            ]
        }
    elif 'linux' in os_system:  # Linux
        return {
            "os_detected": "Linux",
            "instructions": [
                "For Ubuntu/Debian:",
                "sudo apt-get install tesseract-ocr-rus",
                "For other distributions, please check your package manager"
            ]
        }
    elif 'windows' in os_system:  # Windows
        return {
            "os_detected": "Windows",
            "instructions": [
                "Download the Russian language data file from: https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata",
                "Place it in the Tesseract tessdata directory (e.g., 'C:\\Program Files\\Tesseract-OCR\\tessdata\\')"
            ]
        }
    else:
        return {
            "instructions": [
                "Download the Russian language data file from: https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata",
                "Place it in your Tesseract tessdata directory and ensure TESSDATA_PREFIX environment variable is set correctly"
            ]
        }

# Improve the extraction functions
def extract_name(text):
    # Look for patterns that might indicate a name
    # Usually names appear at the beginning or after "Dr." or similar titles
    lines = text.split('\n')
    for line in lines:
        # Look for "Dr." or similar titles
        name_match = re.search(r'(?:Dr\.?|Doctor)\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)', line, re.IGNORECASE)
        if name_match:
            return name_match.group(1)
        
        # Look for capitalized words that might be names
        name_match = re.search(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)', line)
        if name_match:
            return name_match.group(1)
    return ""

def extract_email(text):
    # Implement logic to extract email from text
    # This is a placeholder and needs to be implemented based on the visit card format
    email_match = re.search(r'[\w\.-]+@[\w\.-]+', text)
    if email_match:
        return email_match.group(0)
    return "Extracted Email"

def extract_specialty(text):
    # Common medical specialties
    specialties = [
        'Cardiology', 'Dermatology', 'Neurology', 'Pediatrics', 'Oncology',
        'Orthopedics', 'Gynecology', 'Psychiatry', 'Surgery', 'Internal Medicine',
        # Add more specialties as needed
    ]
    
    lines = text.split('\n')
    for line in lines:
        # Check for known specialties
        for specialty in specialties:
            if specialty.lower() in line.lower():
                return line.strip()
        
        # Look for patterns that might indicate a specialty
        specialty_match = re.search(r'(?:Specialist|Consultant)\s+in\s+([A-Za-z\s]+)', line)
        if specialty_match:
            return specialty_match.group(1).strip()
    return ""

def extract_phone_number(text):
    # Basic pattern to match phone formats, can be refined
    phone_match = re.search(r'(\+?\d[\d\s\-]{7,}\d)', text)
    if phone_match:
        return phone_match.group(0).strip()
    return "Extracted Phone"

@app.route('/api/update-signature', methods=['POST'])
@token_required
def update_signature(user_id):
    try:
        data = request.get_json()
        signature = data.get('signature')

        if not signature:
            return jsonify({'error': 'No signature provided'}), 400

        result = doctors_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': {'signature': signature}}
        )

        if result.modified_count > 0:
            # Get updated doctor data
            doctor_data = doctors_collection.find_one({'_id': ObjectId(user_id)})
            return jsonify({
                'message': 'Signature updated successfully',
                'signature': doctor_data.get('signature')
            }), 200
        else:
            return jsonify({'error': 'Failed to update signature'}), 500

    except Exception as e:
        logger.error(f"Signature update error: {str(e)}")
        return jsonify({'error': f'Signature update failed: {str(e)}'}), 500

def detect_document_language(text):
    """Detect the language of a document based on text content"""
    # Count characters from different scripts
    russian_chars = set('абвгдеёжзийклмнопрстуфхцчшщъыьэюя')
    arabic_chars = set('ابتثجحخدذرزسشصضطظعغفقكلمنهوي')
    french_special_chars = set('àâçéèêëîïôùûüÿæœ')
    
    # Count characters
    russian_count = sum(1 for char in text.lower() if char in russian_chars)
    arabic_count = sum(1 for char in text if char in arabic_chars)
    french_count = sum(1 for char in text.lower() if char in french_special_chars)
    
    # Basic language detection by script
    if russian_count > 5:
        return 'russian'
    elif arabic_count > 5:
        return 'arabic'
    elif french_count > 3:  # French needs fewer special chars to detect
        return 'french'
    
    # If no distinctive script was found, try langdetect
    try:
        lang = detect(text)
        if lang == 'fr':
            return 'french'
        elif lang == 'ar':
            return 'arabic'
        elif lang == 'ru':
            return 'russian'
        elif lang == 'en':
            return 'english'
        else:
            logger.debug(f"Detected language code: {lang}")
            # Map other language codes as needed
            return 'unknown'
    except LangDetectException:
        # If detection fails, check for English content by counting English words
        english_word_pattern = r'\b[a-zA-Z]{3,}\b'
        english_words = re.findall(english_word_pattern, text)
        if len(english_words) > 5:  # If there are several English words
            return 'english'
        
    return 'unknown'

def get_language_code_for_comparison(language):
    """Get standardized language code for comparison"""
    language = language.lower()
    if language in ['russian', 'ru', 'rus']:
        return 'ru'
    elif language in ['arabic', 'ar', 'ara']:
        return 'ar'
    elif language in ['french', 'fr', 'fra']:
        return 'fr'
    elif language in ['english', 'en', 'eng']:
        return 'en'
    else:
        return language

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000, debug=True)
