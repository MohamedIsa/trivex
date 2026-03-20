/**
 * Trivex Worker — Cloudflare Workers backend
 * POST /generate  → returns 10 trivia questions (stub for WORKER-001)
 */

export interface Env {
  OPENAI_API_KEY: string;
  LLM_MODEL?: string;
}

interface Question {
  id: string;
  question: string;
  options: [string, string, string, string];
  correctIndex: 0 | 1 | 2 | 3;
  explanation: string;
}

interface GenerateRequest {
  topic: string;
  difficulty: 'easy' | 'medium' | 'hard';
  count: number;
}

interface GenerateResponse {
  questions: Question[];
}

interface ErrorResponse {
  error: string;
  retryable: boolean;
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
// Stub questions — 10 hardcoded dummies for WORKER-001 (replaced in WORKER-002)
// ---------------------------------------------------------------------------

function buildStubQuestions(topic: string, _difficulty: string): Question[] {
  const stubs: Question[] = [
    {
      id: '1',
      question: `What is considered the founding event of ${topic}?`,
      options: ['Option A', 'Option B', 'Option C', 'Option D'],
      correctIndex: 0,
      explanation: 'This is the stub explanation for question 1.',
    },
    {
      id: '2',
      question: `Who is most associated with ${topic}?`,
      options: ['Person A', 'Person B', 'Person C', 'Person D'],
      correctIndex: 1,
      explanation: 'This is the stub explanation for question 2.',
    },
    {
      id: '3',
      question: `What was the primary impact of ${topic}?`,
      options: ['Impact A', 'Impact B', 'Impact C', 'Impact D'],
      correctIndex: 2,
      explanation: 'This is the stub explanation for question 3.',
    },
    {
      id: '4',
      question: `Which region is most connected to ${topic}?`,
      options: ['Region A', 'Region B', 'Region C', 'Region D'],
      correctIndex: 3,
      explanation: 'This is the stub explanation for question 4.',
    },
    {
      id: '5',
      question: `What ended the era of ${topic}?`,
      options: ['End A', 'End B', 'End C', 'End D'],
      correctIndex: 0,
      explanation: 'This is the stub explanation for question 5.',
    },
    {
      id: '6',
      question: `Which innovation is attributed to ${topic}?`,
      options: ['Inno A', 'Inno B', 'Inno C', 'Inno D'],
      correctIndex: 1,
      explanation: 'This is the stub explanation for question 6.',
    },
    {
      id: '7',
      question: `What language was primarily used in ${topic}?`,
      options: ['Lang A', 'Lang B', 'Lang C', 'Lang D'],
      correctIndex: 2,
      explanation: 'This is the stub explanation for question 7.',
    },
    {
      id: '8',
      question: `Which architectural style is associated with ${topic}?`,
      options: ['Style A', 'Style B', 'Style C', 'Style D'],
      correctIndex: 3,
      explanation: 'This is the stub explanation for question 8.',
    },
    {
      id: '9',
      question: `What was the main form of government in ${topic}?`,
      options: ['Gov A', 'Gov B', 'Gov C', 'Gov D'],
      correctIndex: 0,
      explanation: 'This is the stub explanation for question 9.',
    },
    {
      id: '10',
      question: `What legacy did ${topic} leave behind?`,
      options: ['Legacy A', 'Legacy B', 'Legacy C', 'Legacy D'],
      correctIndex: 1,
      explanation: 'This is the stub explanation for question 10.',
    },
  ];
  return stubs;
}

// ---------------------------------------------------------------------------
// Main fetch handler
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, _env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // ── CORS preflight ──────────────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── Route: POST /generate ───────────────────────────────────────────────
    if (url.pathname === '/generate' && request.method === 'POST') {
      return handleGenerate(request);
    }

    // ── 404 for everything else ─────────────────────────────────────────────
    return errorResponse('Not found', false, 404);
  },
};

// ---------------------------------------------------------------------------
// /generate handler
// ---------------------------------------------------------------------------

async function handleGenerate(request: Request): Promise<Response> {
  try {
    // Parse + validate request body
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

    // Cap count at 15 server-side (enforced in WORKER-002 too)
    const safeCount = Math.min(Math.max(1, Number(count) || 10), 15);

    // TODO(WORKER-002): replace stub with real LLM call
    const questions = buildStubQuestions(topic.trim(), normalizedDifficulty).slice(0, safeCount);

    const responseBody: GenerateResponse = { questions };
    return corsResponse(JSON.stringify(responseBody), 200);
  } catch (err) {
    // Never let an unhandled error escape as a naked 500
    const message = err instanceof Error ? err.message : 'Unexpected server error';
    return errorResponse(message, true, 500);
  }
}
