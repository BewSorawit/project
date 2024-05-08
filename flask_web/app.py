from flask import Flask, request, jsonify
import numpy as np
import librosa as lb
from keras.models import load_model

app = Flask(__name__)

# Load the trained model
model = load_model('audio_classification_model.h5')

# Define classes
classes = ['air_conditioner', 'car_horn', 'children_playing', 'dog_bark', 'drilling',
           'engine_idling', 'gun_shot', 'jackhammer', 'siren', 'street_music']

# Function to extract features from audio file
def feature_extractor(path):
    data, sample_rate = lb.load(path)
    data = lb.feature.mfcc(y=data, sr=sample_rate, n_mfcc=128)
    data = np.mean(data, axis=1)
    return data

# Function to preprocess the audio file and make prediction
def predict_audio(path):
    # Extract features from audio file
    audio_features = feature_extractor(path)
    # Reshape the features
    audio_features = audio_features.reshape(1, -1)
    # Make prediction
    prediction = model.predict(audio_features)
    # Get the predicted class
    predicted_class_index = np.argmax(prediction)
    predicted_class = classes[predicted_class_index]
    
    print("Predicted class index:", predicted_class_index)
    print("Predicted class:", predicted_class)
    return predicted_class

@app.route('/hello',methods=['GET'])
def index():
    return jsonify({'message': 'Hello, Flask!'}), 200

@app.route('/predict', methods=['POST'])
def predict():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    
    print(request.files)
    audio_file = request.files['audio']
    
    # Save the audio file
    audio_path = 'uploaded_audio.wav'
    audio_file.save(audio_path)
    
    # Make prediction
    predicted_class = predict_audio(audio_path)
    
    return jsonify({'predicted_class': predicted_class}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
