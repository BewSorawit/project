import React, { useState } from 'react';
import axios from 'axios';

const App = () => {
  const [selectedFile, setSelectedFile] = useState(null);

  const onFileChange = event => {
    setSelectedFile(event.target.files[0]);
  };

  const onFileUpload = () => {
    const formData = new FormData();
    formData.append('audio', selectedFile);

    axios.post('http://localhost:3001/upload', formData)
      .then(response => {
        console.log('File uploaded successfully');
      })
      .catch(error => {
        console.error('Error uploading file: ', error);
      });
  };

  return (
    <div>
      <h1>Upload WAV File</h1>
      <input type="file" onChange={onFileChange} />
      <button onClick={onFileUpload}>Upload!</button>
    </div>
  );
};

export default App;
