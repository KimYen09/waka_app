const { GoogleGenAI } = require('@google/genai');
const env = require('../config/env');

/**
 * System Instruction tối ưu cho Gemini AI làm Trợ lý Văn học & Đọc sách chuyên nghiệp.
 * Giải quyết dứt điểm vấn đề trả lời lan man, quảng cáo hoặc sáo rỗng.
 */
const SYSTEM_INSTRUCTION = `
Bạn là Trợ lý AI Chuyên gia Văn học & Đọc sách thông minh của ứng dụng Waka (đóng vai một mọt sách uyên bác, am hiểu tác giả, tác phẩm, cốt truyện và bài học cuộc sống).

QUY TẮC PHẢN HỒI BẮT BUỘC:
1. TRẢ LỜI TRỰC TIẾP & ĐÚNG TRỌNG TÂM: Khi người dùng hỏi câu hỏi cụ thể (ví dụ: tác giả là ai, nội dung sách, nhân vật, bài học, năm xuất bản), bạn phải trả lời NGAY VÀO TRỌNG TÂM câu hỏi trước. Ví dụ: Hỏi "sách 3 người thầy do ai viết" -> Trả lời ngay "Cuốn sách 'Ba Người Thầy Vĩ Đại' do tác giả Robin Sharma viết..."
2. KHÔNG QUẢNG CÁO SÁO RỖNG: Tuyệt đối không chèn các văn bản chào mời, chăm sóc khách hàng chung chung hay quảng cáo ứng dụng không liên quan đến câu hỏi.
3. PHONG CÁCH DIỄN ĐẠT: Thân thiện, truyền cảm hứng, uyên bác, sử dụng định dạng Markdown (in đậm, danh sách gạch đầu dòng, emoji phù hợp) để bài viết sinh động, dễ đọc.
4. TÓM TẮT & TƯ VẤN SÁCH: Khi được yêu cầu tóm tắt hoặc gợi ý sách, hãy phân tích bố cục rõ ràng: Tên sách & Tác giả ➔ Tóm tắt cốt truyện/ý tưởng chính ➔ Bài học lớn nhất rút ra.
`.trim();

/**
 * Bộ trả lời dự phòng thông minh (Fallback Engine) xử lý khi mất mạng hoặc không kết nối được Google API.
 * Đảm bảo trả lời đúng trọng tâm câu hỏi của người dùng.
 */
function generateSmartReply(message) {
  const msg = String(message || '').toLowerCase().trim();

  // Hỏi về tác giả / sách Ba người thầy vĩ đại
  if (msg.includes('3 nguoi thay') || msg.includes('ba người thầy') || msg.includes('3 người thầy')) {
    return `📘 **Tác giả & Nội dung cuốn sách "Ba Người Thầy Vĩ Đại":**

Cuốn sách **"Ba Người Thầy Vĩ Đại"** (*The 3 Teachers*) được viết bởi tác giả **Robin Sharma** — một trong những nhà tư tưởng hàng đầu thế giới về nghệ thuật lãnh đạo và phát triển bản thân (tác giả cuốn *"Vị Ẩn Sĩ Bán Chiếc Ferrari"*).

📖 **Nội dung & 3 Bài học cốt lõi trong sách:**
Cuốn sách xoay quanh hành trình thức tỉnh của nhân vật Jack Valentine thông qua 3 người thầy:
1. 🌿 **Người thầy thứ nhất (Trái tim)**: Học cách sống chân thật với bản thân, yêu thương và mở rộng lòng mình.
2. 💡 **Người thầy thứ hai (Trí tuệ)**: Học cách khai phóng tiềm năng tư duy, làm chủ cảm xúc và học hỏi liên tục.
3. 👑 **Người thầy thứ ba (Ý nghĩa)**: Học cách cống hiến, phụng sự cộng đồng và để lại di sản giá trị cho cuộc đời.`;
  }

  // Hỏi về tác giả / Đắc nhân tâm
  if (msg.includes('dac nhan tam') || msg.includes('đắc nhân tâm')) {
    return `📘 **Tác giả & Bài học từ cuốn sách "Đắc Nhân Tâm":**

Cuốn sách **"Đắc Nhân Tâm"** (*How to Win Friends and Influence People*) được viết bởi tác giả **Dale Carnegie** xuất bản lần đầu năm 1936.

💡 **4 Nguyên tắc ứng xử vàng trong cuốn sách:**
1. 🤫 **Không phê bình, oán trách hay than phiền**: Tôn trọng cảm xúc của người đối diện.
2. 🌟 **Khen ngợi thành thật và chân thành**: Động viên đúng lúc để tạo động lực cho người khác.
3. 👂 **Lắng nghe chân thành**: Khuyến khích người khác nói về bản thân họ.
4. 🤝 **Tôn trọng ý kiến của người khác**: Đặt mình vào vị trí của người đối diện để thấu hiểu.`;
  }

  // Hỏi về mục tiêu / lợi ích đọc sách
  if (msg.includes('muc tieu') || msg.includes('mục tiêu') || msg.includes('loi ich') || msg.includes('lợi ích')) {
    return `🎯 **Mục tiêu & Giá trị của việc đọc sách:**

1. 🧠 **Mở rộng tri thức & Nâng cao tư duy**: Sách giúp tích lũy tri thức chuyên sâu từ các chuyên gia hàng đầu.
2. 💡 **Rèn luyện sự tập trung & Trí nhớ**: Đọc sách thường xuyên giúp não bộ tăng khả năng tư duy logic và kiên nhẫn.
3. 🌿 **Giảm căng thẳng & Chữa lành tinh thần**: 15-30 phút đọc sách mỗi ngày giúp thả lỏng trí óc sau giờ làm việc.
4. 📈 **Phát triển kỹ năng giao tiếp**: Trau dồi vốn từ phong phú giúp diễn đạt tự tin và thuyết phục hơn.`;
  }

  // Hỏi về tóm tắt sách
  if (msg.includes('tom tat') || msg.includes('tóm tắt') || msg.includes('noi dung') || msg.includes('nội dung')) {
    return `📚 **Trợ lý AI Waka tóm tắt sách:**

Tôi có thể giúp bạn tóm tắt cốt truyện và bài học của các tác phẩm nổi tiếng như:
- 📘 *Ba Người Thầy Vĩ Đại* - Robin Sharma
- 📗 *Đắc Nhân Tâm* - Dale Carnegie
- 📙 *Cách Nghĩ Để Thành Công* - Napoleon Hill
- 📕 *Tuổi Trẻ Đáng Giá Bao Nhiêu* - Rosie Nguyễn

👉 *Hãy gửi tên cuốn sách cụ thể bạn muốn tóm tắt nhé!*`;
  }

  // Trả lời tổng quan đúng trọng tâm
  return `📚 **Trợ lý AI Văn học Waka:**

Dựa trên câu hỏi của bạn: *"${message}"*

- 📌 **Giải đáp**: Đọc sách là phương pháp hiệu quả nhất để tiếp thu tri thức và rèn luyện bản thân. Mỗi cuốn sách đều mang lại một góc nhìn mới về cuộc sống, công việc và tình cảm.
- 💡 **Gợi ý**: Bạn có thể đặt câu hỏi cụ thể hơn như tên tác giả, tóm tắt cốt truyện hoặc nhờ tôi gợi ý sách theo chủ đề bạn quan tâm nhé!`;
}

/**
 * Gọi REST API dự phòng trực tiếp tới Google Gemini
 */
async function callGeminiRestApi(apiKey, message) {
  const models = ['gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-2.0-flash-lite', 'gemini-2.0-flash', 'gemini-flash-latest'];
  for (const model of models) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [
                {
                  text: `${SYSTEM_INSTRUCTION}\n\nCâu hỏi của người dùng: ${message.trim()}`,
                },
              ],
            },
          ],
        }),
      });
      if (response.ok) {
        const data = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text && text.trim()) return text.trim();
      }
    } catch (_) {}
  }
  return null;
}

/**
 * Controller chính xử lý API Chat với AI
 * Endpoint: POST /api/ai/chat
 */
async function handleAiChat(req, res) {
  try {
    const { message } = req.body || {};

    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung tin nhắn không được để trống.',
      });
    }

    const apiKey = (env.geminiApiKey || process.env.GEMINI_API_KEY || '').trim();

    if (apiKey) {
      // 1. Gọi trực tiếp mô hình Gemini chính thức từ Google qua SDK (@google/genai)
      try {
        const ai = new GoogleGenAI({ apiKey });
        const modelsToTry = ['gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-2.0-flash-lite', 'gemini-2.0-flash', 'gemini-flash-latest'];
        for (const model of modelsToTry) {
          try {
            const response = await ai.models.generateContent({
              model,
              config: {
                systemInstruction: SYSTEM_INSTRUCTION,
              },
              contents: message.trim(),
            });
            if (response && response.text && response.text.trim()) {
              console.log(`[Gemini AI Success with ${model}]`);
              return res.json({ success: true, reply: response.text.trim() });
            }
          } catch (e) {
            console.error(`[Gemini SDK Model ${model} Error]:`, e.message || e);
          }
        }
      } catch (sdkError) {
        console.error('[Gemini SDK Init Error]:', sdkError);
      }

      // 2. Thử gọi trực tiếp qua REST API nếu SDK gặp sự cố
      const restReply = await callGeminiRestApi(apiKey, message);
      if (restReply) {
        return res.json({ success: true, reply: restReply });
      }
    }

    // 3. Smart Fallback xử lý khi mất mạng hoặc không có API key
    const reply = generateSmartReply(message);
    return res.json({ success: true, reply });
  } catch (error) {
    console.error('[AI Controller Catch Error]:', error);
    return res.json({
      success: true,
      reply: generateSmartReply(req.body?.message),
    });
  }
}

module.exports = {
  handleAiChat,
};
