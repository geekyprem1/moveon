const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * secure chatCompletions HTTPS Callable Function (v2)
 * Calls OpenRouter DeepSeek V4 Flash with user context, chat history, and rate limiting.
 */
exports.chatCompletions = onCall({ cors: true }, async (request) => {
  // 1. Authenticate user
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to call Break Coach.");
  }

  const userId = request.auth.uid;
  const { message, sessionId, context, history } = request.data || {};

  if (!message || !sessionId || !context) {
    throw new HttpsError("invalid-argument", "Missing required fields: message, sessionId, or context.");
  }

  // Calculate daily limit
  const dateStr = new Date().toISOString().split("T")[0]; // yyyy-MM-dd UTC
  const limitDocRef = db.collection("coach_usage").doc(`${userId}_${dateStr}`);

  try {
    // 2. Check current usage limits
    const usageDoc = await limitDocRef.get();
    let messagesToday = 0;
    let totalMessages = 0;

    if (usageDoc.exists) {
      messagesToday = usageDoc.data().messagesToday || 0;
      totalMessages = usageDoc.data().totalMessages || 0;
    }

    if (messagesToday >= 20) {
      throw new HttpsError(
        "resource-exhausted",
        "You have reached your daily limit of 20 messages. Take some time to reflect and try again tomorrow."
      );
    }

    // 3. Resolve API Key
    const apiKey = process.env.OPENROUTER_API_KEY;
    if (!apiKey) {
      console.error("OPENROUTER_API_KEY environment variable is not set.");
      throw new HttpsError("internal", "API service configuration error.");
    }

    // 4. Construct System Prompt & Context Injection
    const systemPrompt = `You are "Break Coach", a premium, warm, emotionally intelligent AI breakup recovery companion for the app "Move On".
Your tagline is: "A calm voice when emotions get loud."
Your goal is to help the user recover from their breakup, maintain No Contact, handle urges to message their ex, reduce overthinking, process heavy emotions, and build emotional resilience.

Use the user's current context naturally in the conversation without revealing the raw JSON data:
- No-contact streak: ${context.daysNoContact} days
- Current recovery stage: ${context.recoveryStage}
- Recovery score: ${context.recoveryScore}%
- Recent mood: ${context.currentMood}
- Longest streak: ${context.longestStreak} days
- Tasks completed: ${context.healingTasksCompleted}
- Journals written: ${context.totalJournalEntries}

Core Guidelines:
1. Warmth & CBT: Speak in a warm, grounded, non-judgmental tone. Validate their feelings using Cognitive Behavioral Therapy (CBT) and Motivational Interviewing techniques.
2. Direct and Concise: Keep responses short and digestible (100-250 words, maximum 2-3 small paragraphs). Avoid massive walls of text or bullet-point dumps.
3. Keep them safe: 
   - Never encourage contacting their ex or breaking No Contact. Help them pause and reflect.
   - Never encourage revenge, stalking, or checking their ex's social media.
   - You are a companion, not a licensed therapist or medical doctor. Do not diagnose conditions or make clinical claims.
4. Active SOS Handling: If the user indicates they want to text/call/stalk their ex (SOS trigger), immediately prioritize No Contact. Guide them through a grounding breath, remind them of their streak, suggest writing an unsent letter in their journal, or choosing an alternative action (walk, water, mindfulness).
5. Open Dialog: Always end with a gentle, open-ended question to help them reflect further.`;

    // Compile message history
    const apiMessages = [{ role: "system", content: systemPrompt }];

    // Append last 10 messages from history if available
    if (Array.isArray(history)) {
      const trimmedHistory = history.slice(-10);
      trimmedHistory.forEach((msg) => {
        if (msg.role && msg.content) {
          apiMessages.push({ role: msg.role, content: msg.content });
        }
      });
    }

    // Add current user prompt
    apiMessages.push({ role: "user", content: message });

    // 5. Call OpenRouter
    const openRouterUrl = "https://openrouter.ai/api/v1/chat/completions";
    const apiResponse = await fetch(openRouterUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://moveon.app",
        "X-Title": "Move On App",
      },
      body: JSON.stringify({
        model: "deepseek/deepseek-v4-flash",
        messages: apiMessages,
        temperature: 0.7,
        max_tokens: 450,
      }),
    });

    if (!apiResponse.ok) {
      const errorText = await apiResponse.text();
      console.error(`OpenRouter API error (Status ${apiResponse.status}): ${errorText}`);
      throw new HttpsError("unavailable", "The AI companion is temporarily unresponsive. Please try again in a moment.");
    }

    const responseData = await apiResponse.json();
    const assistantReply =
      responseData.choices &&
      responseData.choices[0] &&
      responseData.choices[0].message &&
      responseData.choices[0].message.content;

    if (!assistantReply) {
      console.error("OpenRouter returned empty choices: ", JSON.stringify(responseData));
      throw new HttpsError("internal", "Invalid response from AI model.");
    }

    // 6. Write transaction to update usage and log session chats
    const batch = db.batch();

    // Increment usage document
    batch.set(
      limitDocRef,
      {
        userId,
        date: dateStr,
        messagesToday: messagesToday + 1,
        totalMessages: totalMessages + 1,
        lastActiveDate: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Save User message
    const userChatRef = db.collection("coach_chats").doc();
    batch.set(userChatRef, {
      id: userChatRef.id,
      sessionId,
      userId,
      role: "user",
      content: message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isSos: message.toLowerCase().includes("text") || message.toLowerCase().includes("contact") || message.toLowerCase().includes("ex"),
    });

    // Save Assistant message
    const assistantChatRef = db.collection("coach_chats").doc();
    batch.set(assistantChatRef, {
      id: assistantChatRef.id,
      sessionId,
      userId,
      role: "assistant",
      content: assistantReply,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isSos: false,
    });

    await batch.commit();

    // 7. Return assistant message to client
    return {
      content: assistantReply,
      messagesRemaining: 20 - (messagesToday + 1),
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("Unhandled error in chatCompletions:", error);
    throw new HttpsError("internal", "An unexpected error occurred. Please try again.");
  }
});
