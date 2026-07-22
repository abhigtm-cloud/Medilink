import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";

const EMERGENCY_KEYWORDS = [
  "chest pain",
  "can't breathe",
  "cant breathe",
  "cannot breathe",
  "difficulty breathing",
  "severe bleeding",
  "heavy bleeding",
  "stroke",
  "unconscious",
  "unresponsive",
  "not breathing",
  "seizure",
  "heart attack",
];

function detectEmergency(text: string): boolean {
  const lower = text.toLowerCase();
  return EMERGENCY_KEYWORDS.some((kw) => lower.includes(kw));
}

type AiCapability =
  | "symptomChecker"
  | "healthTips"
  | "reportExplanation"
  | "diseaseRiskAnalysis"
  | "doctorRecommendation";

const DISCLAIMER =
  "This is general guidance only — please consult a licensed doctor for diagnosis or treatment.";

/**
 * Rule-based stand-in for a real LLM — mirrors the
 * lib/features/ai_assistant `AiProviderDataSource` interface server-side,
 * so swapping in a real provider later (OpenAI/Anthropic) is a change in
 * exactly one function, not the client. No live API key exists yet. See
 * architecture doc §11.
 */
function ruleBasedResponse(userMessage: string, capability: AiCapability): string {
  const lower = userMessage.toLowerCase();

  if (capability === "symptomChecker") {
    if (lower.includes("fever")) {
      return (
        "A fever can have many causes, from common infections to more serious " +
        "conditions. Rest, stay hydrated, and monitor your temperature. See a " +
        `doctor if it lasts more than 3 days or exceeds 39.5°C (103°F). ${DISCLAIMER}`
      );
    }
    if (lower.includes("headache")) {
      return (
        "Headaches are usually caused by stress, dehydration, or lack of sleep. " +
        "Try resting in a dark, quiet room and drinking water. Seek care " +
        `immediately if it's sudden and severe, or comes with vision changes or confusion. ${DISCLAIMER}`
      );
    }
    if (lower.includes("cough") || lower.includes("cold")) {
      return (
        "Coughs and colds are usually viral and resolve on their own within a " +
        "week or two. Rest and fluids help. See a doctor if it persists beyond " +
        `10 days or you develop a high fever. ${DISCLAIMER}`
      );
    }
    return (
      "Thanks for sharing your symptoms. I'd recommend booking an appointment " +
      `with a general physician so they can examine you properly. ${DISCLAIMER}`
    );
  }

  if (capability === "doctorRecommendation") {
    return (
      "Based on what you've described, a General Physician is a good starting " +
      `point — they can refer you to a specialist if needed. You can book one from the Home screen. ${DISCLAIMER}`
    );
  }

  if (capability === "reportExplanation") {
    return (
      "I can offer general context about common report terms, but a full " +
      `interpretation needs a licensed doctor who knows your medical history. ${DISCLAIMER}`
    );
  }

  if (capability === "diseaseRiskAnalysis") {
    return (
      "General risk factors include diet, activity level, sleep, and family " +
      `history. For a personalized risk assessment, please consult a doctor. ${DISCLAIMER}`
    );
  }

  return `I'm here to help with general health questions. ${DISCLAIMER}`;
}

/**
 * Runs server-side (never ships the prompt/logic in the client binary) even
 * though there's no real LLM key yet — the keyword pre-filter/urgency
 * short-circuit below is enforced identically whether or not a real
 * provider is ever wired in. The client already wrote its own "user"
 * message directly to Firestore (allowed by rules); this call generates
 * and writes only the assistant's reply.
 */
export const sendAiMessage = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  const uid = context.auth.uid;
  const chatId = data.chatId as string;
  const userMessage = (data.message as string)?.trim();
  const capability = (data.capability as AiCapability) ?? "symptomChecker";
  if (!chatId || !userMessage) {
    throw new functionsV1.https.HttpsError("invalid-argument", "chatId and message are required");
  }

  const chatRef = db.collection("ai_chats").doc(chatId);
  const chatSnap = await chatRef.get();
  if (!chatSnap.exists || chatSnap.data()?.patientUid !== uid) {
    throw new functionsV1.https.HttpsError("permission-denied", "Not your chat");
  }

  const urgencyFlag = detectEmergency(userMessage);
  const replyContent = urgencyFlag
    ? "This sounds like it may be a medical emergency. Please use the Emergency SOS button now, or call your local emergency number immediately."
    : ruleBasedResponse(userMessage, capability);

  await chatRef.collection("messages").add({
    role: "assistant",
    content: replyContent,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: { urgencyFlag, capability },
  });

  await chatRef.set(
    {
      lastMessagePreview: replyContent.slice(0, 120),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { reply: replyContent, urgencyFlag };
});
