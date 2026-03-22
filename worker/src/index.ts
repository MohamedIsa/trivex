/**
 * Trivex Worker — Cloudflare Workers backend
 * POST /generate  → calls Workers AI, validates response, returns trivia questions (WORKER-003)
 */

export interface Env {
  AI: Ai;
  LLM_MODEL?: string;
}

interface Question {
  id: string;
  question: string;
  options: [string, string, string, string];
  correctIndex: 0 | 1 | 2 | 3;
  explanation: string;
  timeLimit: number;
}

interface GenerateRequest {
  topic: string;
  difficulty: 'easy' | 'medium' | 'hard';
  count: number;
  language?: 'en' | 'ar';
  excludeQuestions?: string[];
}

interface GenerateResponse {
  questions: Question[];
}

interface ErrorResponse {
  error: string;
  retryable: boolean;
}

// Workers AI chat response shape
interface WorkersAIResponse {
  response: string;
}

// ---------------------------------------------------------------------------
// CORS helpers
// ---------------------------------------------------------------------------

const CORS_HEADERS: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function corsResponse(body: string, status: number, extraHeaders?: HeadersInit): Response {
  return new Response(body, {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
      ...extraHeaders,
    },
  });
}

function errorResponse(error: string, retryable: boolean, status: number): Response {
  const body: ErrorResponse = { error, retryable };
  return corsResponse(JSON.stringify(body), status);
}

// ---------------------------------------------------------------------------
// Difficulty wording — influences the user prompt sent to the LLM
// ---------------------------------------------------------------------------

function difficultyWording(difficulty: 'easy' | 'medium' | 'hard'): string {
  switch (difficulty) {
    case 'easy':
      return 'straightforward and suitable for general audiences';
    case 'medium':
      return 'moderately challenging and suitable for people with some knowledge of the subject';
    case 'hard':
      return 'obscure, nuanced, and suitable only for experts or enthusiasts';
  }
}

// ---------------------------------------------------------------------------
// Prompt builders
// ---------------------------------------------------------------------------

function buildSystemPrompt(language: 'en' | 'ar'): string {
  const base =
    'You are a trivia question generator. ' +
    'You MUST return ONLY a raw JSON object — absolutely no markdown code fences, no backticks, no prose, no commentary. ' +
    'Your entire response must be valid JSON that can be passed directly to JSON.parse().';

  if (language === 'ar') {
    return (
      base +
      ' Generate the question text, all 4 options, and the explanation entirely in Modern Standard Arabic (فصحى). ' +
      'Numbers (correctIndex, timeLimit) must remain integers — do not translate them.'
    );
  }
  return base;
}

function buildUserPrompt(
  topic: string,
  difficulty: 'easy' | 'medium' | 'hard',
  count: number,
  language: 'en' | 'ar',
  excludeQuestions: string[] = [],
): string {
  const langInstruction =
    language === 'ar'
      ? 'Write the question, options, and explanation in Modern Standard Arabic (فصحى). '
      : '';

  let exclusionBlock = '';
  if (excludeQuestions.length > 0) {
    const capped = excludeQuestions.slice(0, 50);
    const bullets = capped.map((q) => `- ${q}`).join('\n');
    exclusionBlock =
      '\n\nDo NOT generate any of the following questions that have already been asked:\n' +
      bullets +
      '\n';
  }

  return (
    `Generate ${count} trivia questions about "${topic}" at ${difficulty} difficulty ` +
    `(${difficultyWording(difficulty)}). ` +
    langInstruction +
    'Return a JSON object with this exact shape:\n' +
    '{\n' +
    '  "questions": [\n' +
    '    {\n' +
    '      "id": "1",\n' +
    '      "question": "What is the capital of France?",\n' +
    '      "options": ["Paris", "London", "Berlin", "Madrid"],\n' +
    '      "correctIndex": 0,\n' +
    '      "explanation": "Paris has been the capital of France since the 10th century.",\n' +
    '      "timeLimit": 15\n' +
    '    }\n' +
    '  ]\n' +
    '}\n' +
    'Rules:\n' +
    '- Each option must be a complete, meaningful answer — never a single letter, never "A", "B", "C", or "D"\n' +
    '- WRONG: "options": ["A", "B", "C", "D"] — RIGHT: "options": ["Paris", "London", "Berlin", "Madrid"]\n' +
    '- options must be an array of exactly 4 non-empty strings containing full answer text\n' +
    '- correctIndex must be an integer 0, 1, 2, or 3 pointing to the correct option\n' +
    '- explanation must be a non-empty string explaining why the answer is correct\n' +
    '- id must be a string ("1", "2", …)\n' +
    '- timeLimit must be an integer between 10 and 30 representing how many seconds a player needs to answer this question fairly\n' +
    `- Generate exactly ${count} questions` +
    exclusionBlock
  );
}

// ---------------------------------------------------------------------------
// Workers AI call
// ---------------------------------------------------------------------------

async function callWorkersAI(
  env: Env,
  model: string,
  topic: string,
  difficulty: 'easy' | 'medium' | 'hard',
  count: number,
  language: 'en' | 'ar',
  excludeQuestions: string[] = [],
): Promise<Question[]> {
  let aiResponse: unknown;
  try {
    aiResponse = await env.AI.run(model as Parameters<Ai['run']>[0], {
      messages: [
        { role: 'system', content: buildSystemPrompt(language) },
        { role: 'user', content: buildUserPrompt(topic, difficulty, count, language, excludeQuestions) },
      ],
      max_tokens: 4096,
      response_format: { type: 'json_object' },
    });
  } catch (e) {
    throw new LLMError(`Workers AI runtime error: ${e instanceof Error ? e.message : String(e)}`, 502);
  }

  const content = (aiResponse as WorkersAIResponse)?.response;

  if (!content || typeof content !== 'string') {
    throw new LLMError('Empty or unexpected response from Workers AI', 502);
  }

  // Attempt direct JSON.parse; fall back to stripping markdown fences
  let parsed: { questions: Question[] };
  try {
    parsed = JSON.parse(content) as { questions: Question[] };
  } catch {
    const cleaned = content
      .replace(/^```(?:json)?\s*/i, '')
      .replace(/\s*```\s*$/, '')
      .trim();
    parsed = JSON.parse(cleaned) as { questions: Question[] };
  }
  return parsed.questions;
}

// ---------------------------------------------------------------------------
// Custom error type so handlers can tell LLM failures apart from others
// ---------------------------------------------------------------------------

class LLMError extends Error {
  constructor(
    message: string,
    public readonly statusCode: number,
  ) {
    super(message);
    this.name = 'LLMError';
  }
}

// ---------------------------------------------------------------------------
// Validation type guard (WORKER-003)
// ---------------------------------------------------------------------------

function isValidQuestion(q: unknown): q is Question {
  if (typeof q !== 'object' || q === null) return false;
  const obj = q as Record<string, unknown>;
  if (typeof obj['id'] !== 'string') return false;
  if (typeof obj['question'] !== 'string' || obj['question'].trim() === '') return false;
  if (
    !Array.isArray(obj['options']) ||
    obj['options'].length !== 4 ||
    !(obj['options'] as unknown[]).every((o) => typeof o === 'string' && (o as string).trim() !== '')
  )
    return false;

  // Reject single-character options or bare A/B/C/D labels (BUG-011)
  const labelPattern = /^[A-D]\.?$/;
  if (
    (obj['options'] as string[]).some((o) => o.trim().length <= 1 || labelPattern.test(o.trim()))
  )
    return false;
  if (
    typeof obj['correctIndex'] !== 'number' ||
    !Number.isInteger(obj['correctIndex']) ||
    (obj['correctIndex'] as number) < 0 ||
    (obj['correctIndex'] as number) > 3
  )
    return false;
  if (typeof obj['explanation'] !== 'string' || obj['explanation'].trim() === '') return false;

  // timeLimit: default to 15 if missing or out of range (10–30)
  const rawLimit = obj['timeLimit'];
  if (typeof rawLimit !== 'number' || !Number.isInteger(rawLimit) || rawLimit < 10 || rawLimit > 30) {
    (obj as Record<string, unknown>)['timeLimit'] = 15;
  }

  return true;
}

// ---------------------------------------------------------------------------
// 5-second timeout helper (WORKER-003)
// ---------------------------------------------------------------------------

function withTimeout<T>(promise: Promise<T>, ms: number, timeoutError: Error): Promise<T> {
  const timer = new Promise<never>((_, reject) =>
    setTimeout(() => reject(timeoutError), ms),
  );
  return Promise.race([promise, timer]);
}

// ---------------------------------------------------------------------------
// Main fetch handler
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // ── CORS preflight ──────────────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── Route: POST /generate ───────────────────────────────────────────────
    if (url.pathname === '/generate' && request.method === 'POST') {
      return handleGenerate(request, env);
    }

    // ── 404 for everything else ─────────────────────────────────────────────
    return errorResponse('Not found', false, 404);
  },
};

// ---------------------------------------------------------------------------
// /generate handler
// ---------------------------------------------------------------------------

async function handleGenerate(request: Request, env: Env): Promise<Response> {
  try {
    // ── Parse + validate request body ───────────────────────────────────────
    let body: GenerateRequest;
    try {
      body = (await request.json()) as GenerateRequest;
    } catch {
      return errorResponse('Invalid JSON in request body', false, 400);
    }

    const { topic, difficulty, count } = body;

    if (!topic || typeof topic !== 'string' || topic.trim() === '') {
      return errorResponse('Missing or empty "topic" field', false, 400);
    }

    const validDifficulties = ['easy', 'medium', 'hard'];
    const normalizedDifficulty =
      typeof difficulty === 'string' && validDifficulties.includes(difficulty.toLowerCase())
        ? (difficulty.toLowerCase() as 'easy' | 'medium' | 'hard')
        : 'medium';

    // Cap count between 1 and 20 server-side
    const safeCount = Math.min(Math.max(1, Number(count) || 10), 20);

    // ── Validate + normalize language ─────────────────────────────────────
    const language: 'en' | 'ar' =
      typeof body.language === 'string' && body.language === 'ar' ? 'ar' : 'en';

    // ── Validate + cap excludeQuestions ──────────────────────────────────
    const rawExclude = Array.isArray(body.excludeQuestions) ? body.excludeQuestions : [];
    const excludeQuestions: string[] = rawExclude
      .filter((q: unknown): q is string => typeof q === 'string' && q.trim() !== '')
      .slice(0, 50);

    // ── Call Workers AI with 30s timeout ─────────────────────────────────
    const model = env.LLM_MODEL ?? '@cf/meta/llama-3.1-8b-instruct-fast';
    const timeoutError = new LLMError('LLM API timeout', 504);
    const questions = await withTimeout(
      callWorkersAI(env, model, topic.trim(), normalizedDifficulty, safeCount, language, excludeQuestions),
      30000,
      timeoutError,
    );

    // ── Validate response shape (WORKER-003) ────────────────────────────────
    if (!Array.isArray(questions) || questions.length !== safeCount || !questions.every(isValidQuestion)) {
      return errorResponse('Invalid question format from LLM', true, 422);
    }

    const responseBody: GenerateResponse = { questions };
    return corsResponse(JSON.stringify(responseBody), 200);
  } catch (err) {
    // Never let an unhandled error escape as a naked 500
    if (err instanceof LLMError) {
      if (err.statusCode === 504) {
        return errorResponse('LLM API timeout', true, 504);
      }
      return errorResponse('LLM API unavailable', true, 502);
    }
    const message = err instanceof Error ? err.message : 'Unexpected server error';
    return errorResponse(message, true, 500);
  }
}

