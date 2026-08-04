const { GoogleGenAI } = require('@google/genai');
const env = require('../config/env');

/**
 * Controller xử lý chat với Gemini AI cho ứng dụng Waka
 * Endpoint: POST /api/ai/chat
 * Body: { message: "..." }
 * Return: { success: true, reply: "..." }
 */
async function handleAiChat(req, res, next) {
  try {
    const { message } = req.body || {};

    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung tin nhắn không được để trống.',
      });
    }

    const apiKey = env.geminiApiKey || process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({
        success: false,
        reply: 'Chưa cấu hình GEMINI_API_KEY ở file .env của máy chủ backend.',
      });
    }

    const ai = new GoogleGenAI({ apiKey });

    // Gọi Gemini model với system instruction chuẩn Waka Assistant
    const modelsToTry = ['gemini-3.6-flash', 'gemini-2.0-flash', 'gemini-flash-latest'];
    let responseText = '';
    let lastError = null;

    for (const model of modelsToTry) {
      try {
        const response = await ai.models.generateContent({
          model,
          config: {
            systemInstruction:
              'Bạn là Trợ lý AI của ứng dụng Waka (đọc sách, nghe sách nói, ebook, truyện tranh). ' +
              'Hãy gợi ý sách, tóm tắt nội dung, phân tích bài học từ sách hoặc tư vấn đọc sách phù hợp với người dùng. ' +
              'Trả lời bằng tiếng Việt thân thiện, rõ ràng, giàu thông tin và sử dụng định dạng Markdown khi thích hợp.',
          },
          contents: message.trim(),
        });
        if (response && response.text) {
          responseText = response.text;
          break;
        }
      } catch (err) {
        lastError = err;
      }
    }

    const reply = responseText || (lastError ? `Lỗi kết nối AI (${lastError.message})` : 'Xin lỗi, hiện tại tôi chưa thể đưa ra câu trả lời.');

    return res.json({
      success: true,
      reply,
    });
  } catch (error) {
    console.error('[Gemini AI Controller Error]:', error);
    return res.status(500).json({
      success: false,
      reply: 'Có lỗi xảy ra khi xử lý yêu cầu AI: ' + (error.message || 'Không xác định'),
    });
  }
}

module.exports = {
  handleAiChat,
};
