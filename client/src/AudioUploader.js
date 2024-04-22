// AudioUpload.js
import React, { useState } from 'react';
import axios from 'axios'; // ติดตั้ง axios ถ้ายังไม่ได้ทำ

const AudioUploader = () => {
  const [selectedFile, setSelectedFile] = useState(null);

  const handleFileChange = (e) => {
    setSelectedFile(e.target.files[0]);
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    const formData = new FormData();
    formData.append('audioFile', selectedFile);

    try {
      await axios.post('http://localhost:3001/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      alert('File uploaded successfully');
    } catch (error) {
      console.error('Error uploading file: ', error);
      alert('Failed to upload file');
    }
  };

  return (
    <div>
      <input type="file" accept="audio/wav" onChange={handleFileChange} />
      <button onClick={handleUpload}>Upload</button>
    </div>
  );
};

export default AudioUploader;
