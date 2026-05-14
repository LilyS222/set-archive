import OpenAI from "npm:openai@4.56.0";
import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.21.0";

// AI_PROVIDER = "openai" | "gemini"  (default: "openai")
const PROVIDER = Deno.env.get("AI_PROVIDER") ?? "gemini";

const SYSTEM_PROMPT = `당신은 수집된 콘텐츠를 정확하게 분류하는 AI입니다.

분류 가능한 카테고리:
- 패션: 의류, 신발, 악세서리, 코디, 패션 브랜드
- 카페·맛집: 카페, 레스토랑, 음식, 요리, 음료
- 공부·자기계발: 학습 자료, 책 요약, 강의, 스킬 개발, 뉴스레터
- 여행: 여행지, 숙소, 항공, 여행 팁, 현지 정보
- 인테리어: 인테리어, 가구, 소품, 홈데코, 건축
- 미분류함: 위 카테고리에 명확히 속하지 않거나 확신이 없을 때

반드시 아래 JSON 형식만 출력하세요. 다른 텍스트는 절대 추가하지 마세요:
{
  "category": "카테고리명",
  "confidence": 0.0,
  "summary": "첫 번째 핵심 내용\\n두 번째 핵심 내용\\n세 번째 핵심 내용",
  "suggestedTags": ["태그1", "태그2"]
}

규칙:
- confidence가 0.7 미만이면 category를 반드시 "미분류함"으로 설정
- summary는 개행(\\n)으로 구분된 3줄, 각 줄 20자 이내
- suggestedTags는 2~4개의 짧은 한국어 태그`;

interface ClassifyRequest {
  url?: string;
  text?: string;
  imageBase64?: string;
}

interface ClassifyResponse {
  category: string;
  confidence: number;
  summary: string;
  suggestedTags: string[];
}

const fallback: ClassifyResponse = {
  category: "미분류함",
  confidence: 0,
  summary: "분류를 완료하지 못했어요\nAI 매직박스에서 확인해주세요\n나중에 다시 시도할게요",
  suggestedTags: [],
};

// ── Provider implementations ──────────────────────────────────────

async function classifyWithOpenAI(userText: string, imageBase64?: string): Promise<string> {
  const client = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

  type ContentPart =
    | { type: "text"; text: string }
    | { type: "image_url"; image_url: { url: string } };

  const content: ContentPart[] = [];
  if (imageBase64) {
    content.push({ type: "image_url", image_url: { url: `data:image/jpeg;base64,${imageBase64}` } });
  }
  content.push({ type: "text", text: userText });

  const res = await client.chat.completions.create({
    model: "gpt-4o-mini",
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content },
    ],
    max_tokens: 512,
  });
  return res.choices[0].message.content ?? "";
}

async function classifyWithGemini(userText: string, imageBase64?: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY") ?? "");
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  type Part = { text: string } | { inlineData: { mimeType: string; data: string } };
  const parts: Part[] = [];
  if (imageBase64) {
    parts.push({ inlineData: { mimeType: "image/jpeg", data: imageBase64 } });
  }
  parts.push({ text: SYSTEM_PROMPT + "\n\n" + userText });

  const res = await model.generateContent(parts);
  return res.response.text();
}

// ── Main handler ──────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return new Response("Unauthorized", { status: 401 });

  let body: ClassifyRequest;
  try { body = await req.json(); }
  catch { return json(fallback, 400); }

  const { url, text, imageBase64 } = body;
  const userText = [url && `URL: ${url}`, text && `본문:\n${text.slice(0, 2000)}`]
    .filter(Boolean).join("\n\n") || "내용 없음";

  try {
    const raw = PROVIDER === "gemini"
      ? await classifyWithGemini(userText, imageBase64)
      : await classifyWithOpenAI(userText, imageBase64);

    // Gemini가 markdown 코드블록으로 감쌀 수 있어서 파싱 전에 제거
    const cleaned = raw.replace(/```json\n?|\n?```/g, "").trim();
    const result = JSON.parse(cleaned) as ClassifyResponse;
    if (result.confidence < 0.7) result.category = "미분류함";

    return json(result);
  } catch (err) {
    console.error(`[${PROVIDER}] classify error:`, err);
    return json(fallback);
  }
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
