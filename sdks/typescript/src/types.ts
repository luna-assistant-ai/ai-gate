/**
 * AI Gate SDK Types
 */

export interface AIGateConfig {
  /** Your AI Gate project ID (from dashboard - RECOMMENDED) */
  projectId: string;
  /** Base URL for AI Gate API (default: https://api.ai-gate.dev) */
  baseUrl?: string;
  /** Timeout for API requests in milliseconds (default: 30000) */
  timeout?: number;
  /** Enable debug logging (default: false) */
  debug?: boolean;
}

export interface SessionConfig {
  /** OpenAI model to use (default: gpt-4o-realtime-preview-2024-10-01) */
  model?: string;
  /** Voice to use: alloy, echo, fable, onyx, nova, shimmer (default: echo) */
  voice?: string;
  /** Temperature for the model (0-1, default: 0.7) */
  temperature?: number;
  /** System instructions for the assistant */
  instructions?: string;
}

export interface TurnCredentials {
  iceServers: Array<{
    urls: string | string[];
    username?: string;
    credential?: string;
  }>;
  _auth_method?: string;
  _turn_enabled?: boolean;
}

export interface SessionResponse {
  /** OpenAI session ID */
  id: string;
  /** OpenAI model being used */
  model: string;
  /** Session expiration timestamp */
  expires_at: number;
  /** WebRTC TURN credentials */
  turn_credentials: TurnCredentials;
  /** AI Gate session ID */
  session_id: string;
  /** Session metadata */
  metadata: {
    model: string;
    voice: string;
    turn_server: string;
    created_at: string;
  };
  /** Client secret for WebRTC connection */
  client_secret?: {
    value: string;
    expires_at: number;
  };
}

export interface UsageResponse {
  plan: 'free' | 'starter' | 'growth';
  sessionsIncluded: number;
  sessionsUsed: number;
  sessionsRemaining: number;
  estimatedMinutes: number;
  minutesUsed: number;
  percentUsed: number;
}

export interface QuotaExceededError {
  error: 'quota_exceeded';
  message: string;
  usage: UsageResponse;
  upgrade_url: string;
}

export interface RateLimitError {
  error: 'Rate limit exceeded';
  message: string;
  limit: number;
  window: string;
  resetAt: string;
}

export interface APIError {
  error: string;
  message: string;
}

export type BillingPlan = 'free' | 'starter' | 'growth';

export interface CheckoutSessionRequest {
  priceId: string;
  successUrl: string;
  cancelUrl: string;
  clientId: string;
}

export interface CheckoutSessionResponse {
  url: string;
}

export interface PortalSessionRequest {
  returnUrl: string;
  clientId: string;
}

export interface PortalSessionResponse {
  url: string;
}
