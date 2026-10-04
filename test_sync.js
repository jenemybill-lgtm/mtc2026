const axios = require('axios');

async function testSync() {
  const baseURL = 'https://mtc-m9in.onrender.com';

  try {
    console.log("Logging in...");
    const loginRes = await axios.post(`${baseURL}/api/auth/login`, {
      companyName: 'test',
      password: 'test'
    });

    const token = loginRes.data.token;
    console.log("Token:", token.substring(0, 10) + "...");

    console.log("Downloading current data...");
    const dlRes = await axios.get(`${baseURL}/api/sync/download`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log("Downloaded keys:", Object.keys(dlRes.data));

  } catch (err) {
    if (err.response) {
      console.error("Error:", err.response.status, err.response.data);
    } else {
      console.error("Error:", err.message);
    }
  }
}

testSync();
