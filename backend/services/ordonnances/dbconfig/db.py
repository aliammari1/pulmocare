from pymongo import MongoClient
import os

def get_database():
    client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://admin:admin@localhost:27017/'))
    return client['medapp']
