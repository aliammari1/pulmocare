import bcrypt
from bson import ObjectId

class Doctor:
    def __init__(self, name, email, specialty, phone_number, address, password=None, _id=None):
        self._id = _id if _id else ObjectId()
        self.name = name
        self.email = email
        self.specialty = specialty
        self.phone_number = phone_number
        self.address = address
        self.password_hash = self.set_password(password) if password else None

    def set_password(self, password):
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode('utf-8'), salt)

    def check_password(self, password):
        return bcrypt.checkpw(password.encode('utf-8'), self.password_hash)

    def to_dict(self):
        return {
            'id': str(self._id),
            'name': self.name,
            'email': self.email,
            'specialty': self.specialty,
            'phone_number': self.phone_number,
            'address': self.address
        }

    @staticmethod
    def from_dict(data):
        return Doctor(
            name=data.get('name'),
            email=data.get('email'),
            specialty=data.get('specialty'),
            phone_number=data.get('phone_number'),
            address=data.get('address'),
            _id=ObjectId(data['_id']) if '_id' in data else None
        )
