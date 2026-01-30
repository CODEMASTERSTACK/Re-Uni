// Root /api handler – so visiting the deployment URL shows this instead of 404
module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.status(200).json({
    message: 'UniDate API',
    endpoints: [
      'POST /api/get-custom-token',
      'POST /api/send-verification-otp',
      'POST /api/verify-university-email',
      'POST /api/get-upload-url',
    ],
  });
};
